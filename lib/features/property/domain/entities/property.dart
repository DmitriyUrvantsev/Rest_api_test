/// Entity (Сущность) Property
///
/// Представляет доменную модель недвижимости.
/// Содержит только бизнес-логику и данные, без зависимостей от Flutter или DTO.
class Property {
  /// Уникальный идентификатор недвижимости
  final String id;

  /// Заголовок/название недвижимости
  final String title;

  /// Описание недвижимости
  final String description;

  /// Цена недвижимости (в условных единицах)
  final double price;

  /// URL изображения недвижимости
  final String? imageUrl;

  /// Местоположение/адрес недвижимости
  final String location;

  /// Создает экземпляр Property
  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.location,
  });

  /// Создает копию объекта с измененными полями
  Property copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    String? location,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
    );
  }
}
