import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

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
  /// Falls back to defaults if the file does not exist.
  factory ProjectConfig.fromDirectory(String projectPath) {
    final configFile = File(
      p.join(projectPath, PackageConstants.configFileName),
    );

    if (!configFile.existsSync()) {
      return const ProjectConfig();
    }

    final content = configFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) {
      return const ProjectConfig();
    }

    return ProjectConfig(
      organization: yaml['organization'] as String? ??
          PackageConstants.defaultOrganization,
      template: yaml['template'] as String? ?? PackageConstants.defaultTemplate,
      flavors: _parseStringList(yaml['flavors']),
      riverpod: yaml['riverpod'] as bool? ?? true,
      firebase: yaml['firebase'] as bool? ?? false,
      hive: yaml['hive'] as bool? ?? true,
      dio: yaml['dio'] as bool? ?? true,
      localization: yaml['localization'] as bool? ?? true,
      sampleFeatures: yaml['sample_features'] as bool? ?? true,
    );
  }

  /// Organization identifier (e.g., `com.example`).
  final String organization;

  /// Architecture template: `basic`, `clean`, or `enterprise`.
  final String template;

  /// Flavor configurations (e.g., `['dev', 'stage', 'prod']`).
  final List<String> flavors;

  /// Whether to generate Riverpod architecture.
  final bool riverpod;

  /// Whether to prepare Firebase folder structure.
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
  String toYaml() => '''
# flutter_project_builder configuration
# This file configures the architecture generation.

organization: $organization

# Architecture template: basic, clean, enterprise
template: $template

# Flavor configurations
flavors:
${flavors.map((f) => '  - $f').join('\n')}

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

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is YamlList) {
      return value.map((dynamic e) => e.toString()).toList();
    }
    return [];
  }
}
