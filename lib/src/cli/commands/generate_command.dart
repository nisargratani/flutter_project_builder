// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/project_config.dart';
import '../../generators/feature_generator.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to scaffold a new feature.
class GenerateCommand extends Command<int> {
  /// Creates a new [GenerateCommand].
  GenerateCommand({required CliLogger logger}) {
    addSubcommand(GenerateFeatureCommand(logger: logger));
  }

  @override
  String get name => 'generate';

  @override
  String get description => 'Generate new components (features, etc.).';
}

/// Subcommand to generate a feature.
class GenerateFeatureCommand extends Command<int> {
  /// Creates a new [GenerateFeatureCommand].
  GenerateFeatureCommand({required CliLogger logger}) : _logger = logger;

  @override
  String get name => 'feature';

  @override
  String get description => 'Generate a Clean Architecture feature.';

  final CliLogger _logger;

  @override
  Future<int> run() async {
    final args = argResults?.rest ?? [];
    if (args.isEmpty) {
      _logger.error('Please provide a feature name.');
      _logger.info('Usage: flutter_project_builder generate feature <name>');
      return 1;
    }

    final featureName = args.first;
    final currentDir = Directory.current.path;

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    final config = ProjectConfig.fromDirectory(currentDir);

    try {
      final generator = FeatureGenerator(
        projectPath: currentDir,
        config: config,
        logger: _logger,
      );

      await generator.generateFeature(featureName);

      _logger.success('Feature $featureName generated successfully.');
      return 0;
    } catch (e, st) {
      _logger.error('Feature generation failed: $e');
      _logger.detail(st.toString());
      return 1;
    }
  }
}
