// ignore_for_file: public_member_api_docs

import 'package:path/path.dart' as p;

import '../config/project_config.dart';
import '../templates/config/config_template.dart';
import '../utils/file_utils.dart';
import '../utils/l10n_settings.dart';
import '../utils/pubspec_utils.dart';
import '../utils/string_utils.dart';

/// Scaffolds the app entry points (`app.dart`, `bootstrap.dart`,
/// `main.dart`, `main_<flavor>.dart`), the environment configuration
/// (`AppConfig`, `FlavorConfig`) and the Firebase bootstrap.
class ConfigGenerator {
  ConfigGenerator({
    required this.projectPath,
    required this.config,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  String get _libPath => p.join(projectPath, 'lib');

  /// Human-readable app name derived from the pubspec name.
  String get appName => StringUtils.toTitleCase(
        PubspecUtils.getProjectName(projectPath) ?? 'flutter_app',
      );

  Future<void> generate() async {
    FileUtils.createFile(
      p.join(_libPath, 'app.dart'),
      ConfigTemplate.app(
        localization: config.localization,
        // An existing l10n.yaml is kept, so follow it.
        l10n: config.localization
            ? L10nSettings.read(projectPath)
            : const L10nSettings(),
      ),
    );
    FileUtils.createFile(
      p.join(_libPath, 'bootstrap.dart'),
      ConfigTemplate.bootstrap(hive: config.hive, firebase: config.firebase),
    );
    FileUtils.createFile(
      p.join(_libPath, 'main.dart'),
      ConfigTemplate.main(flavors: config.hasFlavors),
    );
    generateEnvironment();

    if (config.hasFlavors) {
      for (final flavor in config.flavors) {
        FileUtils.createFile(
          p.join(_libPath, 'main_$flavor.dart'),
          ConfigTemplate.flavorMain(flavor),
        );
      }
    }

    if (config.firebase) {
      FileUtils.createFile(
        p.join(_libPath, 'core', 'firebase', 'firebase_initializer.dart'),
        ConfigTemplate.firebaseInitializer,
      );
      // `flutterfire configure` replaces this file; never overwrite it.
      FileUtils.createFileIfAbsent(
        p.join(_libPath, 'firebase_options.dart'),
        ConfigTemplate.firebaseOptionsPlaceholder,
      );
    }
  }

  /// Writes `lib/core/config/app_config.dart` (and `flavor_config.dart`).
  ///
  /// With [onlyIfMissing], existing files are kept: `upgrade` uses this so
  /// your base URLs survive while `lib/core` is refreshed.
  void generateEnvironment({bool onlyIfMissing = false}) {
    final dir = p.join(_libPath, 'core', 'config');
    final files = {
      p.join(dir, 'app_config.dart'): ConfigTemplate.appConfig(
        flavors: config.hasFlavors,
        appName: appName,
      ),
      if (config.hasFlavors)
        p.join(dir, 'flavor_config.dart'): ConfigTemplate.flavorConfig(
          config.flavors,
          appName: appName,
        ),
    };
    for (final MapEntry(key: path, value: content) in files.entries) {
      if (onlyIfMissing) {
        FileUtils.createFileIfAbsent(path, content);
      } else {
        FileUtils.createFile(path, content);
      }
    }
  }
}
