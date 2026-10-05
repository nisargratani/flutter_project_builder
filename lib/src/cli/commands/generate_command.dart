import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/project_config.dart';
import '../../generators/feature_generator.dart';
import '../../utils/file_utils.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to scaffold a new feature.
class GenerateCommand extends Command<int> {
  /// Creates a new [GenerateCommand].
  GenerateCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  }) {
    addSubcommand(
      GenerateFeatureCommand(
        logger: logger,
        workingDirectory: workingDirectory,
      ),
    );
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate new components (features, etc.).';
}

/// Subcommand to generate a feature.
///
/// Creates `lib/features/<name>/{data,domain,presentation}/...` folders.
/// The name is converted to snake_case (`UserProfile` → `user_profile`).
class GenerateFeatureCommand extends Command<int> {
  /// Creates a new [GenerateFeatureCommand].
  GenerateFeatureCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path);

  @override
  String get name => 'feature';

  @override
  String get description => 'Generate a Clean Architecture feature.';

  @override
  String get invocation => 'flutter_project_builder generate feature <name>';

  final CliLogger _logger;
  final String Function() _workingDirectory;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      _logger
        ..error('Please provide a feature name.')
        ..info('Usage: $invocation');
      return 1;
    }
    if (args.length > 1) {
      _logger.error(
        'Expected a single feature name but got ${args.length}: '
        '${args.join(' ')}. Use snake_case for multi-word names.',
      );
      return 1;
    }

    final currentDir = _workingDirectory();
    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    final String featureName;
    try {
      featureName = FeatureGenerator.normalizeName(args.single);
    } on FormatException catch (e) {
      _logger.error(e.message);
      return 1;
    }

    final generator = FeatureGenerator(
      projectPath: currentDir,
      config: ProjectConfig.fromDirectory(currentDir),
      logger: _logger,
    );
    final existed =
        FileUtils.directoryExists(generator.featurePath(featureName));

    try {
      await generator.generateFeature(featureName);
    } on FileSystemException catch (e) {
      _logger.error('Feature generation failed: ${e.message} (${e.path})');
      return 1;
    }

    final location = p.join('lib', 'features', featureName);
    if (existed) {
      _logger.info('Feature $featureName already exists in $location; '
          'missing folders were added.');
    } else {
      _logger.success('Feature $featureName generated in $location.');
    }
    return 0;
  }
}
