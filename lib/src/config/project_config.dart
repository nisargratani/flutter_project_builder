import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/string_utils.dart';
import 'constants.dart';

/// Parsed project configuration from `flutter_project_builder.yaml`.
///
/// Reads and validates the configuration file, providing typed access
/// to all configuration options with sensible defaults.
class ProjectConfig {
  /// Creates a [ProjectConfig] with the given options.
  const ProjectConfig({
    this.organization = PackageConstants.defaultOrganization,
    this.template = PackageConstants.defaultTemplate,
    this.flavors = const [],
    this.riverpod = true,
    this.firebase = false,
    this.hive = true,
    this.dio = true,
    this.localization = true,
    this.sampleFeatures = true,
  });

  /// Loads configuration from the YAML file in [projectPath].
  ///
  /// Falls back to defaults if the file does not exist or is empty.
  ///
  /// Throws a [FormatException] if the file is not valid YAML, is not a
  /// map, or contains values of the wrong type (see [ProjectConfig.fromYaml]).
  factory ProjectConfig.fromDirectory(String projectPath) {
    final configFile = File(configPath(projectPath));
    if (!configFile.existsSync()) {
      return const ProjectConfig();
    }
    return ProjectConfig.fromYaml(
      configFile.readAsStringSync(),
      sourceName: PackageConstants.configFileName,
    );
  }

  /// Parses configuration from YAML [content].
  ///
  /// Missing keys fall back to their defaults. [sourceName] is used in
  /// error messages.
  ///
  /// Throws a [FormatException] when:
  /// - the content is not valid YAML or not a map,
  /// - a value has the wrong type (for example `dio: "yes"`),
  /// - `template` is not one of [PackageConstants.templates],
  /// - a flavor name is not a valid lowercase Dart identifier.
  factory ProjectConfig.fromYaml(
    String content, {
    String sourceName = PackageConstants.configFileName,
  }) {
    final Object? yaml;
    try {
      yaml = loadYaml(content);
    } on YamlException catch (e) {
      throw FormatException('Invalid YAML in $sourceName: ${e.message}');
    }

    if (yaml == null) return const ProjectConfig();
    if (yaml is! YamlMap) {
      throw FormatException(
        '$sourceName must contain a map of options, '
        'found ${yaml.runtimeType}.',
      );
    }

    final map = yaml;
    T read<T>(String key, T fallback) {
      final value = map[key];
      if (value == null) return fallback;
      if (value is T) return value;
      throw FormatException(
        'Invalid value for "$key" in $sourceName: expected $T, '
        'found "$value".',
      );
    }

    final template = read<String>('template', PackageConstants.defaultTemplate);
    if (!PackageConstants.templates.contains(template)) {
      throw FormatException(
        'Invalid template "$template" in $sourceName. '
        'Allowed values: ${PackageConstants.templates.join(', ')}.',
      );
    }

    final flavors = _parseFlavors(map['flavors'], sourceName);

    return ProjectConfig(
      organization: read<Object>(
        'organization',
        PackageConstants.defaultOrganization,
      ).toString(),
      template: template,
      flavors: flavors,
      riverpod: read<bool>('riverpod', true),
      firebase: read<bool>('firebase', false),
      hive: read<bool>('hive', true),
      dio: read<bool>('dio', true),
      localization: read<bool>('localization', true),
      sampleFeatures: read<bool>('sample_features', true),
    );
  }

  /// Returns the path of the configuration file inside [projectPath].
  static String configPath(String projectPath) =>
      p.join(projectPath, PackageConstants.configFileName);

  /// Whether [projectPath] contains a configuration file.
  static bool existsIn(String projectPath) =>
      File(configPath(projectPath)).existsSync();

  /// Organization identifier (e.g., `com.example`).
  ///
  /// Recorded in the configuration file only; it does not change the
  /// bundle identifiers of an existing project.
  final String organization;

  /// Architecture template: `basic`, `clean`, or `enterprise`.
  final String template;

  /// Flavor names (e.g., `['dev', 'stage', 'prod']`).
  ///
  /// Each flavor produces a `lib/main_<flavor>.dart` entry point.
  final List<String> flavors;

  /// Whether to generate Riverpod helpers.
  ///
  /// The generated app, router and providers always use Riverpod; setting
  /// this to `false` only omits the `AsyncValue` UI extensions.
  final bool riverpod;

  /// Whether to prepare the Firebase folder (`lib/core/firebase/`).
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

  /// Creates a copy with the given overrides.
  ProjectConfig copyWith({
    String? organization,
    String? template,
    List<String>? flavors,
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

organization: $organization

# Architecture template: basic, clean, enterprise
template: $template

# Flavor names; each produces lib/main_<flavor>.dart
${flavors.isEmpty ? 'flavors: []' : 'flavors:\n${flavors.map((f) => '  - $f').join('\n')}'}

# State management
riverpod: $riverpod

# Backend integrations
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
