// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../templates/network/network_template.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';

/// Scaffolds network layer using Dio.
class NetworkGenerator {
  NetworkGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final networkPath = p.join(projectPath, 'lib', 'core', 'network');
    FileUtils.createGitKeep(networkPath);

    FileUtils.createFile(
        p.join(networkPath, 'api_client.dart'), NetworkTemplate.apiClient);
    FileUtils.createFile(p.join(networkPath, 'api_interceptors.dart'),
        NetworkTemplate.apiInterceptors);
  }
}
