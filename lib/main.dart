import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PropertyProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Test Order App',
      debugShowCheckedModeBanner: false,
      home: PropertyScreen(),
    );
  }
}

class PropertyModel {
  final String id;
  final String title;
  final int price;
  final int area;
  final int rooms;
  final String city;
  String image;

  PropertyModel({
    required this.id,
    required this.title,
    required this.price,
    required this.area,
    required this.rooms,
    required this.city,
    required this.image,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      price: json['price'] as int,
      area: json['area'] as int,
      rooms: json['rooms'] as int,
      city: json['city'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'area': area,
      'rooms': rooms,
      'city': city,
      'image': image,
    };
  }
}

/// 🔹 Сервис для получения данных о квартирах
class PropertyService {
  static const _host = '69aab1b8e051e9456fa22b65.mockapi.io';
  static const _path = '/api/v1/flats/items';

  Future<List<PropertyModel>> fetchProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    // если API поддерживает фильтры, добавляем их
    if (query != null && query.isNotEmpty) params['title'] = query;
    if (city != null && city.isNotEmpty) params['city'] = city;

    final url = Uri.https(_host, _path, params);

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<PropertyModel> models = data.map((e) {
          final model = PropertyModel.fromJson(e as Map<String, dynamic>);
          model.image = _safeImageUrl(model.image);
          return model;
        }).toList();

        return _removeDuplicates(models);
      } else {
        throw Exception('Ошибка сервера - ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Истекло время ожидания');
    } on SocketException {
      throw Exception('Проблемы с интернетом');
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 Безопасный URL изображения
  String _safeImageUrl(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host.contains('picsum.photos') && uri.pathSegments.length >= 2) {
        final width = uri.pathSegments[0];
        final rawHeight = uri.pathSegments[1].split('.').first;
        return 'https://picsum.photos/$width/$rawHeight?random=${DateTime.now().millisecondsSinceEpoch}';
      }

      return url;
    } catch (_) {
      return 'assets/images/placeholder.png';
    }
  }

  /// 🔹 Убираем дубликаты по id
  List<PropertyModel> _removeDuplicates(List<PropertyModel> list) {
    final seenIds = <String>{};
    final filtered = <PropertyModel>[];
    for (var item in list) {
      if (!seenIds.contains(item.id)) {
        filtered.add(item);
        seenIds.add(item.id);
      }
    }
    return filtered;
  }
}

enum ProgressState { initial, loading, success, error }

/// 🔹 Провайдер для работы с квартирами
class PropertyProvider extends ChangeNotifier {
  final PropertyService _service = PropertyService();

  ProgressState _state = ProgressState.initial;
  ProgressState get state => _state;

  final List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  List<PropertyModel> get properties => _filteredProperties;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  int _page = 1;
  static const _limit = 10;
  bool _hasMore = true;

  bool _isFetching = false;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // текущие фильтры
  String _searchQuery = '';
  String? _city;

  /// 🔹 Получение первых данных
  Future<void> fetchInitial() async {
    if (_isFetching) return;

    _state = ProgressState.loading;
    _errorMessage = '';
    notifyListeners();

    await _fetchProperties(reset: true);
  }

  /// 🔹 Подгрузка следующей страницы
  Future<void> fetchMore() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchProperties(
        page: _page,
        limit: _limit,
        query: _searchQuery,
        city: _city,
      );

      _properties.addAll(result);
      _page++;
      if (result.length < _limit) _hasMore = false;

      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isFetching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 🔹 Сброс и подгрузка данных
  Future<void> _fetchProperties({bool reset = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (reset) {
      _page = 1;
      _hasMore = true;
      _properties.clear();
      _filteredProperties.clear();
    }

    try {
      final result = await _service.fetchProperties(
        page: _page,
        limit: _limit,
        query: _searchQuery,
        city: _city,
      );

      _properties.addAll(result);
      _page++;
      if (result.length < _limit) _hasMore = false;

      _applyFilters();

      _state = ProgressState.success;
    } catch (e) {
      _errorMessage = e.toString();
      if (_properties.isEmpty) _state = ProgressState.error;
    } finally {
      _isFetching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 🔹 Применить фильтры (локально и серверно)
  Future<void> applyFilter({String? query, String? city}) async {
    _searchQuery = query ?? _searchQuery;
    _city = city ?? _city;

    // серверный поиск — сброс и подгрузка с фильтром
    await _fetchProperties(reset: true);
  }

  /// 🔹 Применение фильтров локально к уже загруженным данным
  void _applyFilters() {
    _filteredProperties = _properties.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCity = _city == null || item.city == _city;
      return matchesQuery && matchesCity;
    }).toList();
  }

  /// 🔹 Обновление всех данных
  Future<void> refresh() async {
    await _fetchProperties(reset: true);
  }
}

///
///
///

//---------------
class PropertyScreen extends StatefulWidget {
  const PropertyScreen({super.key});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  final ScrollController _controller = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchInitial();
    });
  }

  void _onScroll() {
    if (_debounce?.isActive ?? false) return;

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent - 200) {
        context.read<PropertyProvider>().fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        context.select<PropertyProvider, ProgressState>((p) => p.state);

    return Scaffold(
      appBar: AppBar(title: const Text('Flats')),
      body: switch (state) {
        ProgressState.loading => const _LoadingView(),
        ProgressState.error => const _ErrorView(),
        ProgressState.success => _PropertyList(controller: _controller),
        ProgressState.initial => const SizedBox(),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final error =
        context.select<PropertyProvider, String>((p) => p.errorMessage);

    return Center(child: Text('Ошибка - $error'));
  }
}

///

class _PropertyList extends StatefulWidget {
  final ScrollController controller;

  const _PropertyList({super.key, required this.controller});

  @override
  State<_PropertyList> createState() => _PropertyListState();
}

class _PropertyListState extends State<_PropertyList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    // 🔹 сбрасываем предыдущий таймер дебаунса
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final provider = context.read<PropertyProvider>();
      final query = value.trim();

      if (query.isEmpty) {
        // 🔹 если поле пустое — сброс фильтров и полный запрос
        provider.refresh();
      } else {
        // 🔹 фильтруем уже загруженные данные
        provider.applyFilter(query: query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PropertyProvider>();

    final properties = context
        .select<PropertyProvider, List<PropertyModel>>((p) => p.properties);

    final isLoadingMore =
        context.select<PropertyProvider, bool>((p) => p.isLoadingMore);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 🔹 поле ввода
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchSubmitted,
                ),
              ),

              const SizedBox(width: 8),

              // 🔹 кнопка поиска
              ElevatedButton(
                onPressed: () {
                  provider.applyFilter(
                    query: _searchController.text,
                  );
                },
                child: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView.builder(
              controller: widget.controller,
              itemCount:
                  isLoadingMore ? properties.length + 1 : properties.length,
              itemBuilder: (context, index) {
                if (index >= properties.length) {
                  // показываем только если реально идет загрузка и _isFetching
                  return provider.isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                return _PropertyCard(property: properties[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

///
///

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const _PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: property),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                property.image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${property.city} • ${property.rooms} rooms • ${property.area} m²',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${property.price}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//=============
class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(property.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(property.image),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${property.city}\n'
              '${property.rooms} rooms • ${property.area} m²\n'
              'Price: \$${property.price}',
            ),
          ),
        ],
      ),
    );
  }
}
