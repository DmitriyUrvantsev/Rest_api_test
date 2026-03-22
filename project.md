# Project Configuration

## Overview

- **Language:** Dart
- **Framework:** Flutter
- **Architecture:** Clean Architecture
- **Code organization:** Feature-first
- **Dependency Injection:** GetIt
- **State Management:** Provider
- **Error handling:** Dartz (Either) + Failure classes
- **Localization:** AppLocalizations (if needed)
- **Design system:** Material 3 + centralized ThemeData

All architectural changes must go through **Architect mode**.

---

## Clean Architecture Rules

The project follows a strict layered architecture.

**Layers:**
```
Presentation → Domain ← Data
```

**Rules:**
- Presentation depends on Domain
- Data depends on Domain
- Domain depends on nothing
- Domain must remain pure Dart (no Flutter imports)

Each feature must be **self-contained**.

---

## State Management (CRITICAL)

The project uses **exactly one state manager**.

**Chosen state manager:**

```
STATE_MANAGER = Provider
```

**Allowed values:**
- Riverpod
- Bloc/Cubit
- Provider

**Rules:**
1. All Roo Code modes must read this value before generating state-related code.
2. If this value is empty → the agent must ask the user which manager to use.
3. Mixing multiple state managers in one project is **strictly forbidden**.
4. No new state manager may be introduced after this value is set.

**Provider Implementation Guidelines:**
- Use `ChangeNotifier` as base class for providers
- Use `ConsumerWidget` for UI that watches providers
- Use `MultiProvider` in `main.dart` for provider registration
- Keep business logic in Use Cases, not in providers
- Providers should call Use Cases and manage UI state (loading, success, error)
- Use `notifyListeners()` to trigger UI updates

---

## UI and Theme Rules

All styling must come from the theme system.

**Avoid hardcoded values.**

Do NOT use:
```dart
Colors.red
EdgeInsets.all(16)
fontSize: 14
```

Use instead:
```dart
Theme.of(context).colorScheme
Theme.of(context).textTheme
Theme.of(context).extension<CustomColors>()
```

**Theme configuration** lives in:
```
lib/core/theme/
```

---

## UI Development Rules

- One widget → one responsibility
- Avoid large `build()` methods
- Extract complex UI into separate widgets
- Prefer `const` constructors
- Prefer small reusable widgets

**Responsive layout** should use:
- `LayoutBuilder`
- `MediaQuery`

**Navigation** must go through the centralized router:
```
lib/core/app/router/
```

---

## Data Models

Data models should use:
- **Freezed** for immutable data classes with union types
- **JsonSerializable** for JSON serialization

Example:
```dart
@freezed
class Property with _$Property {
  const factory Property({
    required String id,
    required String title,
    required int price,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}
```

For DTOs:
```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class PropertyDto {
  final String id;
  final String title;
  final int price;

  PropertyDto({required this.id, required this.title, required this.price});

  factory PropertyDto.fromJson(Map<String, dynamic> json) =>
      _$PropertyDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyDtoToJson(this);
}
```

Models should be immutable.

---

## Error Handling

Errors propagate through layers:

```
DataSource → Repository → UseCase → UI
```

**Use cases and repositories return:**
```dart
Either<Failure, T>
```

**UI must display user-friendly error messages.**

### Failure Hierarchy

```dart
// lib/core/error/failure.dart
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([super.message = 'Ошибка сервера']);
}

class ParseFailure extends Failure {
  ParseFailure([super.message = 'Ошибка обработки данных']);
}

class NetworkFailure extends Failure {
  NetworkFailure([super.message = 'Ошибка сети']);
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure([super.message = 'Неизвестная ошибка']);
}
```

### Exceptions in Data Layer

```dart
// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
}

class FormatException implements Exception {
  final String message;
  FormatException([this.message = 'Format error']);
}
```

---

## API Configuration

API configuration must be externalized:

**Option 1: Environment variables (flutter_dotenv)**
```dart
// .env
API_BASE_URL=https://api.example.com
DEFAULT_PAGE_SIZE=20
```

```dart
// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL']!;
  static int get defaultPageSize =>
      int.parse(dotenv.env['DEFAULT_PAGE_SIZE'] ?? '20');
}
```

**Option 2: compile-time constants**
```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
}
```

---

## Performance Guidelines

**Prefer:**
- `const` widgets
- `ListView.builder`
- `GridView.builder`
- `SliverList` for large lists

**Avoid:**
- large rebuild scopes
- expensive logic inside `build()`
- unnecessary `setState` calls

---

## Code Style

Follow **Effective Dart** and **dart format**.

### Naming
- Classes → `PascalCase`
- Variables/functions → `camelCase`
- Files → `snake_case`
- Constants → `lowerCamelCase` or `SCREAMING_SNAKE_CASE` for compile-time

### Boolean Naming
Boolean variables/methods should start with:
- `is`
- `has`
- `can`
- `should`

### Formatting
```bash
dart format .
```

Trailing commas are encouraged for multi-line collections.

---

## Testing Rules

See `testing.md` for detailed guidelines.

**Key principles:**
- Tests must be isolated, reproducible, fast
- Use **Arrange – Act – Assert** pattern
- Test names: `should_<expected_behavior>_when_<condition>`
- Mock external dependencies (APIs, databases)
- Focus on business logic (Domain) and critical UI states

**Test levels:**
1. **Unit tests** (`test/unit/`) — Use Cases, Repositories, Entities, Mappers
2. **Widget tests** (`test/widget/`) — Screens, Widgets, Providers
3. **Integration tests** (`integration_test/`) — Full user flows

Coverage goals:
- Domain layer: high coverage
- State management: high coverage
- UI components: moderate coverage

---

## Project Structure

```
lib/
├── core/                          # Shared modules
│   ├── theme/                    # ThemeData, colors, text styles
│   ├── router/                   # Navigation (GoRouter/Beamer)
│   ├── network/                  # HTTP client, interceptors
│   ├── di/                       # Dependency Injection (GetIt)
│   ├── error/                    # Failure classes, exceptions
│   ├── config/                   # AppConfig, environment
│   └── utils/                    # Extensions, helpers
├── features/
│   └── <feature_name>/
│       ├── data/
│       │   ├── dto/
│       │   ├── mappers/
│       │   ├── data_sources/
│       │   ├── repositories/
│       │   └── models/           # Local models (if needed)
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── use_cases/
│       └── presentation/
│           ├── screens/
│           ├── widgets/
│           ├── providers/        # or bloc/, cubit/
│           └── view_models/
├── main.dart                     # Entry point, DI initialization
└── app.dart                     # App widget, routes, theme
```

---

## Dependencies

Current dependencies from `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0
  provider: ^6.1.5+1
  # Recommended additions for Clean Architecture:
  dartz: ^0.10.1                 # Either, functional programming
  get_it: ^7.6.0                 # Dependency injection
  freezed: ^2.4.0                # Immutable models, union types
  json_annotation: ^4.8.0
  flutter_dotenv: ^5.1.0         # Environment variables (optional)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0           # For code generation
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  mocktail: ^1.0.0               # Testing mocks
```

---

## Documentation Rules

Each new feature must have documentation:

```
docs/features/<feature_name>.md
```

Architectural decisions must be documented in:

```
CHANGES_OVERVIEW.md
```

---

## Summary

This configuration defines:
- Clean Architecture with feature-first structure
- Provider as the sole state manager
- GetIt for dependency injection
- Dartz Either<Failure, T> for error handling
- Freezed + JsonSerializable for data models
- Externalized API configuration
- Comprehensive testing strategy

All code must adhere to these rules unless explicitly overridden in feature-specific documentation.
