import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'helpers.dart';

Future<void> generate(
  Directory project,
  ProjectConfig config, {
  bool upgradeMode = false,
}) =>
    ProjectGenerator(
      projectPath: project.path,
      config: config,
      logger: CliLogger(useColors: false),
    ).generate(upgradeMode: upgradeMode);

List<String> dartFiles(Directory project) => Directory(project.path)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => p.relative(f.path, from: project.path))
    .where((path) => path.endsWith('.dart'))
    .toList();

void main() {
  test('default config generates a complete, wired project', () async {
    final project = createProject();
    await generate(project, const ProjectConfig());

    for (final path in [
      'lib/app.dart',
      'lib/bootstrap.dart',
      'lib/main.dart',
      'lib/router/app_router.dart',
      'lib/features/home/presentation/pages/home_page.dart',
      'lib/features/counter/presentation/pages/counter_page.dart',
      'lib/features/users/presentation/pages/users_page.dart',
      'lib/core/network/api_client.dart',
      'lib/core/storage/hive_storage_service.dart',
      'lib/l10n/app_en.arb',
      'l10n.yaml',
      'ARCHITECTURE.md',
      'test/widget_test.dart',
      'test/features/users/users_notifier_test.dart',
      'lib/${PackageConstants.generatedMarkerFile}',
    ]) {
      expect(exists(project, path), isTrue, reason: path);
    }
    expect(ProjectGenerator.isGenerated(project.path), isTrue);
    expect(readFile(project, 'lib/bootstrap.dart'), contains('storage.init()'));
    expect(
      readFile(project, 'lib/app.dart'),
      contains('AppLocalizations.localizationsDelegates'),
    );
    expect(exists(project, 'lib/core/firebase'), isFalse);
  });

  test('regression: generated regexes keep their backslashes', () async {
    final project = createProject();
    await generate(project, const ProjectConfig());
    const emailPattern = r"RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$')";
    expect(
      readFile(project, 'lib/core/utils/validators.dart'),
      contains(emailPattern),
    );
    expect(
      readFile(project, 'lib/core/extensions/string_extensions.dart'),
      contains(emailPattern),
    );
  });

  test('regression: no Dart file contains unresolved template markers',
      () async {
    final project = createProject();
    await generate(project, const ProjectConfig(flavors: ['dev', 'prod']));
    for (final path in dartFiles(project)) {
      final content = readFile(project, path);
      expect(content, isNot(contains(r'\$')), reason: path);
      expect(content, isNot(contains('app_name')), reason: path);
    }
  });

  test('regression: tests import the pubspec name, not the directory name',
      () async {
    final project = createProject(dirName: 'Some Folder');
    await generate(project, const ProjectConfig());
    final test = readFile(project, 'test/core/widgets/app_button_test.dart');
    expect(test, contains('package:my_app/core/widgets/app_button.dart'));
  });

  test('adds only the dependencies required by the config', () async {
    final project = createProject();
    await generate(
      project,
      const ProjectConfig(dio: false, hive: false, localization: false),
    );
    final deps = (loadYaml(readFile(project, 'pubspec.yaml'))
        as YamlMap)['dependencies'] as YamlMap;
    expect(deps.keys, containsAll(['flutter_riverpod', 'go_router', 'intl']));
    expect(deps.keys, isNot(contains('dio')));
    expect(deps.keys, isNot(contains('hive_ce')));
    expect(deps.keys, isNot(contains('flutter_localizations')));
    expect(exists(project, 'lib/core/network'), isFalse);
    expect(exists(project, 'lib/core/storage'), isFalse);
    expect(exists(project, 'l10n.yaml'), isFalse);
    expect(readFile(project, 'lib/bootstrap.dart'), isNot(contains('Hive')));
    expect(
      readFile(project, 'lib/core/exceptions/error_mapper.dart'),
      isNot(contains('dio')),
    );
    expect(
      readFile(
        project,
        'lib/features/users/data/datasource/user_remote_data_source.dart',
      ),
      isNot(contains('Dio')),
    );
  });

  test('custom flavors produce matching entry points', () async {
    final project = createProject();
    await generate(project, const ProjectConfig(flavors: ['dev', 'qa']));
    expect(readFile(project, 'lib/main_qa.dart'), contains('Flavor.qa'));
    expect(exists(project, 'lib/main_stage.dart'), isFalse);
    final flavorConfig =
        readFile(project, 'lib/core/config/flavor_config.dart');
    expect(flavorConfig, contains('enum Flavor { dev, qa }'));
    expect(flavorConfig, contains('static Flavor flavor = Flavor.dev;'));
  });

  test('without samples, no sample code or routes are generated', () async {
    final project = createProject();
    await generate(project, const ProjectConfig(sampleFeatures: false));
    expect(exists(project, 'lib/features/counter'), isFalse);
    expect(exists(project, 'test/features'), isFalse);
    expect(
      readFile(project, 'lib/router/app_router.dart'),
      isNot(contains('CounterPage')),
    );
  });

  test('firebase option adds firebase_core and initialises it', () async {
    final project = createProject();
    final options = File(p.join(project.path, 'lib', 'firebase_options.dart'));
    await generate(project, const ProjectConfig(firebase: true));

    expect(readFile(project, 'pubspec.yaml'), contains('firebase_core:'));
    expect(
      readFile(project, 'lib/bootstrap.dart'),
      contains('await FirebaseInitializer.initialize();'),
    );
    expect(options.readAsStringSync(), contains('flutterfire configure'));

    // A real `flutterfire configure` output is never overwritten.
    options.writeAsStringSync('// real options');
    await generate(project, const ProjectConfig(firebase: true));
    expect(options.readAsStringSync(), '// real options');
  });

  test('environment config: per-flavor values, kept on upgrade', () async {
    final project = createProject();
    await generate(project, const ProjectConfig(flavors: ['dev', 'prod']));

    final flavorConfig =
        readFile(project, 'lib/core/config/flavor_config.dart');
    expect(flavorConfig, contains("baseUrl: 'https://dev.api.example.com/'"));
    expect(flavorConfig, contains("baseUrl: 'https://api.example.com/'"));
    expect(flavorConfig, contains("appName: 'My App Dev'"));
    expect(
      readFile(project, 'lib/core/network/api_client.dart'),
      contains('baseUrl: config.baseUrl'),
    );
    expect(readFile(project, 'lib/main.dart'), contains('appFlavor'));

    final file = File(
      p.join(project.path, 'lib', 'core', 'config', 'flavor_config.dart'),
    )..writeAsStringSync('// my urls');
    await generate(
      project,
      const ProjectConfig(flavors: ['dev', 'prod']),
      upgradeMode: true,
    );
    expect(file.readAsStringSync(), '// my urls');
  });

  test('dark theme uses AppColors', () async {
    final project = createProject();
    await generate(project, const ProjectConfig());
    final theme = readFile(project, 'lib/core/theme/app_theme.dart');
    expect(theme, contains('primary: AppColors.primaryDark'));
    expect(theme, contains('background: AppColors.backgroundDark'));
  });

  test('native step only runs with a custom org or native flavors', () async {
    final project = createProject();
    final generator = ProjectGenerator(
      projectPath: project.path,
      config: const ProjectConfig(flavors: ['dev']),
      logger: CliLogger(useColors: false),
    );
    await generator.generate();
    expect(
      readFile(project, 'pubspec.yaml'),
      contains('default-flavor: dev'),
    );
    expect(generator.warnings, isEmpty, reason: 'no platform folders');

    final dartOnly = createProject();
    await generate(
      dartOnly,
      const ProjectConfig(flavors: ['dev'], nativeFlavors: false),
    );
    expect(
      readFile(dartOnly, 'pubspec.yaml'),
      isNot(contains('default-flavor')),
    );
  });

  test('does not overwrite translations or existing ARCHITECTURE.md', () async {
    final project = createProject();
    File(p.join(project.path, 'ARCHITECTURE.md')).writeAsStringSync('mine');
    File(p.join(project.path, 'lib', 'l10n', 'app_en.arb'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{"@@locale": "en", "hello": "Hi"}');

    await generate(project, const ProjectConfig());

    expect(readFile(project, 'ARCHITECTURE.md'), 'mine');
    expect(readFile(project, 'lib/l10n/app_en.arb'), contains('"hello"'));
  });

  test('upgrade mode only rewrites core files', () async {
    final project = createProject();
    await generate(project, const ProjectConfig());
    final router = File(p.join(project.path, 'lib/router/app_router.dart'))
      ..writeAsStringSync('// custom router');
    final validators =
        File(p.join(project.path, 'lib/core/utils/validators.dart'))
          ..writeAsStringSync('// stale');

    await generate(project, const ProjectConfig(), upgradeMode: true);

    expect(router.readAsStringSync(), '// custom router');
    expect(validators.readAsStringSync(), contains('class Validators'));
  });

  test('dependenciesFor selects packages by option', () {
    final all =
        ProjectGenerator.dependenciesFor(const ProjectConfig(firebase: true));
    expect(all.keys, containsAll(PackageConstants.generatedDependencies.keys));
    expect(
      ProjectGenerator.dependenciesFor(const ProjectConfig()).keys,
      isNot(contains('firebase_core')),
    );
    final minimal = ProjectGenerator.dependenciesFor(
      const ProjectConfig(dio: false, hive: false, localization: false),
    );
    expect(minimal.keys, isNot(contains('hive_ce_flutter')));
  });
}
