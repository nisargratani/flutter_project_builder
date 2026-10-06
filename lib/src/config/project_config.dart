import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/string_utils.dart';
import 'constants.dart';

/// Parsed project configuration from `flutter_project_builder.yaml`.
///
/// Reads and validates the configuration file, providing typed access
/// to all configuration options with sensible defaults.
///
/// Each template is a preset (see [ProjectConfig.forTemplate]); options set
/// explicitly in the file or on the command line override the preset.
class ProjectConfig {
  /// Creates a [ProjectConfig] with the given options.
  ///
  /// The defaults match the `clean` template.
  const ProjectConfig({
    this.organization = PackageConstants.defaultOrganization,
    this.template = PackageConstants.defaultTemplate,
    this.flavors = const [],
    this.nativeFlavors = true,
    this.riverpod = true,
    this.firebase = false,
    this.hive = true,
    this.dio = true,
    this.localization = true,
    this.sampleFeatures = true,
  });

  /// Returns the preset for [template].
  ///
  /// | Template     | Network | Storage | l10n | Samples | Flavors        |
  /// | ------------ | ------- | ------- | ---- | ------- | -------------- |
  /// | `basic`      | no      | no      | no   | no      | none           |
  /// | `clean`      | yes     | yes     | yes  | yes     | none           |
  /// | `enterprise` | yes     | yes     | yes  | yes     | dev/stage/prod |
  ///
  /// Throws a [FormatException] for an unknown template.
  factory ProjectConfig.forTemplate(String template) => switch (template) {
        'basic' => const ProjectConfig(
            template: 'basic',
            hive: false,
            dio: false,
            localization: false,
            sampleFeatures: false,
          ),
        'clean' => const ProjectConfig(),
        'enterprise' => const ProjectConfig(
            template: 'enterprise',
            flavors: PackageConstants.defaultFlavors,
          ),
        _ => throw FormatException(
            'Invalid template "$template". '
            'Allowed values: ${PackageConstants.templates.join(', ')}.',
          ),
      };

  /// Loads configuration from the YAML file in [projectPath].
  ///
  /// Falls back to defaults if the file does not exist or is empty.
  /// [templateOverride] replaces the file's `template` as the preset that
  /// missing keys fall back to.
  ///
  /// Throws a [FormatException] if the file is not valid YAML, is not a
  /// map, or contains values of the wrong type (see [ProjectConfig.fromYaml]).
  factory ProjectConfig.fromDirectory(
    String projectPath, {
    String? templateOverride,
  }) {
    final configFile = File(configPath(projectPath));
    if (!configFile.existsSync()) {
      return ProjectConfig.forTemplate(
        templateOverride ?? PackageConstants.defaultTemplate,
      );
    }
    return ProjectConfig.fromYaml(
      configFile.readAsStringSync(),
      sourceName: PackageConstants.configFileName,
      templateOverride: templateOverride,
    );
  }

  /// Parses configuration from YAML [content].
  ///
  /// Missing keys fall back to the preset of the `template` key (or of
  /// [templateOverride] when given). [sourceName] is used in error messages.
  ///
  /// Throws a [FormatException] when:
  /// - the content is not valid YAML or not a map,
  /// - a value has the wrong type (for example `dio: "yes"`),
  /// - `template` is not one of [PackageConstants.templates],
  /// - a flavor name is not a valid lowercase Dart identifier,
  /// - `organization` is not a reverse-domain identifier.
  factory ProjectConfig.fromYaml(
    String content, {
    String sourceName = PackageConstants.configFileName,
    String? templateOverride,
  }) {
    final Object? yaml;
    try {
      yaml = loadYaml(content);
    } on YamlException catch (e) {
      throw FormatException('Invalid YAML in $sourceName: ${e.message}');
    }

    if (yaml != null && yaml is! YamlMap) {
      throw FormatException(
        '$sourceName must contain a map of options, '
        'found ${yaml.runtimeType}.',
      );
    }
    final map = (yaml as YamlMap?) ?? YamlMap();

    T read<T>(String key, T fallback) {
      final value = map[key];
      if (value == null) return fallback;
      if (value is T) return value;
      throw FormatException(
        'Invalid value for "$key" in $sourceName: expected $T, '
        'found "$value".',
      );
    }

    final template = templateOverride ??
        read<String>('template', PackageConstants.defaultTemplate);
    if (!PackageConstants.templates.contains(template)) {
      throw FormatException(
        'Invalid template "$template" in $sourceName. '
        'Allowed values: ${PackageConstants.templates.join(', ')}.',
      );
    }
    final preset = ProjectConfig.forTemplate(template);

    final organization =
        read<Object>('organization', preset.organization).toString();
    if (!isValidOrganization(organization)) {
      throw FormatException(
        'Invalid organization "$organization" in $sourceName. Use a '
        'reverse-domain identifier such as "com.mycompany".',
      );
    }

    return ProjectConfig(
      organization: organization,
      template: template,
      flavors: map.containsKey('flavors')
          ? _parseFlavors(map['flavors'], sourceName)
          : preset.flavors,
      nativeFlavors: read<bool>('native_flavors', preset.nativeFlavors),
      riverpod: read<bool>('riverpod', preset.riverpod),
      firebase: read<bool>('firebase', preset.firebase),
      hive: read<bool>('hive', preset.hive),
      dio: read<bool>('dio', preset.dio),
      localization: read<bool>('localization', preset.localization),
      sampleFeatures: read<bool>('sample_features', preset.sampleFeatures),
    );
  }

  /// Returns the path of the configuration file inside [projectPath].
  static String configPath(String projectPath) =>
      p.join(projectPath, PackageConstants.configFileName);

  /// Whether [projectPath] contains a configuration file.
  static bool existsIn(String projectPath) =>
      File(configPath(projectPath)).existsSync();

  static final RegExp _organizationPattern =
      RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

  /// Whether [value] is a reverse-domain identifier such as `com.example`.
  static bool isValidOrganization(String value) =>
      _organizationPattern.hasMatch(value);

  /// Organization identifier (e.g., `com.example`).
  ///
  /// When it differs from [PackageConstants.defaultOrganization], `create`
  /// sets the Android application ID and the iOS/macOS bundle identifiers
  /// to `<organization>.<package name>`.
  final String organization;

  /// Architecture template: `basic`, `clean`, or `enterprise`.
  final String template;

  /// Flavor names (e.g., `['dev', 'stage', 'prod']`).
  ///
  /// Each flavor produces a `lib/main_<flavor>.dart` entry point and an
  /// entry in `FlavorConfig` with its own `AppConfig` (base URL, app name).
  final List<String> flavors;

  /// Whether to configure native flavors when [flavors] is not empty:
  /// Android product flavors and Xcode schemes/build configurations, so
  /// `flutter run --flavor <name>` works.
  final bool nativeFlavors;

  /// Whether to generate Riverpod helpers.
  ///
  /// The generated app, router and providers always use Riverpod; setting
  /// this to `false` only omits the `AsyncValue` UI extensions.
  final bool riverpod;

  /// Whether to add `firebase_core` and initialise Firebase on startup.
  final bool firebase;

  /// Whether to generate Hive CE storage.
  final bool hive;

  /// Whether to generate Dio networking layer.
  final bool dio;

  /// Whether to generate localization support.
  final bool localization;

  /// Whether to generate sample features (counter + users).
  final bool sampleFeatures;

  /// Whether flavors are enabled.
  bool get hasFlavors => flavors.isNotEmpty;

  /// Whether native (Android/iOS/macOS) flavors will be configured.
  bool get hasNativeFlavors => hasFlavors && nativeFlavors;

  /// Whether a custom organization was chosen.
  bool get hasCustomOrganization =>
      organization != PackageConstants.defaultOrganization;

  /// Creates a copy with the given overrides.
  ProjectConfig copyWith({
    String? organization,
    String? template,
    List<String>? flavors,
    bool? nativeFlavors,
    bool? riverpod,
    bool? firebase,
    bool? hive,
    bool? dio,
    bool? localization,
    bool? sampleFeatures,
  }) =>
      ProjectConfig(
        organization: organization ?? this.organization,
        template: template ?? this.template,
        flavors: flavors ?? this.flavors,
        nativeFlavors: nativeFlavors ?? this.nativeFlavors,
        riverpod: riverpod ?? this.riverpod,
        firebase: firebase ?? this.firebase,
        hive: hive ?? this.hive,
        dio: dio ?? this.dio,
        localization: localization ?? this.localization,
        sampleFeatures: sampleFeatures ?? this.sampleFeatures,
      );

  /// Generates YAML content for this configuration.
  ///
  /// The output can be parsed back with [ProjectConfig.fromYaml].
  String toYaml() => '''
# flutter_project_builder configuration
# This file configures the architecture generation.

# Used for the Android application ID and iOS/macOS bundle identifiers.
organization: $organization

# Preset for options not listed here: basic, clean, enterprise
template: $template

# Flavor names; each produces lib/main_<flavor>.dart
${flavors.isEmpty ? 'flavors: []' : 'flavors:\n${flavors.map((f) => '  - $f').join('\n')}'}

# Configure Android product flavors and Xcode schemes for the flavors
native_flavors: $nativeFlavors

# State management
riverpod: $riverpod

# Firebase (firebase_core); run `flutterfire configure` afterwards
firebase: $firebase

# Local storage
hive: $hive

# Networking
dio: $dio

# Localization
localization: $localization

# Sample features
sample_features: $sampleFeatures
''';

  static List<String> _parseFlavors(Object? value, String sourceName) {
    if (value == null) return const [];
    if (value is! YamlList) {
      throw FormatException(
        '"flavors" in $sourceName must be a list, e.g. [dev, prod].',
      );
    }
    final flavors = <String>[];
    for (final item in value) {
      final name = item.toString();
      if (!StringUtils.isValidIdentifier(name) || name != name.toLowerCase()) {
        throw FormatException(
          'Invalid flavor "$name" in $sourceName. Flavor names must be '
          'lowercase Dart identifiers (letters, digits, underscores) and '
          'not reserved words.',
        );
      }
      if (!flavors.contains(name)) flavors.add(name);
    }
    return flavors;
  }
}
