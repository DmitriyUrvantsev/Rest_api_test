import 'dart:async';
import 'package:dartz/dartz.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';
import '../../../../core/error/failure.dart';

/// Use Case для получения списка свойств (properties) с пагинацией и фильтрацией
///
/// Инкапсулирует бизнес-логику получения списка недвижимости.
/// Не зависит от конкретной реализации репозитория.
class GetProperties {
  final PropertyRepository repository;

  const GetProperties(this.repository);

  /// Выполняет получение списка свойств
  ///
  /// [page] - номер страницы (начиная с 1)
  /// [limit] - количество элементов на странице
  /// [query] - опциональный поисковый запрос (по заголовку)
  /// [city] - опциональный фильтр по городу
  Future<Either<Failure, List<Property>>> call({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) {
    return repository.getProperties(
      page: page,
      limit: limit,
      query: query,
      city: city,
    );
  }
}
