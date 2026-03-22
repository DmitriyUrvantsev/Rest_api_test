import 'package:flutter/material.dart';

/// Класс для управления маршрутизацией в приложении
///
/// Содержит константы имен маршрутов и методы для навигации
class AppRouter {
  /// Имя начального маршрута
  static const String initialRoute = '/';

  /// Имя маршрута для экрана Property
  static const String propertyRoute = '/property';

  /// Имя маршрута для экрана Property Detail
  static const String propertyDetailRoute = '/property/detail';

  /// Генератор маршрутов
  ///
  /// Используется в MaterialApp.onGenerateRoute
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        // TODO: Вернуть маршрут для главного экрана
        // return MaterialPageRoute(builder: (_) => HomeScreen());
        break;
      case propertyRoute:
        // TODO: Вернуть маршрут для экрана Property
        // return MaterialPageRoute(builder: (_) => PropertyScreen());
        break;
      case propertyDetailRoute:
        // final args = settings.arguments as PropertyDetailArgs?;
        // return MaterialPageRoute(
        //   builder: (_) => PropertyDetailScreen(propertyId: args?.id),
        // );
        break;
    }
    return null;
  }

  /// Метод-хелпер для навигации с аргументами
  static void navigateTo(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// Метод-хелпер для возврата назад
  static void goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Метод-хелпер для замены текущего экрана
  static void replaceWith(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Метод-хелпер для очистки стека навигации и перехода на новый экран
  static void navigateAndClearStack(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }
}
