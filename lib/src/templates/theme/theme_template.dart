// ignore_for_file: public_member_api_docs

/// Template strings for theme.
class ThemeTemplate {
  ThemeTemplate._();

  static const String appTheme = r'''
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Material 3 light and dark themes built from [AppColors].
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(
        const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
          onError: AppColors.onError,
        ),
        background: AppColors.background,
      );

  static ThemeData get darkTheme => _build(
        const ColorScheme.dark(
          primary: AppColors.primaryDark,
          onPrimary: AppColors.onPrimaryDark,
          secondary: AppColors.secondaryDark,
          onSecondary: AppColors.onSecondaryDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.onSurfaceDark,
          error: AppColors.errorDark,
          onError: AppColors.onErrorDark,
        ),
        background: AppColors.backgroundDark,
      );

  static ThemeData _build(ColorScheme colorScheme, {required Color background}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
      ),
    );
  }
}
''';
}
