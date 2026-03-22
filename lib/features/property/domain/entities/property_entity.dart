class PropertyEntity {
  final String id;
  final String title;
  final int price;
  final int area;
  final int rooms;
  final String city;
  String image;

  PropertyEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.area,
    required this.rooms,
    required this.city,
    required this.image,
  });
}
