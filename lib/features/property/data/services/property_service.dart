import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../dto/property_dto.dart';

/// Сервис для работы с Property API
///
/// Отвечает за низкоуровневые HTTP запросы к бэкенду.
/// Возвращает DTO (PropertyDto), которые затем преобразуются в Entity через Mapper.
class PropertyService {
  final http.Client httpClient;
  final String baseUrl;

  PropertyService({required this.httpClient}) : baseUrl = AppConstants.baseUrl;

  /// Получает список свойств с пагинацией и фильтрацией
  ///
  /// [page] - номер страницы (начиная с 1)
  /// [limit] - количество элементов на странице
  /// [query] - опциональный поисковый запрос (по заголовку)
  /// [city] - опциональный фильтр по городу
  ///
  /// Возвращает список PropertyDto
  /// Может выбрасывать исключения при сетевых ошибках или ошибках API
  Future<List<PropertyDto>> fetchProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (query != null && query.isNotEmpty) 'q': query,
      if (city != null && city.isNotEmpty) 'city': city,
    };

    final uri = Uri.parse('$baseUrl/properties').replace(
      queryParameters: queryParams,
    );

    final response = await httpClient.get(uri);

    switch (response.statusCode) {
      case 200:
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => PropertyDto.fromJson(json as Map<String, dynamic>))
            .toList();
      case 404:
        throw Exception('Endpoint not found');
      case 500:
        throw Exception('Server error');
      default:
        throw Exception(
            'Failed to load properties: HTTP ${response.statusCode}');
    }
  }

  /// Получает свойство по ID
  ///
  /// [id] - уникальный идентификатор недвижимости
  ///
  /// Возвращает PropertyDto
  /// Может выбрасывать исключения при сетевых ошибках или ошибках API
  Future<PropertyDto> fetchPropertyById(String id) async {
    final response = await httpClient.get(
      Uri.parse('$baseUrl/properties/$id'),
    );

    switch (response.statusCode) {
      case 200:
        return PropertyDto.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      case 404:
        throw Exception('Property with id $id not found');
      case 500:
        throw Exception('Server error');
      default:
        throw Exception('Failed to load property: HTTP ${response.statusCode}');
    }
  }
}
