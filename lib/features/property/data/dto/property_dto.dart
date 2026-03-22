import 'package:json_annotation/json_annotation.dart';

part 'property_dto.g.dart';

/// Data Transfer Object (DTO) для Property
///
/// Представляет данные недвижимости в формате, соответствующем API.
/// Использует snake_case для полей, как принято в JSON.
/// Immutable класс с аннотациями для code generation.
@JsonSerializable(fieldRename: FieldRename.snake)
class PropertyDto {
  /// Уникальный идентификатор недвижимости
  final String id;

  /// Заголовок/название недвижимости
  final String title;

  /// Описание недвижимости
  final String description;

  /// Цена недвижимости
  final double price;

  /// URL изображения недвижимости (опционально)
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Местоположение/адрес недвижимости
  final String location;

  /// Создает экземпляр PropertyDto
  const PropertyDto({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.location,
  });

  /// Создает PropertyDto из JSON-карты
  factory PropertyDto.fromJson(Map<String, dynamic> json) =>
      _$PropertyDtoFromJson(json);

  /// Преобразует PropertyDto в JSON-карту
  Map<String, dynamic> toJson() => _$PropertyDtoToJson(this);
}
