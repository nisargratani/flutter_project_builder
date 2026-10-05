// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/router/router_template.dart';
import '../utils/file_utils.dart';

/// Scaffolds routing layer using GoRouter.
class RouterGenerator {
  RouterGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final routerPath = p.join(projectPath, 'lib', 'router');

    FileUtils.createFile(
      p.join(routerPath, 'app_router.dart'),
      RouterTemplate.appRouter(samples: config.sampleFeatures),
    );
    FileUtils.createFile(
      p.join(routerPath, 'route_names.dart'),
      RouterTemplate.routeNames,
    );
    FileUtils.createFile(
      p.join(routerPath, 'navigation_logger.dart'),
      RouterTemplate.navigationLogger,
    );
  }
}
