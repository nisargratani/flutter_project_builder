import 'package:path/path.dart' as p;

import '../cli/cli_logger.dart';
import '../config/constants.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';
import '../utils/pubspec_utils.dart';
import 'config_generator.dart';
import 'core_generator.dart';
import 'doc_generator.dart';
import 'feature_generator.dart';
import 'localization_generator.dart';
import 'network_generator.dart';
import 'router_generator.dart';
import 'service_generator.dart';
import 'storage_generator.dart';
import 'test_generator.dart';
import 'theme_generator.dart';
import 'widget_generator.dart';

/// Orchestrates the generation of the entire Flutter project architecture.
///
/// Writes files into an existing Flutter project at [projectPath] according
/// to [config], reporting progress through [logger].
class ProjectGenerator {
  /// Creates a generator for the project at [projectPath].
  ProjectGenerator({
    required this.projectPath,
    required this.config,
    required this.logger,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  /// The CLI logger.
  final CliLogger logger;

  /// Whether the project at [projectPath] was already generated (the marker
  /// file `lib/.flutter_project_builder` exists).
  static bool isGenerated(String projectPath) =>
      FileUtils.fileExists(markerPath(projectPath));

  /// Path of the marker file written after a successful generation.
  static String markerPath(String projectPath) =>
      p.join(projectPath, 'lib', PackageConstants.generatedMarkerFile);

  /// Returns the dependencies required by the code generated for [config].
  static Map<String, String> dependenciesFor(ProjectConfig config) {
    const all = PackageConstants.generatedDependencies;
    return {
      for (final entry in all.entries)
        if (_isRequired(entry.key, config)) entry.key: entry.value,
    };
  }

  static bool _isRequired(String package, ProjectConfig config) =>
      switch (package) {
        'dio' => config.dio,
        'hive_ce' || 'hive_ce_flutter' => config.hive,
        'flutter_localizations' => config.localization,
        _ => true,
      };

  /// Generates the project architecture.
  ///
  /// Adds the required dependencies to `pubspec.yaml` (existing constraints
  /// are kept) and writes the generated files, overwriting files with the
  /// same path.
  ///
  /// If [upgradeMode] is true, it only regenerates `lib/core/` files and
  /// skips features, routing, entry points, localization and tests to avoid
  /// overwriting user logic.
  Future<void> generate({bool upgradeMode = false}) async {
    final steps = <String, Future<void> Function()>{
      'Updating dependencies...': () async {
        PubspecUtils.addDependencies(projectPath, dependenciesFor(config));
        PubspecUtils.addDependencies(
          projectPath,
          PackageConstants.generatedDevDependencies,
          isDev: true,
        );
      },
      'Generating Core infrastructure...': () async {
        await CoreGenerator(projectPath: projectPath, config: config)
            .generate();
        await ServiceGenerator(projectPath: projectPath, config: config)
            .generate();
        if (config.firebase) {
          FileUtils.createGitKeep(
            p.join(projectPath, 'lib', 'core', 'firebase'),
          );
        }
      },
      'Generating Theme...':
          ThemeGenerator(projectPath: projectPath, config: config).generate,
      'Generating UI Widgets...':
          WidgetGenerator(projectPath: projectPath, config: config).generate,
      if (config.dio)
        'Generating Network layer...':
            NetworkGenerator(projectPath: projectPath, config: config).generate,
      if (config.hive)
        'Generating Storage layer...':
            StorageGenerator(projectPath: projectPath, config: config).generate,
      if (!upgradeMode) ..._featureSteps(),
    };

    logger.startProgress(total: steps.length);
    for (final step in steps.entries) {
      logger.step(step.key);
      await step.value();
    }

    _writeMarker();
    logger.completeProgress();
  }

  Map<String, Future<void> Function()> _featureSteps() {
    final features = FeatureGenerator(
      projectPath: projectPath,
      config: config,
      logger: logger,
    );
    return {
      'Generating Router...':
          RouterGenerator(projectPath: projectPath, config: config).generate,
      if (config.localization)
        'Generating Localization...':
            LocalizationGenerator(projectPath: projectPath, config: config)
                .generate,
      config.sampleFeatures
          ? 'Generating Sample features...'
          : 'Generating Home page...': () async {
        await features.generateHome();
        if (config.sampleFeatures) {
          await features.generateCounterSample();
          await features.generateUsersSample();
        }
      },
      'Generating main files and config...':
          ConfigGenerator(projectPath: projectPath, config: config).generate,
      'Generating Test templates...':
          TestGenerator(projectPath: projectPath, config: config).generate,
      'Generating documentation...':
          DocGenerator(projectPath: projectPath, config: config).generate,
    };
  }

  void _writeMarker() {
    FileUtils.createFile(
      markerPath(projectPath),
      '# Generated by flutter_project_builder v${PackageConstants.version}\n',
    );
  }
}
