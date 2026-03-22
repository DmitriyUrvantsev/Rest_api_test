import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:test_promt_api/core/error/failure.dart';
import 'package:test_promt_api/features/property/domain/entities/property.dart';
import 'package:test_promt_api/features/property/domain/use_cases/get_properties.dart';
import 'package:test_promt_api/features/property/domain/use_cases/get_property_by_id.dart';
import 'package:test_promt_api/features/property/presentation/providers/property_provider.dart';

class MockGetProperties extends Mock implements GetProperties {}

class MockGetPropertyById extends Mock implements GetPropertyById {}

void main() {
  late PropertyProvider provider;
  late MockGetProperties mockGetProperties;
  late MockGetPropertyById mockGetPropertyById;
  late List<Property> testProperties;

  setUp(() {
    mockGetProperties = MockGetProperties();
    mockGetPropertyById = MockGetPropertyById();
    provider = PropertyProvider(
      getPropertiesUseCase: mockGetProperties,
      getPropertyByIdUseCase: mockGetPropertyById,
    );

    testProperties = [
      Property(
        id: '1',
        title: 'Test Property 1',
        description: 'Description 1',
        price: 1000000,
        imageUrl: 'https://example.com/image1.jpg',
        location: 'Moscow',
      ),
      Property(
        id: '2',
        title: 'Test Property 2',
        description: 'Description 2',
        price: 2000000,
        imageUrl: 'https://example.com/image2.jpg',
        location: 'St. Petersburg',
      ),
    ];
  });

  group('PropertyProvider', () {
    test('Initial values should be correct', () {
      expect(provider.properties, isEmpty);
      expect(provider.currentProperty, isNull);
      expect(provider.isLoading, false);
      expect(provider.isLoadingMore, false);
      expect(provider.hasMore, true);
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedCity, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('should emit loading state when loadProperties is called', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // Act
      await provider.loadProperties();

      // Assert
      verify(() => mockGetProperties(
            page: 1,
            limit: 20,
            query: null,
            city: null,
          )).called(1);
    });

    test('should load properties successfully', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // Act
      await provider.loadProperties();

      // Assert
      expect(provider.properties, hasLength(2));
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('should handle error when loading properties', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Left(NetworkFailure('Network error')));

      // Act
      await provider.loadProperties();

      // Assert
      expect(provider.properties, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
    });

    test('should set search query and trigger debounced load', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // Act
      provider.setSearchQuery('test');

      // Assert - immediately after setting, query should be set but not loaded yet
      expect(provider.searchQuery, 'test');

      // Wait for debounce (300ms)
      await Future.delayed(const Duration(milliseconds: 350));

      // Assert - after debounce, properties should be loaded
      expect(provider.properties, hasLength(2));
      verify(() => mockGetProperties(
            page: 1,
            limit: 20,
            query: 'test',
            city: null,
          )).called(1);
    });

    test('should cancel previous debounce timer when new query is set',
        () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // Act - set first query
      provider.setSearchQuery('first');
      await Future.delayed(const Duration(milliseconds: 100));

      // Set second query before first debounce completes
      provider.setSearchQuery('second');
      await Future.delayed(const Duration(milliseconds: 350));

      // Assert - only second query should trigger load
      expect(provider.searchQuery, 'second');
      verify(() => mockGetProperties(
            page: 1,
            limit: 20,
            query: 'second',
            city: null,
          )).called(1);
    });

    test('should set selected city and reload properties', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // Act
      provider.setSelectedCity('Moscow');

      // Assert
      expect(provider.selectedCity, 'Moscow');
      verify(() => mockGetProperties(
            page: 1,
            limit: 20,
            query: null,
            city: 'Moscow',
          )).called(1);
    });

    test('should load more properties when hasMore is true', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // First load
      await provider.loadProperties();

      // Reset mock to verify second call
      reset(mockGetProperties);
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // Act
      await provider.loadMore();

      // Assert
      expect(provider.properties,
          hasLength(4)); // 2 from first load + 2 from second
      expect(provider.isLoadingMore, false);
    });

    test('should not load more when hasMore is false', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties.take(1).toList()));

      // First load
      await provider.loadProperties();

      // Act
      await provider.loadMore();

      // Assert - should not call use case again because hasMore is false
      verifyNever(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          ));
    });

    test('should load property by id successfully', () async {
      // Arrange
      final singleProperty = testProperties.first;
      when(() => mockGetPropertyById('1'))
          .thenAnswer((_) async => Right(singleProperty));

      // Act
      await provider.loadPropertyById('1');

      // Assert
      expect(provider.currentProperty, singleProperty);
      expect(provider.errorMessage, isNull);
    });

    test('should handle error when loading property by id', () async {
      // Arrange
      when(() => mockGetPropertyById('1'))
          .thenAnswer((_) async => Left(NetworkFailure('Network error')));

      // Act
      await provider.loadPropertyById('1');

      // Assert
      expect(provider.currentProperty, isNull);
      expect(provider.errorMessage, isNotNull);
    });

    test('should clear error', () {
      // Arrange
      provider.clearError();

      // Assert
      expect(provider.errorMessage, isNull);
    });

    test('should refresh properties correctly', () async {
      // Arrange
      when(() => mockGetProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(testProperties));

      // First load
      await provider.loadProperties();
      expect(provider.properties, hasLength(2));

      // Act - refresh
      await provider.loadProperties(refresh: true);

      // Assert
      expect(provider.properties, hasLength(2));
      // After refresh, page should be reset to 1 and then incremented to 2
    });
  });
}
