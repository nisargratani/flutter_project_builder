// ignore_for_file: public_member_api_docs

/// Template strings for core.
class ConstantsTemplate {
  ConstantsTemplate._();

  static const String appStrings = r'''
class AppStrings {
  AppStrings._();
  static const String appName = 'Flutter App';
}
''';

  static const String appAssets = r'''
class AppAssets {
  AppAssets._();
}
''';

  static const String appColors = r'''
import 'package:flutter/material.dart';

/// Brand colors. `AppTheme` builds the light and dark color schemes from
/// these values, so change them here.
class AppColors {
  AppColors._();

  // Light theme.
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);

  // Dark theme (lighter accents for contrast on dark surfaces).
  static const Color primaryDark = Color(0xFFBB86FC);
  static const Color secondaryDark = Color(0xFF03DAC6);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorDark = Color(0xFFCF6679);

  static const Color onPrimaryDark = Color(0xFF000000);
  static const Color onSecondaryDark = Color(0xFF000000);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);
}
''';

  static const String appDimensions = r'''
class AppDimensions {
  AppDimensions._();
  
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p48 = 48.0;
  static const double p64 = 64.0;
}
''';

  static const String appDurations = r'''
class AppDurations {
  AppDurations._();
  
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
''';

  static const String appIcons = r'''
class AppIcons {
  AppIcons._();
}
''';

  static const String appImages = r'''
class AppImages {
  AppImages._();
}
''';
}
