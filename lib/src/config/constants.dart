/// Package-level constants for flutter_project_builder.
///
/// Contains version information, default values, and configuration
/// keys used throughout the CLI tool.
class PackageConstants {
  PackageConstants._();

  /// Current version of the package.
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
  static const String minDartSdk = '3.4.0';

  /// Minimum Flutter SDK version for generated projects.
  static const String minFlutterSdk = '3.22.0';

  /// Generated project dependencies with versions.
  static const Map<String, String> generatedDependencies = {
    'flutter_riverpod': '^3.3.2',
    'riverpod_annotation': '^4.0.3',
    'go_router': '^17.3.0',
    'dio': '^5.11.0',
    'hive_ce': '^2.19.3',
    'hive_ce_flutter': '^2.3.4',
    'flutter_localizations': 'sdk: flutter',
    'intl': '^0.20.2',
    'cached_network_image': '^3.4.1',
    'shimmer': '^3.0.0',
    'gap': '^3.0.1',
    'url_launcher': '^6.3.1',
    'connectivity_plus': '^6.1.4',
    'share_plus': '^10.1.4',
    'permission_handler': '^11.4.0',
    'path_provider': '^2.1.5',
  };

  /// Generated project dev dependencies.
  static const Map<String, String> generatedDevDependencies = {
    'flutter_test': 'sdk: flutter',
    'flutter_lints': '^5.0.0',
    'mocktail': '^1.0.4',
    'network_image_mock': '^2.1.1',
  };

  /// Files generated during a clean architecture scaffold.
  static const String generatedMarkerFile = '.flutter_project_builder';
}
