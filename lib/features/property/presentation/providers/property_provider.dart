import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../domain/use_cases/get_properties.dart';
import '../../domain/use_cases/get_property_by_id.dart';
import '../../domain/entities/property.dart';
import '../../../../core/error/failure.dart';

/// Provider для управления состоянием Property.
///
/// Отвечает за:
/// - Загрузку списка свойств с пагинацией
/// - Фильтрацию по поисковому запросу и городу
/// - Загрузку отдельного свойства по ID
/// - Управление состояниями загрузки и ошибок
///
/// Использует debounce для поиска (300ms).
class PropertyProvider extends ChangeNotifier {
  final GetProperties getPropertiesUseCase;
  final GetPropertyById getPropertyByIdUseCase;

  PropertyProvider({
    required this.getPropertiesUseCase,
    required this.getPropertyByIdUseCase,
  });

  /// Список всех загруженных свойств
  List<Property> _properties = [];
  List<Property> get properties => List.unmodifiable(_properties);

  /// Текущее загруженное свойство (для детального экрана)
  Property? _currentProperty;
  Property? get currentProperty => _currentProperty;

  /// Флаг загрузки списка
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Флаг загрузки дополнительных элементов (пагинация)
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  /// Флаг наличия дополнительных элементов для пагинации
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// Текущий поисковый запрос
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Выбранный город для фильтрации
  String? _selectedCity;
  String? get selectedCity => _selectedCity;

  /// Текущая страница пагинации
  int _currentPage = 1;

  /// Размер страницы
  static const int _pageSize = 20;

  /// Сообщение об ошибке
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Debounce таймер для поиска
  Timer? _debounceTimer;

  /// Флаг для отслеживания, не был ли provider удален
  bool _isDisposed = false;

  /// Загружает список свойств с фильтрацией
  ///
  /// [refresh] - если true, загружает первую страницу и очищает список
  Future<void> loadProperties({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _properties.clear();
    }

    // Если загружаем не первую страницу и больше нет данных - выходим
    if (!refresh && _currentPage > 1 && !_hasMore) {
      return;
    }

    // Устанавливаем правильный флаг загрузки
    if (_currentPage == 1) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }
    _clearError();

    final Either<Failure, List<Property>> result = await getPropertiesUseCase(
      page: _currentPage,
      limit: _pageSize,
      query: _searchQuery.isEmpty ? null : _searchQuery,
      city: _selectedCity,
    );

    // Проверяем, не был ли provider удален во время запроса
    if (_isDisposed) return;

    result.fold(
      (Failure failure) {
        _errorMessage = _mapFailureToMessage(failure);
        if (_currentPage == 1) {
          _setLoading(false);
        } else {
          _setLoadingMore(false);
        }
      },
      (List<Property> newProperties) {
        if (refresh || _currentPage == 1) {
          _properties = newProperties;
        } else {
          _properties.addAll(newProperties);
        }

        // Определяем, есть ли еще данные для пагинации
        _hasMore = newProperties.length == _pageSize;
        _currentPage++;

        if (_currentPage == 1) {
          _setLoading(false);
        } else {
          _setLoadingMore(false);
        }
      },
    );
  }

  /// Загружает свойство по ID
  Future<void> loadPropertyById(String id) async {
    _clearError();
    _currentProperty = null;
    notifyListeners();

    if (_isDisposed) return;

    final Either<Failure, Property> result = await getPropertyByIdUseCase(id);

    if (_isDisposed) return;

    result.fold(
      (Failure failure) {
        _errorMessage = _mapFailureToMessage(failure);
      },
      (Property property) {
        _currentProperty = property;
      },
    );
    notifyListeners();
  }

  /// Устанавливает поисковый запрос с debounce (300ms)
  void setSearchQuery(String query) {
    _searchQuery = query;

    // Отменяем предыдущий таймер
    _debounceTimer?.cancel();

    // Запускаем новый таймер
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      // Сбрасываем пагинацию и загружаем первую страницу
      _currentPage = 1;
      _hasMore = true;
      loadProperties(refresh: true);
    });
  }

  /// Устанавливает фильтр по городу
  void setSelectedCity(String? city) {
    _selectedCity = city;

    // Сбрасываем пагинацию и загружаем первую страницу
    _currentPage = 1;
    _hasMore = true;
    loadProperties(refresh: true);
  }

  /// Загружает следующую страницу (пагинация)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    await loadProperties();
  }

  /// Очищает ошибку
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Устанавливает состояние загрузки и уведомляет listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Устанавливает состояние загрузки дополнительных элементов
  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  /// Очищает ошибку
  void _clearError() {
    _errorMessage = null;
  }

  /// Преобразует Failure в пользовательское сообщение
  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Проблема с сетью. Проверьте подключение.';
    } else if (failure is NotFoundFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is ServerFailure) {
      return 'Ошибка сервера. Попробуйте позже.';
    } else {
      return 'Произошла ошибка. Попробуйте позже.';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _isDisposed = true;
    super.dispose();
  }
}
