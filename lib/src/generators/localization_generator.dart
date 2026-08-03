// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../utils/file_utils.dart';

/// Scaffolds localization configuration.
class LocalizationGenerator {
  LocalizationGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final l10nPath = p.join(projectPath, 'lib', 'l10n');
    FileUtils.createGitKeep(l10nPath);
    // Will be populated with templates in Phase 6
  }
}
