import 'package:flutter/material.dart';
import '../../domain/entities/property_entity.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyEntity property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(property.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              property.image,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: theme.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: theme.colorScheme.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator.adaptive(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${property.price}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    theme,
                    icon: Icons.location_on,
                    label: 'Location',
                    value: property.city,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    theme,
                    icon: Icons.meeting_room,
                    label: 'Rooms',
                    value: '${property.rooms}',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    theme,
                    icon: Icons.square_foot,
                    label: 'Area',
                    value: '${property.area} m²',
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement contact/booking
                    },
                    style: theme.elevatedButtonTheme.style,
                    child: const Text('Contact Owner'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
