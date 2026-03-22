# Testing Guide

## Purpose

Testing ensures that the application's business logic and critical UI behave correctly.

Tests should focus on **reliability, speed, and maintainability**.

The goal is to cover:
- Core business logic
- Important UI states
- Critical user flows

Tests must remain **deterministic and isolated**.

---

## Core Principles

Tests must be:
- **Isolated** — no shared state between tests
- **Reproducible** — same input → same output
- **Fast** — quick feedback loop

### Rules:
- One test should validate **one behavior**
- Avoid testing implementation details
- Prefer testing **behavior and outcomes**
- Use **Arrange – Act – Assert** pattern

**Example structure:**
```dart
test('should emit loading then success when login succeeds', () {
  // Arrange
  final mockUseCase = MockLoginUseCase();
  when(() => mockUseCase(any()))
      .thenAnswer((_) async => Right(testUser));

  final bloc = AuthBloc(loginUseCase: mockUseCase);

  // Act
  bloc.add(LoginEvent('userId'));

  // Assert
  expectLater(
    bloc.stream,
    emitsInOrder([
      AuthState.loading(),
      AuthState.success(testUser),
    ]),
  );
});
```

---

## Naming Convention

Test names should describe behavior.

**Recommended styles:**
- `should_<expected_behavior>_when_<condition>`
- `Given/When/Then` format

**Examples:**
```dart
should_emit_loading_then_success_when_login_succeeds
should_show_error_when_repository_returns_failure
should_navigate_to_home_after_successful_login
```

---

## Test Levels

The project uses three levels of tests.

### 1. Unit Tests

**Purpose:** Verify pure logic without Flutter UI.

**What to test:**
- Use Cases
- Domain logic (Entities, Value Objects)
- Repositories (with mocked data sources)
- Helpers and utilities
- State management logic (Bloc, Riverpod, Provider)

**Requirements:**
- Run quickly
- Avoid Flutter framework when possible
- Mock external dependencies

**Location:**
```
test/unit/
```

**Example structure:**
```
test/unit/features/auth/
├── login_usecase_test.dart
├── auth_repository_test.dart
└── auth_bloc_test.dart
```

**Example unit test (Use Case):**
```dart
void main() {
  group('GetProperties', () {
    late MockPropertyRepository mockRepository;
    late GetProperties useCase;

    setUp(() {
      mockRepository = MockPropertyRepository();
      useCase = GetProperties(mockRepository);
    });

    test('should return list of properties from repository', () async {
      // Arrange
      final properties = [Property(id: '1', title: 'Test', ...)];
      when(() => mockRepository.getProperties(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            city: any(named: 'city'),
          )).thenAnswer((_) async => Right(properties));

      // Act
      final result = await useCase(
        page: 1,
        limit: 20,
      );

      // Assert
      expect(result, Right(properties));
    });

    test('should return failure when repository fails', () async {
      // Arrange
      when(() => mockRepository.getProperties(any(), any(), any(), any()))
          .thenAnswer((_) async => Left(ServerFailure()));

      // Act
      final result = await useCase(page: 1, limit: 20);

      // Assert
      expect(result, Left(ServerFailure()));
    });
  });
}
```

### 2. Widget Tests

**Purpose:** Verify UI components in isolation.

**What to test:**
- Widgets
- Pages/Screens
- UI states (loading, success, error, empty)
- User interactions (taps, text input)

**Common states to test:**
- Initial
- Loading
- Success (with data)
- Error
- Empty

**Typical tools:**
```dart
testWidgets()
pumpWidget()
pumpAndSettle()
tester.tap()
tester.enterText()
find.text()
find.byType()
find.byKey()
```

**Location:**
```
test/widget/
```

**Example:**
```
test/widget/features/auth/
├── login_page_test.dart
├── login_form_test.dart
└── property_card_test.dart
```

**Example widget test:**
```dart
testWidgets('PropertyScreen should display properties', (tester) async {
  // Arrange
  final testProperties = [
    Property(id: '1', title: 'Apartment 1', price: 100000, ...),
  ];

  final mockUseCase = MockGetProperties();
  when(() => mockUseCase(any(), any(), any(), any()))
      .thenAnswer((_) async => Right(testProperties));

  final provider = PropertyProvider(getProperties: mockUseCase);
  await provider.loadProperties(page: 1, limit: 20);

  // Act
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
      ],
      child: const MaterialApp(home: PropertyScreen()),
    ),
  );
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Apartment 1'), findsOneWidget);
  expect(find.text('100000 ₽'), findsOneWidget);
});
```

### 3. Integration Tests

**Purpose:** Validate complete user flows.

**What to test:**
- Registration
- Login
- Navigation
- Full feature usage (e.g., browse properties, apply filters)

**Use:**
```
integration_test/
```

**Run with:**
```bash
flutter test integration_test/
```

**Location:**
```
integration_test/
```

**Example:**
```dart
testWidgets('User can browse properties', (tester) async {
  // Start from app launch
  app.main();

  // Wait for app to settle
  await tester.pumpAndSettle();

  // Verify properties are loaded
  expect(find.byType(PropertyCard), findsWidgets);

  // Test pull-to-refresh
  await tester.drag(find.byType(ListView), const Offset(0, 300));
  await tester.pumpAndSettle();

  // Verify still showing properties
  expect(find.byType(PropertyCard), findsWidgets);
});
```

**Note:** Integration tests should be **fewer** than unit/widget tests and focus only on critical user scenarios.

---

## Mocks and Test Doubles

Use mocking for external dependencies.

**Recommended library:** `mocktail`

**Mock only:**
- Repositories
- Data sources
- Network services
- Storage services
- Use cases (when testing state management)

**Never call:**
- Real APIs
- Real databases
- Firebase
- External services

**Setup example:**
```dart
class MockPropertyRepository extends Mock implements PropertyRepository {}

void main() {
  late MockPropertyRepository mockRepository;

  setUp(() {
    mockRepository = MockPropertyRepository();
  });

  // Tests...
}
```

---

## State Management Testing

### For Provider (ChangeNotifier)

```dart
test('PropertyProvider should emit loading then success', () async {
  // Arrange
  final mockUseCase = MockGetProperties();
  when(() => mockUseCase(any(), any(), any(), any()))
      .thenAnswer((_) async => Right([testProperty]));

  final provider = PropertyProvider(getProperties: mockUseCase);

  // Act
  await provider.loadProperties(page: 1, limit: 20);

  // Assert
  expect(provider.isLoading, false);
  expect(provider.properties, [testProperty]);
  expect(provider.failure, isNull);
});
```

### For Bloc/Cubit

Use `bloc_test` package:

```dart
blocTest<AuthBloc, AuthState>(
  'emits loading and success on login',
  build: () => AuthBloc(loginUseCase: mockLoginUseCase),
  act: (bloc) => bloc.add(LoginEvent('id')),
  expect: () => [
    AuthState.loading(),
    AuthState.authenticated(user),
  ],
);
```

---

## UI Testing Guidelines

Widget tests should verify:
- ✅ Loading indicators appear/disappear
- ✅ Error messages display correctly
- ✅ Correct widgets rendered
- ✅ User actions trigger expected behavior

**Avoid overly brittle tests** based on exact layout details.

**Prefer:**
- `find.byType`
- `find.byKey`
- `find.text`

Over exact widget tree matching.

---

## Golden Tests (Optional)

Golden tests may be used for important UI components.

**Typical cases:**
- Complex cards
- Design system widgets
- Reusable UI components

**Use packages:** `golden_toolkit`

Golden tests are optional and should focus on design-critical widgets.

---

## Test Reliability Rules

Tests must not depend on:
- Device state
- Real network
- External APIs
- Current time (unless mocked)

**Use fake values or mocks** when needed.

---

## CI Requirements

All tests must pass before merging.

**Run tests with:**
```bash
flutter test
```

**Recommended coverage goals:**
- Domain layer: high coverage (≥80%)
- State management logic: high coverage
- UI components: moderate coverage

Focus on **critical logic**, not trivial code.

---

## Common Testing Patterns

### Testing Either Results

```dart
result.fold(
  (failure) => expect(failure, isA<ServerFailure>()),
  (data) => expect(data, isA<List<Property>>()),
);
```

### Testing Async State Changes

```dart
await tester.pump(); // Start frame
await tester.pump(Duration(seconds: 1)); // Advance time
await tester.pumpAndSettle(); // Wait for all animations
```

### Testing Error States

```dart
when(() => mockUseCase(any()))
    .thenAnswer((_) async => Left(ServerFailure()));

await provider.load();
expect(provider.failure, isA<ServerFailure>());
```

---

## Summary

Effective testing follows:
1. **Isolate** the component
2. **Mock** external dependencies
3. **Arrange** test data
4. **Act** by calling the method
5. **Assert** expected outcome

This ensures stability and maintainability of the codebase.

---

## Related Documentation

- `ARCHITECTURE.md` — architecture overview
- `project.md` — project configuration
- `docs/features/<feature>.md` — feature-specific testing examples
