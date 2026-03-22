import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/property/data/services/property_service.dart';
import '../../features/property/data/repositories/property_repository_impl.dart';
import '../../features/property/domain/repositories/property_repository.dart';
import '../../features/property/domain/use_cases/get_properties.dart';
import '../../features/property/domain/use_cases/get_property_by_id.dart';
import '../../features/property/presentation/providers/property_provider.dart';

/// Глобальный экземпляр GetIt для регистрации и получения сервисов
final GetIt serviceLocator = GetIt.instance;

/// Конфигурация всех зависимостей приложения
///
/// Этот метод должен быть вызван при запуске приложения
/// для регистрации всех сервисов, репозиториев и use cases.
/// Порядок регистрации важен:
/// 1. HTTP Client (как lazy singleton)
/// 2. Data Layer сервисы (как singleton)
/// 3. Data Layer репозитории (как singleton)
/// 4. Domain Layer use cases (как singleton)
/// 5. Presentation Layer providers (как lazy singleton)
void setupServiceLocator() {
  // ========== INFRASTRUCTURE ==========
  // HTTP Client - lazy singleton, создается при первом обращении
  serviceLocator.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  // ========== DATA LAYER ==========
  // PropertyService - singleton, зависит от HTTP Client
  /// Сервис для работы с Property API.
  /// Отвечает за низкоуровневые HTTP запросы к бэкенду.
  serviceLocator.registerSingleton<PropertyService>(
    PropertyService(
      httpClient: serviceLocator<http.Client>(),
    ),
  );

  // PropertyRepositoryImpl - singleton, зависит от PropertyService
  /// Реализация репозитория для работы с Property.
  /// Использует PropertyService для получения данных и преобразует DTO в Entity.
  serviceLocator.registerSingleton<PropertyRepository>(
    PropertyRepositoryImpl(
      propertyService: serviceLocator<PropertyService>(),
    ),
  );

  // ========== DOMAIN LAYER ==========
  // GetProperties - singleton, зависит от PropertyRepository
  /// Use Case для получения списка свойств с пагинацией и фильтрацией.
  /// Инкапсулирует бизнес-логику получения списка недвижимости.
  serviceLocator.registerSingleton<GetProperties>(
    GetProperties(serviceLocator<PropertyRepository>()),
  );

  // GetPropertyById - singleton, зависит от PropertyRepository
  /// Use Case для получения свойства по идентификатору.
  /// Инкапсулирует бизнес-логику получения одной недвижимости по ID.
  serviceLocator.registerSingleton<GetPropertyById>(
    GetPropertyById(serviceLocator<PropertyRepository>()),
  );

  // ========== PRESENTATION LAYER ==========
  // PropertyProvider - lazy singleton, зависит от use cases
  /// Provider для управления состоянием Property в UI.
  /// Отвечает за загрузку списка свойств, фильтрацию, пагинацию.
  /// Использует debounce для поиска (300ms).
  serviceLocator.registerLazySingleton<PropertyProvider>(
    () => PropertyProvider(
      getPropertiesUseCase: serviceLocator<GetProperties>(),
      getPropertyByIdUseCase: serviceLocator<GetPropertyById>(),
    ),
  );
}
