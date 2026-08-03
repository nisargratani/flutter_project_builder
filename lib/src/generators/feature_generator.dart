// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../cli/cli_logger.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';
import '../utils/string_utils.dart';

/// Scaffolds Clean Architecture features.
class FeatureGenerator {
  FeatureGenerator({
    required this.projectPath,
    required this.config,
    this.logger,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  /// The CLI logger.
  final CliLogger? logger;

  /// Scaffolds a new empty feature with Clean Architecture structure.
  Future<void> generateFeature(String name) async {
    final featureName = StringUtils.toSnakeCase(name);
    final basePath = p.join(projectPath, 'lib', 'features', featureName);

    // Data layer
    FileUtils.createGitKeep(p.join(basePath, 'data', 'datasource'));
    FileUtils.createGitKeep(p.join(basePath, 'data', 'models'));
    FileUtils.createGitKeep(p.join(basePath, 'data', 'repository'));

    // Domain layer
    FileUtils.createGitKeep(p.join(basePath, 'domain', 'entities'));
    FileUtils.createGitKeep(p.join(basePath, 'domain', 'repository'));
    FileUtils.createGitKeep(p.join(basePath, 'domain', 'usecases'));

    // Presentation layer
    FileUtils.createGitKeep(p.join(basePath, 'presentation', 'pages'));
    FileUtils.createGitKeep(p.join(basePath, 'presentation', 'widgets'));
    FileUtils.createGitKeep(p.join(basePath, 'presentation', 'providers'));
  }

  /// Generates the Counter sample feature.
  Future<void> generateCounterSample() async {
    // For now we just create the directory structure.
    // We will populate templates in a later phase.
    await generateFeature('counter');
  }

  /// Generates the Users sample feature.
  Future<void> generateUsersSample() async {
    // For now we just create the directory structure.
    // We will populate templates in a later phase.
    await generateFeature('users');
  }
}
