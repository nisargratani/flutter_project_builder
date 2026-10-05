// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/config/config_template.dart';
import '../utils/file_utils.dart';

/// Scaffolds the app entry points (`app.dart`, `bootstrap.dart`,
/// `main.dart`, `main_<flavor>.dart`) and the flavor configuration.
class ConfigGenerator {
  ConfigGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final libPath = p.join(projectPath, 'lib');

    FileUtils.createFile(
      p.join(libPath, 'app.dart'),
      ConfigTemplate.app(localization: config.localization),
    );
    FileUtils.createFile(
      p.join(libPath, 'bootstrap.dart'),
      ConfigTemplate.bootstrap(hive: config.hive),
    );
    FileUtils.createFile(p.join(libPath, 'main.dart'), ConfigTemplate.main);

    if (!config.hasFlavors) return;

    FileUtils.createFile(
      p.join(libPath, 'core', 'config', 'flavor_config.dart'),
      ConfigTemplate.flavorConfig(config.flavors),
    );
    for (final flavor in config.flavors) {
      FileUtils.createFile(
        p.join(libPath, 'main_$flavor.dart'),
        ConfigTemplate.flavorMain(flavor),
      );
    }
  }
}
