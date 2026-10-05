// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/docs/doc_template.dart';
import '../utils/file_utils.dart';

/// Writes `ARCHITECTURE.md` (only if it does not exist yet).
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
    FileUtils.createFileIfAbsent(
      p.join(projectPath, 'ARCHITECTURE.md'),
      DocTemplate.architecture,
    );
  }
}
