import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/project_config.dart';
import '../../generators/project_generator.dart';
import '../../utils/file_utils.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';
import '../dry_run_report.dart';

/// Command to upgrade existing generated architecture.
///
/// Regenerates `lib/core/` (and adds missing dependencies) using the options
/// in `flutter_project_builder.yaml`. Features, routing, entry points and
/// tests are not touched.
class UpgradeCommand extends Command<int> {
  /// Creates a new [UpgradeCommand].
  UpgradeCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path) {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Upgrade without prompting, even if no generation marker '
            'exists.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'List the files that would be overwritten, without writing '
            'anything.',
        negatable: false,
      );
  }

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Regenerate lib/core with the latest templates.';

  final CliLogger _logger;
  final String Function() _workingDirectory;

  @override
  Future<int> run() async {
    final currentDir = _workingDirectory();

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    final force = argResults!.flag('force');
    final config = ProjectConfig.fromDirectory(currentDir);

    if (argResults!.flag('dry-run')) {
      final recorder = await FileUtils.dryRun(
        () => ProjectGenerator(
          projectPath: currentDir,
          config: config,
          logger: _logger,
        ).generate(upgradeMode: true),
      );
      printDryRun(_logger, recorder, currentDir);
      return 0;
    }

    if (!force) {
      if (!ProjectGenerator.isGenerated(currentDir)) {
        _logger
          ..error('No generated architecture found. '
              'Run `flutter_project_builder create` first.')
          ..info('Pass --force to generate lib/core anyway.');
        return 1;
      }
      if (!stdin.hasTerminal) {
        _logger.error(
          'Refusing to overwrite files without confirmation. '
          'Re-run with --force in non-interactive environments.',
        );
        return 1;
      }
      _logger.warning('This will overwrite existing files in lib/core.');
      stdout.write('Are you sure you want to proceed? (y/N): ');
      final input = stdin.readLineSync()?.trim().toLowerCase();
      if (input != 'y' && input != 'yes') {
        _logger.info('Aborted.');
        return 0;
      }
    }

    try {
      await ProjectGenerator(
        projectPath: currentDir,
        config: config,
        logger: _logger,
      ).generate(upgradeMode: true);

      _logger.success('Architecture upgraded successfully.');
      return 0;
    } catch (e, st) {
      _logger
        ..error('Upgrade failed: $e')
        ..trace(st.toString());
      return 1;
    }
  }
}
