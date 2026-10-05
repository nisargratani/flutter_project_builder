import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('global', () {
    test('--version and no command succeed', () async {
      final project = createProject();
      expect(await runCli(project, ['--version']), 0);
      expect(await runCli(project, []), 0);
    });

    test('unknown options are usage errors', () async {
      final project = createProject();
      expect(await runCli(project, ['create', '--bogus']), 1);
      expect(await runCli(project, ['nope']), 1);
    });

    test('commands refuse to run outside a Flutter project', () async {
      final project = createProject(pubspec: 'name: cli\n');
      for (final args in [
        ['create'],
        ['upgrade', '--force'],
        ['clean', '--force'],
        ['generate', 'feature', 'auth'],
      ]) {
        expect(await runCli(project, args), 1, reason: args.join(' '));
      }
      expect(exists(project, 'lib'), isFalse);
    });
  });

  group('create', () {
    test('uses flags and saves the effective configuration', () async {
      final project = createProject();
      final code = await runCli(project, [
        'create',
        '--no-interactive',
        '--flavors',
        '--no-dio',
        '--org=io.acme',
      ]);

      expect(code, 0);
      expect(exists(project, 'lib/main_stage.dart'), isTrue);
      expect(exists(project, 'lib/core/network'), isFalse);
      final saved = ProjectConfig.fromDirectory(project.path);
      expect(saved.organization, 'io.acme');
      expect(saved.flavors, PackageConstants.defaultFlavors);
      expect(saved.dio, isFalse);
    });

    test('honours flutter_project_builder.yaml and lets flags override it',
        () async {
      final project = createProject();
      final configFile =
          File(p.join(project.path, PackageConstants.configFileName))
            ..writeAsStringSync(
              'flavors: [dev, qa]\nsample_features: false\nhive: false\n',
            );

      expect(await runCli(project, ['create', '--hive']), 0);

      expect(exists(project, 'lib/main_qa.dart'), isTrue);
      expect(exists(project, 'lib/features/counter'), isFalse);
      expect(exists(project, 'lib/core/storage'), isTrue, reason: '--hive');
      expect(
        configFile.readAsStringSync(),
        contains('hive: false'),
        reason: 'an existing config file is never rewritten',
      );
    });

    test('reports an invalid config file instead of crashing', () async {
      final project = createProject();
      File(p.join(project.path, PackageConstants.configFileName))
          .writeAsStringSync('template: huge\n');
      expect(await runCli(project, ['create']), 1);
      expect(exists(project, 'lib/core'), isFalse);
    });

    test('refuses to run twice unless --force', () async {
      final project = createProject();
      expect(await runCli(project, ['create']), 0);
      final router = File(p.join(project.path, 'lib/router/app_router.dart'))
        ..writeAsStringSync('// my routes');

      expect(await runCli(project, ['create']), 1);
      expect(router.readAsStringSync(), '// my routes');

      expect(await runCli(project, ['create', '--force']), 0);
      expect(router.readAsStringSync(), contains('GoRouter'));
    });
  });

  group('generate feature', () {
    test('creates the layer folders using snake_case', () async {
      final project = createProject();
      expect(await runCli(project, ['generate', 'feature', 'UserProfile']), 0);
      for (final layer in [
        'data/datasource',
        'domain/usecases',
        'presentation/pages',
      ]) {
        expect(
          exists(project, 'lib/features/user_profile/$layer/.gitkeep'),
          isTrue,
        );
      }
    });

    test('is idempotent and keeps existing files', () async {
      final project = createProject();
      await runCli(project, ['generate', 'feature', 'auth']);
      final page = File(
        p.join(project.path, 'lib/features/auth/presentation/pages/a.dart'),
      )..writeAsStringSync('// page');
      expect(await runCli(project, ['generate', 'feature', 'auth']), 0);
      expect(page.readAsStringSync(), '// page');
    });

    test('rejects invalid names, reserved words and path traversal', () async {
      final project = createProject();
      for (final name in ['../../escape', 'class', '1st', '_x', 'a/b']) {
        expect(
          await runCli(project, ['generate', 'feature', name]),
          1,
          reason: name,
        );
      }
      expect(await runCli(project, ['generate', 'feature']), 1);
      expect(await runCli(project, ['generate', 'feature', 'a', 'b']), 1);
      expect(exists(project, 'lib'), isFalse);
      expect(exists(project, 'escape'), isFalse);
      expect(exists(project, '../escape'), isFalse);
    });
  });

  group('init', () {
    test('writes a parseable config once', () async {
      final project = createProject();
      expect(await runCli(project, ['init']), 0);
      expect(
        ProjectConfig.fromDirectory(project.path).template,
        PackageConstants.defaultTemplate,
      );
      expect(await runCli(project, ['init']), 1);
    });
  });

  group('upgrade', () {
    test('requires a generated project unless --force', () async {
      final project = createProject();
      expect(await runCli(project, ['upgrade']), 1);
      expect(exists(project, 'lib/core'), isFalse);
      expect(await runCli(project, ['upgrade', '--force']), 0);
      expect(exists(project, 'lib/core/utils/validators.dart'), isTrue);
      expect(exists(project, 'lib/router'), isFalse);
    });

    test('uses the saved configuration', () async {
      final project = createProject();
      await runCli(project, ['create', '--no-dio']);
      expect(await runCli(project, ['upgrade', '-f']), 0);
      expect(exists(project, 'lib/core/network'), isFalse);
    });
  });

  group('clean', () {
    test('requires a generated project unless --force', () async {
      final project = createProject();
      Directory(p.join(project.path, 'lib/core')).createSync(recursive: true);
      expect(await runCli(project, ['clean']), 1);
      expect(exists(project, 'lib/core'), isTrue);
    });

    test('removes generated files but keeps user tests and translations',
        () async {
      final project = createProject();
      await runCli(project, ['create', '--flavors']);
      File(p.join(project.path, 'test/my_test.dart'))
          .writeAsStringSync('void main() {}');

      expect(await runCli(project, ['clean', '--force']), 0);

      for (final path in [
        'lib/core',
        'lib/features',
        'lib/router',
        'lib/app.dart',
        'lib/bootstrap.dart',
        'lib/main_dev.dart',
        'lib/${PackageConstants.generatedMarkerFile}',
        'test/widget_test.dart',
        'test/core',
      ]) {
        expect(exists(project, path), isFalse, reason: path);
      }
      expect(exists(project, 'test/my_test.dart'), isTrue);
      expect(exists(project, 'lib/l10n/app_en.arb'), isTrue);
      expect(exists(project, 'pubspec.yaml'), isTrue);
    });
  });
}
