import 'package:flutter/foundation.dart';
import '../core/models/property_model.dart';
import '../services/property_service.dart';

enum ProgressState { initial, loading, success, error }

class PropertyProvider extends ChangeNotifier {
  final PropertyService _service = PropertyService();

  ProgressState _state = ProgressState.initial;
  ProgressState get state => _state;

  final List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  List<PropertyModel> get properties => _filteredProperties;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  int _page = 1;
  static const _limit = 10;
  bool _hasMore = true;

  bool _isFetching = false;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String _searchQuery = '';
  String? _city;

  Future<void> fetchInitial() async {
    if (_isFetching) return;

    _state = ProgressState.loading;
    _errorMessage = '';
    notifyListeners();

    await _fetchProperties(reset: true);
  }

  Future<void> fetchMore() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchProperties(
        page: _page,
        limit: _limit,
        query: _searchQuery,
        city: _city,
      );

      _properties.addAll(result);
      _page++;
      if (result.length < _limit) _hasMore = false;

      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isFetching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchProperties({bool reset = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (reset) {
      _page = 1;
      _hasMore = true;
      _properties.clear();
      _filteredProperties.clear();
    }

    try {
      final result = await _service.fetchProperties(
        page: _page,
        limit: _limit,
        query: _searchQuery,
        city: _city,
      );

      _properties.addAll(result);
      _page++;
      if (result.length < _limit) _hasMore = false;

      _applyFilters();

      _state = ProgressState.success;
    } catch (e) {
      _errorMessage = e.toString();
      if (_properties.isEmpty) _state = ProgressState.error;
    } finally {
      _isFetching = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter({String? query, String? city}) async {
    _searchQuery = query ?? _searchQuery;
    _city = city ?? _city;

    await _fetchProperties(reset: true);
  }

  void _applyFilters() {
    _filteredProperties = _properties.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCity = _city == null || item.city == _city;
      return matchesQuery && matchesCity;
    }).toList();
  }

  Future<void> refresh() async {
    await _fetchProperties(reset: true);
  }
}
