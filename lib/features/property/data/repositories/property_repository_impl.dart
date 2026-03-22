import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/entities/property_entity.dart';
import '../../domain/repositories/property_repository.dart';
import '../dto/property_dto.dart';
import '../mappers/property_mapper.dart';
import '../utils/property_helpers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failure.dart';

//
class PropertyRepositoryImpl implements PropertyRepository {
  @override
  Future<List<PropertyEntity>> fetchProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (query != null && query.isNotEmpty) params['title'] = query;
    if (city != null && city.isNotEmpty) params['city'] = city;

    final url = Uri.https(ApiConstants.host, ApiConstants.path, params);

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<PropertyDto> dtos = data.map((e) {
          return PropertyDto.fromJson(e as Map<String, dynamic>);
        }).toList();

        final List<PropertyEntity> entities = dtos.map((dto) {
          final entity = PropertyMapper.toEntity(dto);
          entity.image = safeImageUrl(entity.image);
          return entity;
        }).toList();

        return removeDuplicates(entities, (e) => e.id);
      } else {
        throw ServerFailure('Ошибка сервера - ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutFailure('Истекло время ожидания');
    } on SocketException {
      throw NetworkFailure('Проблемы с интернетом');
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
