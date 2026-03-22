import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/property/presentation/providers/property_provider.dart';
import 'features/property/presentation/screens/property_list_screen.dart';
import 'features/property/domain/use_cases/get_properties.dart';
import 'features/property/domain/use_cases/get_property_by_id.dart';

void main() {
  /// Инициализируем Dependency Injection перед запуском приложения
  /// Все зависимости будут зарегистрированы в service locator
  setupServiceLocator();

  runApp(
    MultiProvider(
      providers: [
        /// PropertyProvider регистрируется через ChangeNotifierProvider
        /// и получает зависимости из service locator (GetIt)
        ChangeNotifierProvider<PropertyProvider>(
          create: (context) => PropertyProvider(
            getPropertiesUseCase: serviceLocator<GetProperties>(),
            getPropertyByIdUseCase: serviceLocator<GetPropertyById>(),
          ),
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
      title: 'Test Promt API',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const PropertyListScreen(),
    );
  }
}
