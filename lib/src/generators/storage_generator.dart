// ignore_for_file: public_member_api_docs, require_trailing_commas, directives_ordering, cascade_invocations, lines_longer_than_80_chars

import 'package:path/path.dart' as p;

import '../templates/storage/storage_template.dart';
import '../config/project_config.dart';
import '../utils/file_utils.dart';

/// Scaffolds local storage layer using Hive CE.
class StorageGenerator {
  StorageGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final storagePath = p.join(projectPath, 'lib', 'core', 'storage');
    FileUtils.createGitKeep(storagePath);

    FileUtils.createFile(p.join(storagePath, 'storage_service.dart'),
        StorageTemplate.storageService);
    FileUtils.createFile(p.join(storagePath, 'hive_storage_service.dart'),
        StorageTemplate.hiveStorageService);
  }
}
