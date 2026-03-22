import '../../domain/entities/property_entity.dart';
import '../dto/property_dto.dart';

class PropertyMapper {
  static PropertyEntity toEntity(PropertyDto dto) {
    return PropertyEntity(
      id: dto.id,
      title: dto.title,
      price: dto.price,
      area: dto.area,
      rooms: dto.rooms,
      city: dto.city,
      image: dto.image,
    );
  }

  static PropertyDto toDto(PropertyEntity entity) {
    return PropertyDto(
      id: entity.id,
      title: entity.title,
      price: entity.price,
      area: entity.area,
      rooms: entity.rooms,
      city: entity.city,
      image: entity.image,
    );
  }
}
