import 'package:get_it/get_it.dart';
import '../../features/property/data/repositories/property_repository_impl.dart';
import '../../features/property/domain/repositories/property_repository.dart';
import '../../features/property/domain/usecases/get_properties.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  serviceLocator.registerLazySingleton<PropertyRepository>(
    () => PropertyRepositoryImpl(),
  );
  serviceLocator.registerLazySingleton<GetProperties>(
    () => GetProperties(serviceLocator<PropertyRepository>()),
  );
}
