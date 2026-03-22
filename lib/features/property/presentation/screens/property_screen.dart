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

    return Scaffold(
      appBar: AppBar(title: const Text('Flats')),
      body: switch (state) {
        ProgressState.loading => const _LoadingView(),
        ProgressState.error => const _ErrorView(),
        ProgressState.success => _PropertyList(controller: _controller),
        ProgressState.initial => const SizedBox(),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final error =
        context.select<PropertyProvider, String>((p) => p.errorMessage);

    return Center(child: Text('Ошибка - $error'));
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

    final properties = context
        .select<PropertyProvider, List<PropertyEntity>>((p) => p.properties);

    final isLoadingMore =
        context.select<PropertyProvider, bool>((p) => p.isLoadingMore);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  provider.applyFilter(
                    query: _searchController.text,
                  );
                },
                child: const Icon(Icons.search),
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
                            child: CircularProgressIndicator(),
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: property),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                property.image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${property.city} • ${property.rooms} rooms • ${property.area} m²',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${property.price}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
