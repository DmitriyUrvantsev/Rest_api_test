import '../entities/property_entity.dart';

abstract class PropertyRepository {
  Future<List<PropertyEntity>> fetchProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  });
}
