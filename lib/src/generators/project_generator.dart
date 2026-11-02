import 'package:path/path.dart' as p;

import '../cli/cli_logger.dart';
import '../config/constants.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';
import '../utils/native_project.dart';
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

  /// Problems found while generating that need manual follow-up (for
  /// example a native file that could not be edited).
  final List<String> warnings = [];

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
        'firebase_core' => config.firebase,
        _ => true,
      };

  /// Generates the project architecture.
  ///
  /// Adds the required dependencies to `pubspec.yaml` (existing constraints
  /// are kept) and writes the generated files, overwriting files with the
  /// same path.
  ///
  /// When the organization is customised or native flavors are enabled,
  /// the Android, iOS, macOS, Linux and Windows projects are edited too (see
  /// `NativeProject`). Inside `FileUtils.dryRun` nothing is written.
  ///
  /// If [upgradeMode] is true, it only regenerates `lib/core/` files and
  /// skips features, routing, entry points, native projects, localization
  /// and tests to avoid overwriting user logic.
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
        if (upgradeMode) {
          // Keep your URLs; only add the files if they are missing.
          ConfigGenerator(projectPath: projectPath, config: config)
              .generateEnvironment(onlyIfMissing: true);
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
      if (needsNativeConfiguration)
        'Configuring native projects...': configureNative,
      'Generating Test templates...':
          TestGenerator(projectPath: projectPath, config: config).generate,
      'Generating documentation...':
          DocGenerator(projectPath: projectPath, config: config).generate,
    };
  }

  /// Whether [configureNative] has anything to do for [config].
  bool get needsNativeConfiguration =>
      config.hasCustomOrganization ||
      config.hasNativeFlavors ||
      config.firebase;

  /// Applies the organization, native flavors, deployment targets and
  /// `default-flavor` to the platform folders.
  ///
  /// Idempotent. Run it again after `flutter pub get`: Flutter only creates
  /// a Podfile at that point (when the project uses CocoaPods), and the
  /// flavor configurations must then be mapped in it.
  Future<void> configureNative() async {
    final native = NativeProject(
      projectPath: projectPath,
      packageName:
          PubspecUtils.getProjectName(projectPath) ?? p.basename(projectPath),
    );
    if (config.hasCustomOrganization) {
      warnings.addAll(native.applyOrganization(config.organization).warnings);
    }
    if (config.firebase) {
      // firebase_core 4.x requires iOS 15 and macOS 10.15.
      warnings.addAll(
        native.raiseDeploymentTargets(ios: '15.0', macos: '10.15').warnings,
      );
    }
    if (config.hasNativeFlavors) {
      warnings.addAll(native.configureFlavors(config.flavors).warnings);
      // Plain `flutter run` (without --flavor) uses the first flavor.
      PubspecUtils.setFlutterOption(
        projectPath,
        'default-flavor',
        config.flavors.first,
      );
    }
  }

  void _writeMarker() {
    FileUtils.createFile(
      markerPath(projectPath),
      '# Generated by flutter_project_builder v${PackageConstants.version}\n',
    );
  }
}
