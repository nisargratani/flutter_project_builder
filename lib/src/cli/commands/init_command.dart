import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/constants.dart';
import '../../config/project_config.dart';
import '../../utils/file_utils.dart';
import '../cli_logger.dart';

/// Command to initialize configuration file.
class InitCommand extends Command<int> {
  /// Creates a new [InitCommand].
  InitCommand({required CliLogger logger}) : _logger = logger;

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize flutter_project_builder.yaml configuration file.';

  final CliLogger _logger;

  @override
  Future<int> run() async {
    final currentDir = Directory.current.path;
    final configPath = p.join(currentDir, PackageConstants.configFileName);

    if (FileUtils.fileExists(configPath)) {
      _logger.warning('${PackageConstants.configFileName} already exists.');
      return 1;
    }

    const config = ProjectConfig();
    FileUtils.createFile(configPath, config.toYaml());

    _logger.success('Created ${PackageConstants.configFileName}');
    return 0;
  }
}
