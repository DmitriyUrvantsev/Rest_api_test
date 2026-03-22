import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/models/property_model.dart';

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
