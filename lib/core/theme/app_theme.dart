import 'package:flutter/material.dart';

/// Базовый класс для кастомных цветов темы
///
/// Добавляет дополнительные цвета, не входящие в стандартную ColorScheme
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? accent;
  final Color? success;
  final Color? warning;
  final Color? info;

  const CustomColors({
    this.accent,
    this.success,
    this.warning,
    this.info,
  });

  @override
  CustomColors copyWith({
    Color? accent,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return CustomColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      accent: Color.lerp(accent, other.accent, t),
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      info: Color.lerp(info, other.info, t),
    );
  }

  String get debugLabel => 'CustomColors';
}

/// Конфигурация темы приложения
///
/// Содержит:
/// - lightTheme - светлая тема
/// - darkTheme - темная тема
/// - themeData - общий метод для создания ThemeData
class AppTheme {
  static const Color _primaryColor = Colors.blue;
  static const Color _secondaryColor = Colors.amber;

  /// Светлая тема
  static ThemeData get lightTheme {
    return themeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
    );
  }

  /// Темная тема
  static ThemeData get darkTheme {
    return themeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }

  /// Создает ThemeData с заданной ColorScheme и кастомными расширениями
  static ThemeData themeData({
    required ColorScheme colorScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: const <ThemeExtension<dynamic>>[
        CustomColors(
          accent: _secondaryColor,
          success: Colors.green,
          warning: Colors.orange,
          info: Colors.cyan,
        ),
      ],
    );
  }
}
