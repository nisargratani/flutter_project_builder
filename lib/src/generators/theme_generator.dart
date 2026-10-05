// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/theme/theme_template.dart';
import '../utils/file_utils.dart';

/// Scaffolds theme configuration.
class ThemeGenerator {
  ThemeGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final themePath = p.join(projectPath, 'lib', 'core', 'theme');

    FileUtils.createFile(
      p.join(themePath, 'app_theme.dart'),
      ThemeTemplate.appTheme,
    );
  }
}
