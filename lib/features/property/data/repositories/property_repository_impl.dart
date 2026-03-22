import 'package:dartz/dartz.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../../../core/error/failure.dart';
import '../services/property_service.dart';
import '../dto/property_dto.dart';
import '../mappers/property_mapper.dart';

/// Реализация PropertyRepository
///
/// Использует PropertyService для получения данных из API
/// и PropertyMapper для преобразования DTO в Entity.
/// Преобразует исключения в Failure объекты.
class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyService propertyService;

  PropertyRepositoryImpl({required this.propertyService});

  @override
  Future<Either<Failure, List<Property>>> getProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    try {
      final List<PropertyDto> dtos = await propertyService.fetchProperties(
        page: page,
        limit: limit,
        query: query,
        city: city,
      );
      final List<Property> properties =
          dtos.map((dto) => PropertyMapper.toEntity(dto)).toList();
      return Right(properties);
    } catch (e) {
      return Left(NetworkFailure('Ошибка сети: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Property>> getPropertyById(String id) async {
    try {
      final PropertyDto dto = await propertyService.fetchPropertyById(id);
      final Property property = PropertyMapper.toEntity(dto);
      return Right(property);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return Left(NotFoundFailure('Недвижимость с ID $id не найдена'));
      }
      return Left(NetworkFailure('Ошибка сети: ${e.toString()}'));
    }
  }
}
