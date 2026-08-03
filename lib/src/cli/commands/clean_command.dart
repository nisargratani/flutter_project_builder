import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../utils/file_utils.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to clean generated architecture files.
class CleanCommand extends Command<int> {
  /// Creates a new [CleanCommand].
  CleanCommand({required CliLogger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force clean without prompting.',
      defaultsTo: false,
    );
  }

  @override
  String get name => 'clean';

  @override
  String get description => 'Remove generated architecture files.';

  final CliLogger _logger;

  @override
  Future<int> run() async {
    final currentDir = Directory.current.path;

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    final force = argResults?['force'] as bool? ?? false;

    if (!force && stdin.hasTerminal) {
      _logger.warning(
        'This will delete lib/core, lib/features, and other generated files.',
      );
      stdout.write('Are you sure you want to proceed? (y/N): ');
      final input = stdin.readLineSync()?.trim().toLowerCase();
      if (input != 'y') {
        _logger.info('Aborted.');
        return 0;
      }
    }

    _logger.startProgress(total: 4);

    try {
      _logger.step('Cleaning lib/core...');
      FileUtils.deleteDirectory(p.join(currentDir, 'lib', 'core'));

      _logger.step('Cleaning lib/features...');
      FileUtils.deleteDirectory(p.join(currentDir, 'lib', 'features'));

      _logger.step('Cleaning lib/router & lib/localization...');
      FileUtils.deleteDirectory(p.join(currentDir, 'lib', 'router'));
      FileUtils.deleteDirectory(p.join(currentDir, 'lib', 'localization'));

      _logger.step('Cleaning main entry points...');
      FileUtils.deleteFile(p.join(currentDir, 'lib', 'main_dev.dart'));
      FileUtils.deleteFile(p.join(currentDir, 'lib', 'main_stage.dart'));
      FileUtils.deleteFile(p.join(currentDir, 'lib', 'main_prod.dart'));

      _logger.completeProgress();
      return 0;
    } catch (e) {
      _logger.error('Clean failed: $e');
      return 1;
    }
  }
}
