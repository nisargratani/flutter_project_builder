// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../templates/config/config_template.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';

/// Scaffolds application configuration files (main, flavors).
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

    if (config.hasFlavors) {
      FileUtils.createFile(
          p.join(libPath, 'main_dev.dart'),
          ConfigTemplate.main.replaceFirst(
              'void main() {', 'import \'core/config/flavor_config.dart\';\n\nvoid main() {\n  FlavorConfig.flavor = Flavor.dev;'));
      FileUtils.createFile(
          p.join(libPath, 'main_stage.dart'),
          ConfigTemplate.main.replaceFirst(
              'void main() {', 'import \'core/config/flavor_config.dart\';\n\nvoid main() {\n  FlavorConfig.flavor = Flavor.stage;'));
      FileUtils.createFile(
          p.join(libPath, 'main_prod.dart'),
          ConfigTemplate.main.replaceFirst(
              'void main() {', 'import \'core/config/flavor_config.dart\';\n\nvoid main() {\n  FlavorConfig.flavor = Flavor.prod;'));
      FileUtils.createFile(
          p.join(libPath, 'core', 'config', 'flavor_config.dart'),
          ConfigTemplate.flavorConfig);
    } else {
      FileUtils.createFile(p.join(libPath, 'main.dart'), ConfigTemplate.main);
    }
  }
}
