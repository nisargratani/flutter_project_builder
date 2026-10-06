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

    test('--dry-run writes nothing, even when already generated', () async {
      final project = createProject();
      final before = readFile(project, 'pubspec.yaml');
      expect(await runCli(project, ['create', '--dry-run', '--flavors']), 0);
      expect(exists(project, 'lib'), isFalse);
      expect(exists(project, PackageConstants.configFileName), isFalse);
      expect(readFile(project, 'pubspec.yaml'), before);

      await runCli(project, ['create']);
      expect(await runCli(project, ['create', '--dry-run']), 0);
    });

    test('templates are presets that flags can override', () async {
      final basic = createProject();
      expect(await runCli(basic, ['create', '--template=basic']), 0);
      expect(exists(basic, 'lib/core/network'), isFalse);
      expect(exists(basic, 'lib/features/users'), isFalse);
      expect(exists(basic, 'l10n.yaml'), isFalse);

      final enterprise = createProject();
      expect(
        await runCli(enterprise, ['create', '-t', 'enterprise', '--no-hive']),
        0,
      );
      expect(exists(enterprise, 'lib/main_stage.dart'), isTrue);
      expect(exists(enterprise, 'lib/core/storage'), isFalse);
      final saved = ProjectConfig.fromDirectory(enterprise.path);
      expect(saved.template, 'enterprise');
      expect(saved.flavors, PackageConstants.defaultFlavors);
    });

    test('rejects an invalid --org', () async {
      final project = createProject();
      expect(await runCli(project, ['create', '--org=acme']), 1);
      expect(exists(project, 'lib'), isFalse);
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
    test('creates starter files in every layer and a route', () async {
      final project = createProject();
      await runCli(project, ['create', '--no-sample']);

      expect(
        await runCli(project, [
          'generate',
          'feature',
          'UserProfile',
          '--fields=id:int,title:String,score:double?',
        ]),
        0,
      );
      for (final path in [
        'domain/entities/user_profile_entity.dart',
        'domain/repository/user_profile_repository.dart',
        'data/models/user_profile_model.dart',
        'data/datasource/user_profile_remote_data_source.dart',
        'data/repository/user_profile_repository_impl.dart',
        'presentation/providers/user_profile_provider.dart',
        'presentation/pages/user_profile_page.dart',
        'domain/usecases/.gitkeep',
      ]) {
        expect(
          exists(project, 'lib/features/user_profile/$path'),
          isTrue,
          reason: path,
        );
      }
      expect(
        exists(
            project,
            'test/features/user_profile/'
            'user_profile_notifier_test.dart'),
        isTrue,
      );
      expect(
        readFile(
            project,
            'lib/features/user_profile/data/models/'
            'user_profile_model.dart'),
        contains("score: (json['score'] as num?)?.toDouble(),"),
      );
      final router = readFile(project, 'lib/router/app_router.dart');
      expect(router, contains('const UserProfilePage()'));
      expect(
        router,
        contains('user_profile/presentation/pages/user_profile_page.dart'),
      );
      expect(
        readFile(project, 'lib/router/route_names.dart'),
        contains("static const String userProfile = 'user-profile';"),
      );
    });

    test('--no-route and missing router produce files and a warning', () async {
      final project = createProject();
      expect(
        await runCli(project, ['generate', 'feature', 'auth', '--no-route']),
        0,
      );
      expect(exists(project, 'lib/router'), isFalse);
      expect(await runCli(project, ['generate', 'page', 'settings']), 0);
      expect(
        exists(
            project,
            'lib/features/settings/presentation/pages/'
            'settings_page.dart'),
        isTrue,
      );
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

  group('generate page/widget/provider/model', () {
    test('writes files in the expected places', () async {
      final project = createProject();
      await runCli(project, ['create', '--no-sample']);

      for (final args in [
        ['page', 'edit_profile', '--feature=profile'],
        ['widget', 'info_card'],
        ['widget', 'price_tag', '--feature=shop'],
        ['provider', 'cart'],
        ['provider', 'session', '--type=async', '--feature=profile'],
        ['model', 'address', '--fields=street:String,zip:int?'],
      ]) {
        expect(
          await runCli(project, ['generate', ...args]),
          0,
          reason: args.join(' '),
        );
      }
      for (final path in [
        'lib/features/profile/presentation/pages/edit_profile_page.dart',
        'test/features/profile/edit_profile_page_test.dart',
        'lib/core/widgets/info_card.dart',
        'test/core/widgets/info_card_test.dart',
        'lib/features/shop/presentation/widgets/price_tag.dart',
        'lib/features/cart/presentation/providers/cart_provider.dart',
        'lib/features/profile/presentation/providers/session_provider.dart',
        'lib/features/address/data/models/address_model.dart',
        'test/features/address/address_model_test.dart',
      ]) {
        expect(exists(project, path), isTrue, reason: path);
      }
      expect(
        readFile(
            project,
            'lib/features/profile/presentation/providers/'
            'session_provider.dart'),
        contains('extends AsyncNotifier<String>'),
      );
      expect(
        readFile(project, 'lib/router/route_names.dart'),
        contains("static const String editProfile = 'edit-profile';"),
      );
    });

    test('rejects clashing names and bad field specs', () async {
      final project = createProject();
      expect(await runCli(project, ['generate', 'widget', 'app']), 1);
      expect(await runCli(project, ['generate', 'page', 'home']), 1);
      expect(
        await runCli(project, ['generate', 'model', 'a', '--fields=x:Map']),
        1,
      );
      expect(
        await runCli(project, ['generate', 'provider', 'p', '--type=x']),
        1,
      );
      expect(exists(project, 'lib'), isFalse);
    });

    test('--dry-run writes nothing', () async {
      final project = createProject();
      expect(
        await runCli(project, ['generate', 'feature', 'auth', '--dry-run']),
        0,
      );
      expect(exists(project, 'lib'), isFalse);
      expect(exists(project, 'test'), isFalse);
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
