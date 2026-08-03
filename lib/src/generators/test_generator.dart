// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../templates/tests/test_template.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';

/// Scaffolds unit and widget test files.
class TestGenerator {
  TestGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final testPath = p.join(projectPath, 'test');
    FileUtils.createGitKeep(testPath);

    FileUtils.createFile(
        p.join(testPath, 'widget_test.dart'),
        TestTemplate.widgetTest.replaceAll('app_name', p.basename(projectPath)));
  }
}
