import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/constants.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to check environment health.
///
/// Exits with code 1 if `flutter` or `dart` cannot be run. `git` is
/// optional and only produces a warning.
class DoctorCommand extends Command<int> {
  /// Creates a new [DoctorCommand].
  DoctorCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path);

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check environment health and versions.';

  final CliLogger _logger;
  final String Function() _workingDirectory;

  @override
  Future<int> run() async {
    _logger
      ..header('flutter_project_builder doctor')
      ..info('Package Version: ${PackageConstants.version}');

    if (PubspecUtils.isFlutterProject(_workingDirectory())) {
      _logger.success('Valid Flutter project detected.');
    } else {
      _logger.warning('Not inside a valid Flutter project.');
    }

    final flutterOk = await _checkCommand('flutter');
    final dartOk = await _checkCommand('dart');
    await _checkCommand('git', required: false);

    _logger.newLine();
    return flutterOk && dartOk ? 0 : 1;
  }

  Future<bool> _checkCommand(String executable, {bool required = true}) async {
    try {
      // `flutter` is a batch script on Windows and needs a shell.
      final result = await Process.run(
        executable,
        ['--version'],
        runInShell: Platform.isWindows,
      );
      if (result.exitCode == 0) {
        // Older Dart SDKs print the version to stderr.
        final output = '${result.stdout}'.trim().isNotEmpty
            ? '${result.stdout}'
            : '${result.stderr}';
        _logger.success('$executable: ${output.split('\n').first.trim()}');
        return true;
      }
      _report(executable, 'returned exit code ${result.exitCode}', required);
    } on ProcessException {
      _report(executable, 'not found in PATH', required);
    }
    return false;
  }

  void _report(String executable, String problem, bool required) {
    if (required) {
      _logger.error('$executable $problem.');
    } else {
      _logger.warning('$executable $problem (optional).');
    }
  }
}
