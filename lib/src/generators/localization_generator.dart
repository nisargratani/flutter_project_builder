// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/l10n/l10n_template.dart';
import '../utils/file_utils.dart';
import '../utils/pubspec_utils.dart';

/// Scaffolds `gen-l10n` localization: `l10n.yaml`, an English ARB file and
/// `flutter: generate: true` in `pubspec.yaml`.
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
    PubspecUtils.addLocalizationConfig(projectPath);
    // Never overwrite translations or a customised l10n setup.
    FileUtils.createFileIfAbsent(
      p.join(projectPath, 'l10n.yaml'),
      L10nTemplate.l10nYaml,
    );
    FileUtils.createFileIfAbsent(
      p.join(projectPath, 'lib', 'l10n', 'app_en.arb'),
      L10nTemplate.appEnArb,
    );
  }
}
