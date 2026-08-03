// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for theme.
class ThemeTemplate {
  ThemeTemplate._();

  static const String appTheme = '''
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onSurface: AppColors.onSurface,
        onError: AppColors.onError,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    // Implement dark theme here
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(),
    );
  }
}
''';
}
