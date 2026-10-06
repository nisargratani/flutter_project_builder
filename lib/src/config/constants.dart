/// Package-level constants for flutter_project_builder.
///
/// Contains version information, default values, and configuration
/// keys used throughout the CLI tool.
class PackageConstants {
  PackageConstants._();

  /// Current version of the package.
  ///
  /// Must be kept in sync with the `version` field in `pubspec.yaml`.
  static const String version = '0.0.1';

  /// Package name.
  static const String packageName = 'flutter_project_builder';

  /// Package description.
  static const String description =
      'Generate enterprise-grade Flutter project architectures in seconds.';

  /// Configuration file name.
  static const String configFileName = 'flutter_project_builder.yaml';

  /// Default organization name.
  static const String defaultOrganization = 'com.example';

  /// Supported templates.
  static const List<String> templates = ['basic', 'clean', 'enterprise'];

  /// Default template.
  static const String defaultTemplate = 'clean';

  /// Default flavors.
  static const List<String> defaultFlavors = ['dev', 'stage', 'prod'];

  /// Minimum Dart SDK version for generated projects.
  ///
  /// Imposed by `flutter_riverpod` 3.x.
  static const String minDartSdk = '3.8.0';

  /// Minimum Flutter SDK version for generated projects.
  ///
  /// Flutter 3.32 is the first stable release that ships Dart 3.8 and
  /// generates localizations into the source tree (`lib/l10n/`).
  static const String minFlutterSdk = '3.32.0';

  /// Catalog of dependencies that may be added to a generated project.
  ///
  /// Which entries are actually added depends on the `ProjectConfig`
  /// options (for example `dio` is only added when the network layer is
  /// enabled). Entries already present in the project are never changed.
  ///
  /// `firebase_core` is only added when Firebase is enabled.
  ///
  /// `intl` uses `any` because `flutter_localizations` pins the exact
  /// version for each Flutter release.
  static const Map<String, String> generatedDependencies = {
    'flutter_riverpod': '^3.0.0',
    'go_router': '^17.0.0',
    'dio': '^5.4.0',
    'hive_ce': '^2.6.0',
    'hive_ce_flutter': '^2.0.0',
    'flutter_localizations': 'sdk: flutter',
    'intl': 'any',
    'connectivity_plus': '^7.0.0',
    'firebase_core': '^4.0.0',
  };

  /// Generated project dev dependencies.
  static const Map<String, String> generatedDevDependencies = {
    'flutter_test': 'sdk: flutter',
    'flutter_lints': '^6.0.0',
    'mocktail': '^1.0.4',
  };

  /// Marker file written into `lib/` after a successful generation.
  ///
  /// Its presence is used to detect an already generated project.
  static const String generatedMarkerFile = '.flutter_project_builder';
}
