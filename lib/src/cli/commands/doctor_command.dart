// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/constants.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to check environment health.
class DoctorCommand extends Command<int> {
  /// Creates a new [DoctorCommand].
  DoctorCommand({required CliLogger logger}) : _logger = logger;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check environment health and versions.';

  final CliLogger _logger;

  @override
  Future<int> run() async {
    _logger.header('flutter_project_builder doctor');

    _logger.info('Package Version: ${PackageConstants.version}');

    final currentDir = Directory.current.path;
    if (PubspecUtils.isFlutterProject(currentDir)) {
      _logger.success('Valid Flutter project detected.');
    } else {
      _logger.warning('Not inside a valid Flutter project.');
    }

    await _checkCommand('flutter', ['--version']);
    await _checkCommand('dart', ['--version']);
    await _checkCommand('git', ['--version']);

    _logger.newLine();
    return 0;
  }

  Future<void> _checkCommand(String executable, List<String> args) async {
    try {
      final result = await Process.run(executable, args);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().split('\n').first.trim();
        _logger.success('$executable: $output');
      } else {
        _logger.error('$executable not found or returned error.');
      }
    } catch (e) {
      _logger.error('$executable not found in PATH.');
    }
  }
}
