// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/widgets/widget_template.dart';
import '../utils/file_utils.dart';

/// Scaffolds reusable widgets.
class WidgetGenerator {
  WidgetGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  Future<void> generate() async {
    final widgetsPath = p.join(projectPath, 'lib', 'core', 'widgets');

    FileUtils.createFile(
      p.join(widgetsPath, 'app_button.dart'),
      WidgetTemplate.appButton,
    );
    FileUtils.createFile(
      p.join(widgetsPath, 'app_gap.dart'),
      WidgetTemplate.appGap,
    );
    FileUtils.createFile(
      p.join(widgetsPath, 'empty_widget.dart'),
      WidgetTemplate.emptyWidget,
    );
  }
}
