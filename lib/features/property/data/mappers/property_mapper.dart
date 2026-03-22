import '../../domain/entities/property.dart';
import '../dto/property_dto.dart';

/// Маппер для преобразования между PropertyDto и Property
///
/// Отвечает за конвертацию данных между слоем Data (DTO) и слоем Domain (Entity).
/// Следует правилу: Domain и Presentation не зависят от DTO.
class PropertyMapper {
  /// Преобразует PropertyDto в Property (Entity)
  ///
  /// Используется в RepositoryImpl при получении данных из API
  static Property toEntity(PropertyDto dto) {
    return Property(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      price: dto.price,
      imageUrl: dto.imageUrl,
      location: dto.location,
    );
  }

  /// Преобразует Property (Entity) в PropertyDto
  ///
  /// Используется в RepositoryImpl при отправке данных на сервер
  static PropertyDto toDto(Property entity) {
    return PropertyDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      price: entity.price,
      imageUrl: entity.imageUrl,
      location: entity.location,
    );
  }

  /// Преобразует список PropertyDto в список Property
  static List<Property> toEntityList(List<PropertyDto> dtos) {
    return dtos.map((dto) => toEntity(dto)).toList();
  }

  /// Преобразует список Property в список PropertyDto
  static List<PropertyDto> toDtoList(List<Property> entities) {
    return entities.map((entity) => toDto(entity)).toList();
  }
}
