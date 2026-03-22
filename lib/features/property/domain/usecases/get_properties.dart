import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

class GetProperties {
  final PropertyRepository repository;

  GetProperties(this.repository);

  Future<List<PropertyEntity>> call({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) {
    return repository.fetchProperties(
      page: page,
      limit: limit,
      query: query,
      city: city,
    );
  }
}
//