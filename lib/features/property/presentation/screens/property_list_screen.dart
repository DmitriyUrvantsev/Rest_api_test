import 'package:flutter/material.dart';
import '../widgets/property_card.dart';
import '../providers/property_provider.dart';
import 'property_detail_screen.dart';
import 'package:provider/provider.dart';

/// Экран со списком недвижимости
///
/// Отображает список PropertyCard и управляет состоянием загрузки/ошибок.
/// Поддерживает:
/// - Поиск по заголовку
/// - Фильтрацию по городу
/// - Пагинацию при скролле
/// - Pull-to-refresh
class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _availableCities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Новосибирск'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Начальная загрузка
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PropertyProvider>().loadProperties();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Загружаем больше когда скроллим ближе к концу (80%)
      context.read<PropertyProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Недвижимость'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // City Filter
          _buildCityFilter(),
          // Property List
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                // Initial loading
                if (provider.isLoading && provider.properties.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error state
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
                          onPressed: () =>
                              provider.loadProperties(refresh: true),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                // Empty state
                if (provider.properties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет доступной недвижимости',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (provider.searchQuery.isNotEmpty ||
                            provider.selectedCity != null)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                              provider.setSelectedCity(null);
                            },
                            child: const Text('Сбросить фильтры'),
                          ),
                      ],
                    ),
                  );
                }

                // Success state with list
                return RefreshIndicator(
                  onRefresh: () => provider.loadProperties(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        provider.properties.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Load more indicator at the end
                      if (index == provider.properties.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }

                      final property = provider.properties[index];
                      return PropertyCard(
                        property: property,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(
                                propertyId: property.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar widget
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по названию...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PropertyProvider>().setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          context.read<PropertyProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  /// Builds the city filter dropdown
  Widget _buildCityFilter() {
    return Consumer<PropertyProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: provider.selectedCity,
            decoration: InputDecoration(
              hintText: 'Выберите город',
              prefixIcon: const Icon(Icons.location_city),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Все города'),
              ),
              ..._availableCities.map(
                (city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                ),
              ),
            ],
            onChanged: (value) {
              provider.setSelectedCity(value);
            },
          ),
        );
      },
    );
  }
}
