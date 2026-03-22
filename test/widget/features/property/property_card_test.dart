import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:test_promt_api/features/property/domain/entities/property.dart';
import 'package:test_promt_api/features/property/presentation/widgets/property_card.dart';

class MockPropertyProvider extends ChangeNotifier {
  @override
  void notifyListeners() {}
}

void main() {
  group('PropertyCard Widget Tests', () {
    final testProperty = Property(
      id: '1',
      title: 'Test Property',
      description: 'Test description',
      price: 1000000,
      imageUrl: 'https://example.com/image.jpg',
      location: 'Test City',
    );

    testWidgets('should display property title and price',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: testProperty),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Property'), findsOneWidget);
      expect(find.text('1.0M'), findsOneWidget); // Formatted price
      expect(find.text('Test City'), findsOneWidget);
    });

    testWidgets('should display image when imageUrl is valid',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: testProperty),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should display placeholder icon when imageUrl is null',
        (WidgetTester tester) async {
      // Arrange
      final propertyWithoutImage = testProperty.copyWith(imageUrl: null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: propertyWithoutImage),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('should display placeholder icon when imageUrl is empty',
        (WidgetTester tester) async {
      // Arrange
      final propertyWithEmptyImage = testProperty.copyWith(imageUrl: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: propertyWithEmptyImage),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets(
        'should display placeholder icon when imageUrl is invalid (not http/https)',
        (WidgetTester tester) async {
      // Arrange
      final propertyWithInvalidImage =
          testProperty.copyWith(imageUrl: 'ftp://example.com/image.jpg');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: propertyWithInvalidImage),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('should display description when provided',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: testProperty),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('should not display description when empty',
        (WidgetTester tester) async {
      // Arrange
      final propertyWithoutDescription = testProperty.copyWith(description: '');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: propertyWithoutDescription),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test description'), findsNothing);
    });

    testWidgets('should call onTap when card is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(
              property: testProperty,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(tapped, true);
    });

    testWidgets('should format price correctly for millions',
        (WidgetTester tester) async {
      // Arrange
      final expensiveProperty = testProperty.copyWith(price: 2500000);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: expensiveProperty),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2.5M'), findsOneWidget);
    });

    testWidgets('should format price correctly for thousands',
        (WidgetTester tester) async {
      // Arrange
      final thousandProperty = testProperty.copyWith(price: 150000);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: thousandProperty),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('150K'), findsOneWidget);
    });

    testWidgets('should format price correctly for less than 1000',
        (WidgetTester tester) async {
      // Arrange
      final cheapProperty = testProperty.copyWith(price: 500);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: cheapProperty),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('500'), findsOneWidget);
    });
  });
}
