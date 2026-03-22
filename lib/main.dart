import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/property_provider.dart';
import 'screens/property_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PropertyProvider(),
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
