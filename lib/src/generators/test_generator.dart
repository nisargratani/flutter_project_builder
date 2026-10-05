// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/tests/test_template.dart';
import '../utils/file_utils.dart';
import '../utils/pubspec_utils.dart';

/// Scaffolds unit and widget tests for the generated code.
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
    // Imports must use the pubspec package name, which can differ from the
    // directory name.
    final package =
        PubspecUtils.getProjectName(projectPath) ?? p.basename(projectPath);

    final files = {
      'widget_test.dart': TestTemplate.appTest(
        package,
        samples: config.sampleFeatures,
      ),
      p.join('core', 'widgets', 'app_button_test.dart'):
          TestTemplate.appButtonTest(package),
      p.join('core', 'utils', 'validators_test.dart'):
          TestTemplate.validatorsTest(package),
      if (config.sampleFeatures) ...{
        p.join('features', 'counter', 'counter_notifier_test.dart'):
            TestTemplate.counterTest(package),
        p.join('features', 'users', 'users_notifier_test.dart'):
            TestTemplate.usersTest(package),
      },
    };
    for (final entry in files.entries) {
      FileUtils.createFile(p.join(testPath, entry.key), entry.value);
    }
  }
}
