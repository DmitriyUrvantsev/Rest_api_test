import 'package:flutter/material.dart';
import '../core/models/property_model.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(property.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(property.image),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${property.city}\n'
              '${property.rooms} rooms • ${property.area} m²\n'
              'Price: \$${property.price}',
            ),
          ),
        ],
      ),
    );
  }
}
