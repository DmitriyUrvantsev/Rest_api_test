# Feature: Property

## Overview

Feature **Property** отвечает за отображение списка недвижимости (квартир) с возможностью фильтрации по поисковому запросу и городу.

**Текущее состояние:** монолитный код в `lib/main.dart`
**Целевое состояние:** Clean Architecture с разделением на слои

---

## Business Requirements

- Пользователь видит список квартир
- Поддерживается пагинация (page, limit)
- Поддерживается фильтрация:
  - По текстовому запросу (поиск по заголовку)
  - По городу
- Отображение состояний: загрузка, успех, ошибка, пустой список

---

## API Contract

**Endpoint:** `GET /api/v1/flats/items`

**Query Parameters:**
- `page` (int, required) — номер страницы
- `limit` (int, required) — количество элементов на странице
- `title` (string, optional) — поисковый запрос
- `city` (string, optional) — фильтр по городу

**Response (JSON array):**
```json
[
  {
    "id": "string",
    "title": "string",
    "price": 0,
    "area": 0,
    "rooms": 0,
    "city": "string",
    "image": "string"
  }
]
```

---

## Target Architecture

### Feature Structure

```
lib/features/property/
├── data/
│   ├── dto/
│   │   └── property_dto.dart
│   ├── mappers/
│   │   └── property_mapper.dart
│   ├── data_sources/
│   │   └── property_remote_data_source.dart
│   └── repositories/
│       └── property_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── property.dart
│   ├── repositories/
│   │   └── property_repository.dart
│   └── use_cases/
│       └── get_properties.dart
└── presentation/
    ├── screens/
    │   └── property_screen.dart
    ├── widgets/
    │   └── property_card.dart
    └── providers/
        └── property_provider.dart
```

---

## Layer Implementation Details

### 1. Domain Layer

#### Entity: `Property`

**File:** `lib/features/property/domain/entities/property.dart`

```dart
class Property {
  final String id;
  final String title;
  final int price;
  final int area;
  final int rooms;
  final String city;
  final String image;

  Property({
    required this.id,
    required this.title,
    required this.price,
    required this.area,
    required this.rooms,
    required this.city,
    required this.image,
  });
}
```

**Rules:**
- Immutable (all `final`)
- camelCase naming
- No Flutter dependencies
- No JSON annotations

#### Repository Interface: `PropertyRepository`

**File:** `lib/features/property/domain/repositories/property_repository.dart`

```dart
abstract class PropertyRepository {
  Future<Either<Failure, List<Property>>> getProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  });
}
```

**Returns:** `Either<Failure, List<Property>>`
- `Right(List<Property>)` — успешный результат
- `Left(Failure)` — ошибка (ServerFailure, ParseFailure, NetworkFailure, UnexpectedFailure)

#### Use Case: `GetProperties`

**File:** `lib/features/property/domain/use_cases/get_properties.dart`

```dart
class GetProperties {
  final PropertyRepository repository;

  GetProperties(this.repository);

  Future<Either<Failure, List<Property>>> call({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) {
    return repository.getProperties(
      page: page,
      limit: limit,
      query: query,
      city: city,
    );
  }
}
```

**Responsibility:** Просто делегирует вызов в репозиторий. В будущем может содержать дополнительную бизнес-логику (валидацию, кэширование и т.д.).

---

### 2. Data Layer

#### DTO: `PropertyDto`

**File:** `lib/features/property/data/dto/property_dto.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_dto.freezed.dart';
part 'property_dto.g.dart';

@freezed
class PropertyDto with _$PropertyDto {
  const factory PropertyDto({
    required String id,
    required String title,
    required int price,
    required int area,
    required int rooms,
    required String city,
    required String image,
  }) = _PropertyDto;

  factory PropertyDto.fromJson(Map<String, dynamic> json) =>
      _$PropertyDtoFromJson(json);
}
```

**Rules:**
- snake_case поля (как в API)
- `@JsonSerializable(fieldRename: FieldRename.snake)` если не используется Freezed
- Immutable
- Автоматическая сериализация через `build_runner`

#### Mapper: `PropertyMapper`

**File:** `lib/features/property/data/mappers/property_mapper.dart`

```dart
class PropertyMapper {
  static Property toEntity(PropertyDto dto) => Property(
        id: dto.id,
        title: dto.title,
        price: dto.price,
        area: dto.area,
        rooms: dto.rooms,
        city: dto.city,
        image: dto.image,
      );

  static PropertyDto fromEntity(Property entity) => PropertyDto(
        id: entity.id,
        title: entity.title,
        price: entity.price,
        area: entity.area,
        rooms: entity.rooms,
        city: entity.city,
        image: entity.image,
      );
}
```

**Rules:**
- Статические методы
- Централизованная конвертация
- Никакой логики, только маппинг полей

#### Remote Data Source: `PropertyRemoteDataSource`

**File:** `lib/features/property/data/data_sources/property_remote_data_source.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PropertyRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  PropertyRemoteDataSource({required this.client, required this.baseUrl});

  Future<List<PropertyDto>> fetchProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (query != null && query.isNotEmpty) 'title': query,
      if (city != null && city.isNotEmpty) 'city': city,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw ServerException('Failed to load properties: ${response.statusCode}');
    }

    final jsonList = json.decode(response.body) as List<dynamic>;
    return jsonList
        .map((json) => PropertyDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

**Rules:**
- Только HTTP/сетевая логика
- Возвращает DTOs, не Entities
- Бросает исключения (ServerException, FormatException) на ошибках
- Никакой обработки Either — это в репозитории

#### Repository Implementation: `PropertyRepositoryImpl`

**File:** `lib/features/property/data/repositories/property_repository_impl.dart`

```dart
class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource remoteDataSource;

  PropertyRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Property>>> getProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    try {
      final dtos = await remoteDataSource.fetchProperties(
        page: page,
        limit: limit,
        query: query,
        city: city,
      );
      final entities = dtos.map(PropertyMapper.toEntity).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on FormatException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: $e'));
    }
  }
}
```

**Rules:**
- Реализует интерфейс из Domain
- Конвертирует DTO → Entity через Mapper
- Оборачивает исключения в Either<Failure, T>
- Не содержит бизнес-логики

---

### 3. Presentation Layer

#### Provider: `PropertyProvider`

**File:** `lib/features/property/presentation/providers/property_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/property.dart';
import '../../domain/use_cases/get_properties.dart';
import '../../../core/error/failure.dart';

class PropertyProvider extends ChangeNotifier {
  final GetProperties getProperties;

  PropertyProvider({required this.getProperties});

  List<Property>? _properties;
  List<Property> get properties => _properties ?? [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Failure? _failure;
  Failure? get failure => _failure;

  Future<void> loadProperties({
    required int page,
    required int limit,
    String? query,
    String? city,
  }) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final result = await getProperties(
      page: page,
      limit: limit,
      query: query,
      city: city,
    );

    result.fold(
      (failure) {
        _failure = failure;
        _isLoading = false;
      },
      (properties) {
        _properties = properties;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  void clear() {
    _properties = null;
    _failure = null;
    notifyListeners();
  }
}
```

**Rules:**
- Наследуется от `ChangeNotifier`
- Вызывает Use Cases
- Управляет состоянием (loading, data, error)
- Использует `Either.fold` для обработки результата
- Вызывает `notifyListeners()` после изменений

#### Screen: `PropertyScreen`

**File:** `lib/features/property/presentation/screens/property_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/property.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';
import '../../../core/error/failure.dart';

class PropertyScreen extends ConsumerWidget {
  const PropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(propertyProvider);

    // Loading state
    if (provider.isLoading && provider.properties.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (provider.failure != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Properties')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_mapFailureToMessage(provider.failure!)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.loadProperties(
                  page: 1,
                  limit: 20,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Success state
    final properties = provider.properties;
    if (properties.isEmpty) {
      return const Scaffold(
        appBar: AppBar(title: Text('Properties')),
        body: Center(child: Text('No properties found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      body: RefreshIndicator(
        onRefresh: () => provider.loadProperties(
          page: 1,
          limit: 20,
        ),
        child: ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return PropertyCard(property: property);
          },
        ),
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Ошибка сервера. Попробуйте позже.';
    }
    if (failure is ParseFailure) {
      return 'Ошибка обработки данных.';
    }
    if (failure is NetworkFailure) {
      return 'Проверьте подключение к интернету.';
    }
    return 'Неизвестная ошибка';
  }
}
```

**Rules:**
- `ConsumerWidget` для доступа к Provider
- Отдельные UI для каждого состояния
- Никакой бизнес-логики
- Только отображение и навигация

#### Widget: `PropertyCard`

**File:** `lib/features/property/presentation/widgets/property_card.dart`

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              property.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image, size: 48),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${property.price} ₽',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      property.city,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(Icons.square_foot, '${property.area} м²'),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.meeting_room, '${property.rooms} комн.'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
```

**Rules:**
- `StatelessWidget` по умолчанию
- Использует Theme для стилей
- Принимает Entity (не DTO)
- Обработка ошибок загрузки изображений

---

## Dependency Injection Setup

**File:** `lib/core/di/service_locator.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/property/data/data_sources/property_remote_data_source.dart';
import '../../features/property/data/repositories/property_repository_impl.dart';
import '../../features/property/domain/repositories/property_repository.dart';
import '../../features/property/domain/use_cases/get_properties.dart';
import '../../features/property/presentation/providers/property_provider.dart';
import '../config/app_config.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // External dependencies
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Configuration
  getIt.registerLazySingleton<String>(
    instanceName: 'apiBaseUrl',
    () => AppConfig.apiBaseUrl,
  );

  // Data layer
  getIt.registerLazySingleton<PropertyRemoteDataSource>(
    () => PropertyRemoteDataSource(
      client: getIt<http.Client>(),
      baseUrl: getIt<String>(instanceName: 'apiBaseUrl'),
    ),
  );

  getIt.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(getIt<PropertyRemoteDataSource>()),
  );

  // Domain layer
  getIt.registerLazySingleton<GetProperties>(
    () => GetProperties(getIt<PropertyRepository>()),
  );

  // Presentation layer
  getIt.registerFactory<PropertyProvider>(
    () => PropertyProvider(getProperties: getIt<GetProperties>()),
  );
}
```

---

## Main.dart Integration

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'features/property/presentation/providers/property_provider.dart';

void main() {
  setupServiceLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PropertyProvider>(
          create: (_) => getIt<PropertyProvider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Order App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const PropertyScreen(),
    );
  }
}
```

---

## Testing Strategy

### Unit Tests

**Location:** `test/unit/features/property/`

**Files:**
- `property_test.dart` — Entity валидация
- `property_mapper_test.dart` — маппинг DTO ↔ Entity
- `get_properties_test.dart` — Use Case с моками репозитория
- `property_repository_impl_test.dart` — Repository с моками DataSource

**Example:**
```dart
test('PropertyMapper should convert DTO to Entity correctly', () {
  final dto = PropertyDto(
    id: '1',
    title: 'Test',
    price: 1000,
    area: 50,
    rooms: 2,
    city: 'Moscow',
    image: 'http://example.com/image.jpg',
  );

  final entity = PropertyMapper.toEntity(dto);

  expect(entity.id, '1');
  expect(entity.title, 'Test');
  expect(entity.price, 1000);
  // ... остальные поля
});
```

### Widget Tests

**Location:** `test/widget/features/property/`

**Files:**
- `property_screen_test.dart` — все состояния экрана
- `property_card_test.dart` — рендеринг карточки
- `property_provider_test.dart` — state transitions

**Example:**
```dart
testWidgets('PropertyScreen should show loading indicator', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PropertyProvider(
            getProperties: MockGetProperties(),
          ),
        ),
      ],
      child: const MaterialApp(home: PropertyScreen()),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Integration Tests

**Location:** `integration_test/property_test.dart**

**Scenario:** Полный поток загрузки и отображения списка

---

## Migration Steps (for Code Mode)

1. Создать структуру папок `lib/features/property/`
2. Перенести `PropertyModel` → `domain/entities/property.dart` (убрать fromJson/toJson)
3. Создать `data/dto/property_dto.dart` с Freezed/JsonSerializable
4. Создать `data/mappers/property_mapper.dart`
5. Создать `data/data_sources/property_remote_data_source.dart` (перенести логику из PropertyService)
6. Создать `domain/repositories/property_repository.dart` (интерфейс)
7. Создать `data/repositories/property_repository_impl.dart`
8. Создать `domain/use_cases/get_properties.dart`
9. Создать `presentation/providers/property_provider.dart` (перенести логику из текущего PropertyProvider)
10. Создать `presentation/widgets/property_card.dart` (вынести из PropertyScreen)
11. Обновить `presentation/screens/property_screen.dart` (использовать ConsumerWidget)
12. Создать `lib/core/di/service_locator.dart` и настроить DI
13. Обновить `lib/main.dart` для использования GetIt
14. Добавить зависимости в `pubspec.yaml`: `dartz`, `get_it`, `freezed`, `json_serializable`, `build_runner`
15. Запустить `flutter pub run build_runner build`
16. Удалить старый `PropertyService` из `main.dart`

---

## Notes

- Все слои должны следовать правилам из `ARCHITECTURE.md`
- State Management: только Provider
- Ошибки: Either<Failure, T>
- DI: GetIt
- API URL: вынести в `AppConfig`
- Тестирование: unit + widget + integration

---

## Related Documentation

- `ARCHITECTURE.md` — общая архитектура проекта
- `project.md` — конфигурация проекта и правила
- `testing.md` — стратегия тестирования
