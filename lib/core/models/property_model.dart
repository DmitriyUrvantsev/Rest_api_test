class PropertyModel {
  final String id;
  final String title;
  final int price;
  final int area;
  final int rooms;
  final String city;
  String image;

  PropertyModel({
    required this.id,
    required this.title,
    required this.price,
    required this.area,
    required this.rooms,
    required this.city,
    required this.image,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      price: json['price'] as int,
      area: json['area'] as int,
      rooms: json['rooms'] as int,
      city: json['city'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'area': area,
      'rooms': rooms,
      'city': city,
      'image': image,
    };
  }
}
