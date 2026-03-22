import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'features/property/domain/repositories/property_repository.dart';
import 'features/property/presentation/providers/property_provider.dart';
import 'features/property/presentation/screens/property_screen.dart';

void main() {
  setupServiceLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PropertyProvider(
            repository: serviceLocator<PropertyRepository>(),
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
    return const MaterialApp(
      title: 'Test Order App',
      debugShowCheckedModeBanner: false,
      home: PropertyScreen(),
    );
  }
}
