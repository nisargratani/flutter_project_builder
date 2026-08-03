// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../templates/docs/doc_template.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';

/// Scaffolds documentation files (README, Architecture).
class DocGenerator {
  DocGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    FileUtils.createFile(p.join(projectPath, 'README.md'), DocTemplate.readme);
  }
}
