// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/services/service_template.dart';
import '../utils/file_utils.dart';

/// Scaffolds service stubs.
class ServiceGenerator {
  ServiceGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final servicePath = p.join(projectPath, 'lib', 'core', 'services');

    FileUtils.createFile(
      p.join(servicePath, 'connectivity_service.dart'),
      ServiceTemplate.connectivityService,
    );
  }
}
