// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/project_config.dart';
import '../../generators/project_generator.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to upgrade existing generated architecture.
class UpgradeCommand extends Command<int> {
  /// Creates a new [UpgradeCommand].
  UpgradeCommand({required CliLogger logger}) : _logger = logger;

  @override
  String get name => 'upgrade';

  @override
  String get description =>
      'Upgrade architecture to the latest template version.';

  final CliLogger _logger;

  @override
  Future<int> run() async {
    final currentDir = Directory.current.path;

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    _logger.warning('This will overwrite existing core architecture files.');
    stdout.write('Are you sure you want to proceed? (y/N): ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input != 'y') {
      _logger.info('Aborted.');
      return 0;
    }

    final config = ProjectConfig.fromDirectory(currentDir);

    try {
      final generator = ProjectGenerator(
        projectPath: currentDir,
        config: config,
        logger: _logger,
      );

      // Only regenerate core files, not features or config files
      await generator.generate(upgradeMode: true);

      _logger.success('Architecture upgraded successfully.');
      return 0;
    } catch (e, st) {
      _logger.error('Upgrade failed: $e');
      _logger.detail(st.toString());
      return 1;
    }
  }
}
