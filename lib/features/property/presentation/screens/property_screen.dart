import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../domain/entities/property_entity.dart';
import '../providers/property_provider.dart';
import 'property_details_screen.dart';

class PropertyScreen extends StatefulWidget {
  const PropertyScreen({super.key});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  final ScrollController _controller = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchInitial();
    });
  }

  void _onScroll() {
    if (_debounce?.isActive ?? false) return;

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent - 200) {
        context.read<PropertyProvider>().fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        context.select<PropertyProvider, ProgressState>((p) => p.state);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flats'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: switch (state) {
          ProgressState.loading => const _LoadingView(),
          ProgressState.error => const _ErrorView(),
          ProgressState.success => _PropertyList(controller: _controller),
          ProgressState.initial => const SizedBox(),
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final error =
        context.select<PropertyProvider, String>((p) => p.errorMessage);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PropertyProvider>().refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _PropertyList extends StatefulWidget {
  final ScrollController controller;

  const _PropertyList({super.key, required this.controller});

  @override
  State<_PropertyList> createState() => _PropertyListState();
}

class _PropertyListState extends State<_PropertyList> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final provider = context.read<PropertyProvider>();
      final query = value.trim();

      if (query.isEmpty) {
        provider.refresh();
      } else {
        provider.applyFilter(query: query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PropertyProvider>();
    final theme = Theme.of(context);

    final properties = context
        .select<PropertyProvider, List<PropertyEntity>>((p) => p.properties);

    final isLoadingMore =
        context.select<PropertyProvider, bool>((p) => p.isLoadingMore);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: theme.inputDecorationTheme.border,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor: theme.inputDecorationTheme.fillColor,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    contentPadding: theme.inputDecorationTheme.contentPadding,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: _onSearchSubmitted,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  provider.applyFilter(
                    query: _searchController.text,
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView.builder(
              controller: widget.controller,
              itemCount:
                  isLoadingMore ? properties.length + 1 : properties.length,
              itemBuilder: (context, index) {
                if (index >= properties.length) {
                  return provider.isLoadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                return _PropertyCard(property: properties[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyEntity property;

  const _PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailsScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                property.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
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
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.city,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.meeting_room,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${property.rooms} rooms',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.square_foot,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${property.area} m²',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${property.price}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailsScreen(property: property),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
