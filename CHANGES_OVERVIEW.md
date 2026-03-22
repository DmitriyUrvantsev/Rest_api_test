# Changes Overview

This document tracks major architectural decisions and changes to the project structure.

---

## Current Architecture: Clean Architecture with Feature-First Organization

**Date:** 2025-03-22

### Decision
Adopted Clean Architecture with feature-first structure to improve code maintainability, testability, and scalability.

### Key Changes
- Introduced layered architecture: Presentation → Domain ← Data
- Enforced dependency direction (inward to Domain)
- Defined feature structure with independent modules
- Established DTO ↔ Entity mapping via Mappers
- Standardized error handling with Either<Failure, T>
- Configured Dependency Injection with GetIt
- Selected Provider as the sole state manager

### Impact
- Clear separation of concerns
- Domain layer remains pure Dart (testable without Flutter)
- Data layer isolated (easy to swap APIs/data sources)
- Presentation layer decoupled from data formats
- Consistent patterns across all features

### Related Files
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — complete architecture specification
- [`project.md`](project.md) — project configuration and rules
- [`docs/features/property.md`](docs/features/property.md) — feature implementation example

---

## State Management: Provider

**Date:** 2025-03-22

### Decision
Provider chosen as the single state management solution.

### Rationale
- Already in use in the project (existing `PropertyProvider`)
- Simple and lightweight
- Good integration with ChangeNotifier
- Suitable for the app's complexity

### Rules
- Only Provider allowed (no Bloc, Riverpod, GetX, etc.)
- Use `ChangeNotifier` for stateful providers
- Use `ConsumerWidget` for consuming state
- All state logic in providers, UI only displays

### Related Files
- [`project.md`](project.md#state-management) — state management configuration

---

## Error Handling: Dartz Either

**Date:** 2025-03-22

### Decision
Adopted `dartz` Either<Failure, T> for functional error handling.

### Rationale
- Explicit error handling (no exceptions in UI)
- Type-safe error propagation
- Forces handling of both success and failure cases
- Aligns with Clean Architecture best practices

### Failure Hierarchy
- `Failure` (abstract base)
- `ServerFailure`
- `ParseFailure`
- `NetworkFailure`
- `UnexpectedFailure`

### Related Files
- [`ARCHITECTURE.md`](ARCHITECTURE.md#error-handling) — error handling patterns
- [`project.md`](project.md#error-handling) — error handling rules

---

## Dependency Injection: GetIt

**Date:** 2025-03-22

### Decision
GetIt selected for service locator pattern.

### Rationale
- Simple setup
- No need for code generation (unlike Riverpod)
- Works well with Provider
- Lazy singleton and factory support

### Registration Pattern
- External dependencies → lazy singleton
- Repositories → lazy singleton
- Use Cases → lazy singleton
- Providers → factory (new instance per consumer)

### Related Files
- [`ARCHITECTURE.md`](ARCHITECTURE.md#dependency-injection) — DI setup
- [`project.md`](project.md#dependency-injection) — DI configuration

---

## Data Models: Freezed + JsonSerializable

**Date:** 2025-03-22

### Decision
Use Freezed for immutable data classes and union types; JsonSerializable for JSON serialization.

### Rationale
- Immutability by default
- Built-in equality and toString
- Union types support (for state management)
- Code generation reduces boilerplate
- Field renaming support (snake_case ↔ camelCase)

### Usage
- **Entities** (Domain): plain classes (no annotations)
- **DTOs** (Data): `@freezed` or `@JsonSerializable(fieldRename: FieldRename.snake)`

### Related Files
- [`ARCHITECTURE.md`](ARCHITECTURE.md#dto-and-mapper-rules) — DTO/Entity rules
- [`project.md`](project.md#data-models) — model guidelines

---

## Feature: Property Refactoring

**Date:** 2025-03-22

### Decision
Refactor monolithic `lib/main.dart` into feature-first Clean Architecture structure.

### Current State
- All code in single file (583 lines)
- `PropertyModel` mixes Entity and JSON logic
- `PropertyService` handles HTTP directly
- No separation of layers
- No DI, no error handling

### Target State
- Feature structure: `lib/features/property/{data,domain,presentation}`
- Domain: `Property` entity, `PropertyRepository` interface, `GetProperties` use case
- Data: `PropertyDto`, `PropertyMapper`, `PropertyRemoteDataSource`, `PropertyRepositoryImpl`
- Presentation: `PropertyProvider`, `PropertyScreen`, `PropertyCard`
- DI via GetIt
- Error handling with Either<Failure, T>

### Migration Steps
See [`docs/features/property.md`](docs/features/property.md#migration-steps)

---

## API Configuration: Externalized

**Date:** 2025-03-22

### Decision
Move hardcoded API URL and constants to configuration.

### Options
1. **Environment variables** via `flutter_dotenv` (`.env` file)
2. **Compile-time constants** via `String.fromEnvironment`

### Implementation
```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  static const int defaultPageSize = 20;
}
```

### Related Files
- [`project.md`](project.md#api-configuration) — configuration guidelines

---

## Testing Strategy

**Date:** 2025-03-22

### Decision
Three-level testing strategy: Unit → Widget → Integration.

### Coverage Goals
- Domain layer: high (≥80%)
- State management: high
- UI components: moderate
- Integration tests: critical flows only

### Tools
- `test` package for unit/widget tests
- `flutter_test` for widget tests
- `mocktail` for mocking
- `bloc_test` (if using Bloc)
- `golden_toolkit` (optional for golden tests)

### Related Files
- [`testing.md`](testing.md) — complete testing guide
- [`project.md`](project.md#testing-rules) — testing rules

---

## Future Considerations

### Potential Additions
- **Local storage** (Hive/Isar) for caching
- **Navigation router** (GoRouter/Beamer) with centralized routing
- **Internationalization** (AppLocalizations)
- **Analytics** (Firebase Analytics)
- **Crash reporting** (Sentry)
- **Feature flags** (remote config)

### Not In Scope
- **Multiple state managers** — strictly one (Provider)
- **Changing architecture** — requires Architect mode approval
- **Breaking existing patterns** — must follow established rules

---

## Summary

This document tracks the key architectural decisions that shape the project. All changes must align with these decisions unless a new decision is recorded here.

For detailed implementation guidelines, refer to:
- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`project.md`](project.md)
- [`testing.md`](testing.md)
- [`docs/features/`](docs/features/)
