import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/property_provider.dart';
import 'package:provider/provider.dart';

/// Экран детальной информации о недвижимости
///
/// Отображает полную информацию о выбранном Property.
class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  /// Проверяет, является ли URL валидным (начинается с http/https)
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали недвижимости'),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          // Если текущее свойство не загружено или ID не совпадает - загружаем
          if (provider.currentProperty?.id != propertyId) {
            // Используем addPostFrameCallback чтобы избежать вызова во время build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.loadPropertyById(propertyId);
            });
          }

          if (provider.isLoading && provider.currentProperty == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPropertyById(propertyId),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final property = provider.currentProperty;
          if (property == null) {
            return const Center(
              child: Text('Недвижимость не найдена'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображение (если есть и URL валиден)
                if (_isValidUrl(property.imageUrl))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: property.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 250,
                        width: double.infinity,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 250,
                        width: double.infinity,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      size: 100,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 24),

                // Заголовок и цена
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatPrice(property.price),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Местоположение
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        property.location,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Описание
                if (property.description.isNotEmpty) ...[
                  Text(
                    'Описание',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                ],

                // Кнопка "Назад"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Вернуться к списку'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Форматирует цену в читаемый вид
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M ₽';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K ₽';
    }
    return '${price.toStringAsFixed(0)} ₽';
  }
}
