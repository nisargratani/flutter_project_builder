// Regression tests for the issues reported against 0.0.1 (FPB-01 to FPB-16).
import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:flutter_project_builder/src/cli/commands/upgrade_command.dart';
import 'package:flutter_project_builder/src/generators/model_field.dart';
import 'package:flutter_project_builder/src/templates/code/code_template.dart';
import 'package:flutter_project_builder/src/templates/tests/test_template.dart';
import 'package:flutter_project_builder/src/utils/native_project.dart';
import 'package:flutter_project_builder/src/utils/pubspec_utils.dart';
import 'package:flutter_project_builder/src/utils/sdk_type_names.dart';
import 'package:flutter_project_builder/src/utils/string_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

const String marker = 'lib/${PackageConstants.generatedMarkerFile}';

/// A project like `flutter create` leaves it: counter app and its test.
Directory flutterCreatedProject() {
  final project = createProject();
  writeFile(project, 'lib/main.dart', '// counter app\n');
  writeFile(
    project,
    'test/widget_test.dart',
    FlutterCli.defaultWidgetTest('my_app'),
  );
  return project;
}

/// Records `dart`/`flutter` invocations made through [FlutterCli].
class RecordingRunner {
  final List<({String executable, List<String> args, String? cwd})> calls = [];

  Future<ProcessResult> call(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    calls.add((executable: executable, args: arguments, cwd: workingDirectory));
    return ProcessResult(0, 0, '', '');
  }

  /// The files passed to `dart format`.
  List<String> get formatted => [
        for (final call in calls)
          if (call.executable == 'dart' && call.args.first == 'format')
            ...call.args.skip(1),
      ];
}

void main() {
  group('FPB-01: create in an existing project', () {
    const userFiles = {
      'lib/app.dart': '// my app widget\n',
      'lib/core/theme/app_theme.dart': '// my theme\n',
      'lib/router/app_router.dart': '// my router\n',
      'lib/features/home/presentation/pages/home_page.dart': '// my home\n',
    };

    test('refuses to overwrite user files, lists them and writes nothing',
        () async {
      final project = flutterCreatedProject();
      userFiles.forEach((path, content) => writeFile(project, path, content));
      final before = snapshot(project);

      final run = await runCliCaptured(project, ['create']);

      expect(run.exitCode, 1, reason: '$run');
      expect(snapshot(project), before);
      for (final path in userFiles.keys) {
        expect(run.output, contains(path));
      }
      expect(run.output, contains('--force'));
      // Replaced by design: not reported as conflicts.
      expect(run.output, isNot(contains('lib/main.dart')));
      expect(run.output, isNot(contains('test/widget_test.dart')));
    });

    test('--force overwrites them', () async {
      final project = flutterCreatedProject();
      userFiles.forEach((path, content) => writeFile(project, path, content));
      expect(await runCli(project, ['create', '--force']), 0);
      expect(readFile(project, 'lib/app.dart'), contains('class MyApp'));
    });

    test('replaces the unmodified flutter create counter test', () async {
      final project = flutterCreatedProject();
      expect(await runCli(project, ['create']), 0);
      expect(
        readFile(project, 'test/widget_test.dart'),
        startsWith(TestTemplate.header),
      );
    });

    test('lists an edited test/widget_test.dart as a conflict', () async {
      final project = flutterCreatedProject();
      writeFile(
        project,
        'test/widget_test.dart',
        '${FlutterCli.defaultWidgetTest('my_app')}// my extra test\n',
      );
      final before = snapshot(project);

      final run = await runCliCaptured(project, ['create']);

      expect(run.exitCode, 1, reason: '$run');
      expect(run.output, contains('test/widget_test.dart'));
      expect(run.output, contains('counter test from `flutter create`'));
      expect(snapshot(project), before);
    });

    test('files with identical content are not conflicts', () async {
      final generated = flutterCreatedProject();
      expect(await runCli(generated, ['create', '--no-sample']), 0);

      final project = flutterCreatedProject();
      writeFile(
        project,
        'lib/core/theme/app_theme.dart',
        readFile(generated, 'lib/core/theme/app_theme.dart'),
      );
      expect(await runCli(project, ['create', '--no-sample']), 0);
    });

    test('recognises the flutter create counter test', () {
      final test = FlutterCli.defaultWidgetTest('shop');
      expect(FlutterCli.isDefaultWidgetTest(test, 'shop'), isTrue);
      expect(
        FlutterCli.isDefaultWidgetTest(test.replaceAll('\n', '\r\n'), 'shop'),
        isTrue,
        reason: 'CRLF checkout',
      );
      expect(
        FlutterCli.isDefaultWidgetTest(
          test.replaceFirst('const MyApp()', 'MyApp()'),
          'shop',
        ),
        isTrue,
        reason: 'older Flutter versions',
      );
      expect(FlutterCli.isDefaultWidgetTest(test, 'other_app'), isFalse);
      expect(
        FlutterCli.isDefaultWidgetTest('$test\n// mine\n', 'shop'),
        isFalse,
      );
    });
  });

  group('FPB-02: incompatible existing constraints', () {
    String pubspecWith(String dependencies) => flutterPubspec.replaceFirst(
          'dependencies:\n',
          'dependencies:\n$dependencies',
        );

    test('create keeps the constraint and warns how to fix it', () async {
      final project = createProject(
        pubspec: pubspecWith('  flutter_riverpod: ^2.6.1\n'),
      );

      final run = await runCliCaptured(project, ['create']);

      expect(run.exitCode, 0, reason: '$run');
      expect(readFile(project, 'pubspec.yaml'), contains('^2.6.1'));
      expect(run.output, contains('flutter_riverpod to ^2.6.1'));
      expect(run.output, contains('^3.0.0'));
      expect(
        run.output,
        contains('flutter pub add "flutter_riverpod:^3.0.0"'),
      );
    });

    test('upgrade warns too', () async {
      final project = createProject();
      await runCli(project, ['create']);
      writeFile(
        project,
        'pubspec.yaml',
        readFile(project, 'pubspec.yaml')
            .replaceFirst(RegExp('flutter_riverpod: .*'), 'go_router: ^14.0.0')
            .replaceFirst(RegExp(r'\n  go_router: \^17.*'), '')
            .replaceFirst('dependencies:\n', 'dependencies:\n'),
      );
      final run = await runCliCaptured(project, ['upgrade', '--force']);
      expect(run.exitCode, 0, reason: '$run');
      expect(run.output, contains('go_router to ^14.0.0'));
    });

    test('incompatibleConstraints checks only versioned hosted packages', () {
      final project = createProject(
        pubspec: '${pubspecWith('''
  flutter_riverpod: ^2.6.1
  go_router: ">=16.0.0 <18.0.0"
  dio:
    version: ^4.0.0
  hive_ce: any
  intl: ^0.19.0
  connectivity_plus:
    path: ../connectivity_plus
''')}\ndependency_overrides:\n  intl: 0.20.2\n',
      );
      expect(
        PubspecUtils.incompatibleConstraints(project.path, {
          'flutter_riverpod': '^3.0.0',
          'go_router': '^17.0.0',
          'dio': '^5.4.0',
          'hive_ce': '^2.6.0',
          'intl': '^0.20.0',
          'connectivity_plus': '^7.0.0',
          'flutter_localizations': 'sdk: flutter',
        }),
        {'flutter_riverpod': '^2.6.1', 'dio': '^4.0.0'},
      );
    });
  });

  group('FPB-03: clean', () {
    test('deletes only the generated files and lists the kept ones', () async {
      final project = flutterCreatedProject();
      const userFiles = {
        'lib/features/cart/cart_page.dart': '// my cart\n',
        'lib/core/api/my_client.dart': '// my client\n',
        'lib/router/guards.dart': '// my guards\n',
        'test/features/cart/cart_test.dart': '// my test\n',
      };
      userFiles.forEach((path, content) => writeFile(project, path, content));
      expect(await runCli(project, ['create', '--firebase']), 0);
      expect(await runCli(project, ['generate', 'feature', 'auth']), 0);
      // A file that looks generated but is not listed in the marker.
      writeFile(
        project,
        'test/copied_test.dart',
        '${TestTemplate.header}\n// copied by hand\n',
      );

      final run = await runCliCaptured(project, ['clean', '--force']);

      expect(run.exitCode, 0, reason: '$run');
      for (final path in userFiles.keys) {
        expect(exists(project, path), isTrue, reason: path);
        expect(run.output, contains(path));
      }
      for (final path in [
        'lib/core/theme',
        'lib/features/auth',
        'lib/features/home',
        'lib/app.dart',
        'test/widget_test.dart',
        'test/features/auth',
        marker,
      ]) {
        expect(exists(project, path), isFalse, reason: path);
      }
      for (final path in [
        'lib/main.dart',
        'lib/firebase_options.dart',
        'lib/l10n/app_en.arb',
        'test/copied_test.dart',
      ]) {
        expect(exists(project, path), isTrue, reason: path);
      }
    });

    test('the marker lists what create and generate wrote', () async {
      final project = createProject();
      await runCli(project, ['create', '--firebase', '--flavors']);
      await runCli(project, ['generate', 'widget', 'info_card']);

      final listed = ProjectGenerator.generatedFiles(project.path)!;
      expect(
        listed,
        containsAll([
          'lib/app.dart',
          'lib/main_dev.dart',
          'lib/core/theme/app_theme.dart',
          'test/widget_test.dart',
          'lib/core/widgets/info_card.dart',
          'test/core/widgets/info_card_test.dart',
        ]),
      );
      for (final kept in [
        'lib/main.dart',
        'lib/firebase_options.dart',
        'lib/l10n/app_en.arb',
        'pubspec.yaml',
        marker,
      ]) {
        expect(listed, isNot(contains(kept)), reason: kept);
      }
      expect(listed, orderedEquals([...listed]..sort()));
    });

    test('never deletes unsafe or user-owned paths from the marker', () async {
      final project = createProject();
      await runCli(project, ['create', '--no-sample']);
      final outside = File(p.join(project.parent.path, 'outside.txt'))
        ..writeAsStringSync('keep');
      writeFile(
        project,
        marker,
        '${readFile(project, marker)}../outside.txt\nlib/../../outside.txt\n'
        'pubspec.yaml\nlib/main.dart\n',
      );

      expect(await runCli(project, ['clean', '--force']), 0);

      expect(outside.existsSync(), isTrue);
      expect(exists(project, 'pubspec.yaml'), isTrue);
      expect(exists(project, 'lib/main.dart'), isTrue);
    });

    test('a 0.0.1 marker without a list: deletes nothing, exits 1', () async {
      final project = createProject();
      await runCli(project, ['create']);
      writeFile(
        project,
        marker,
        '# Generated by flutter_project_builder v0.0.1\n',
      );
      // generate and upgrade do not turn it into a partial list.
      await runCli(project, ['generate', 'widget', 'badge_count']);
      await runCli(project, ['upgrade', '--force']);
      expect(ProjectGenerator.generatedFiles(project.path), isNull);
      final before = snapshot(project);

      final run = await runCliCaptured(project, ['clean', '--force']);

      expect(run.exitCode, 1);
      expect(run.output, contains('Nothing was deleted'));
      expect(snapshot(project), before);
    });

    test('without a marker: exits 1 even with --force', () async {
      final project = createProject();
      writeFile(project, 'lib/core/mine.dart', '// mine\n');
      expect(await runCli(project, ['clean', '--force']), 1);
      expect(exists(project, 'lib/core/mine.dart'), isTrue);
    });
  });

  group('FPB-04: native flavors keep a customised app name', () {
    late Directory project;

    void rename({String? android, String? ios}) {
      if (android != null) {
        writeFile(
          project,
          'android/app/src/main/AndroidManifest.xml',
          readFile(project, 'android/app/src/main/AndroidManifest.xml')
              .replaceFirst(
            'android:label="my_app"',
            'android:label="$android"',
          ),
        );
      }
      if (ios != null) {
        writeFile(
          project,
          'ios/Runner/Info.plist',
          readFile(project, 'ios/Runner/Info.plist')
              .replaceFirst('<string>My App</string>', '<string>$ios</string>'),
        );
      }
    }

    NativeProject native() =>
        NativeProject(projectPath: project.path, packageName: 'my_app');

    setUp(() => project = nativeProject());

    test('on Android and iOS, also after the second native pass', () {
      rename(android: 'Shop Pro', ios: 'Shop Pro');
      native().configureFlavors(['dev', 'prod']);
      // `create` configures native projects again after `pub get`.
      native().configureFlavors(['dev', 'prod']);

      final gradle = readFile(project, 'android/app/build.gradle.kts');
      expect(gradle, contains('manifestPlaceholders["appName"] = "Shop Pro"'));
      expect(
        gradle,
        contains('manifestPlaceholders["appName"] = "Shop Pro Dev"'),
      );
      final pbxproj = readFile(project, 'ios/Runner.xcodeproj/project.pbxproj');
      expect(pbxproj, contains('APP_DISPLAY_NAME = "Shop Pro";'));
      expect(pbxproj, contains('APP_DISPLAY_NAME = "Shop Pro Dev";'));
      expect(pbxproj, isNot(contains('My App')));
      expect(native().iosAppName, 'Shop Pro');
    });

    test('each platform keeps its own name', () {
      rename(android: 'Shop &amp; Co');
      expect(native().androidAppName, 'Shop & Co');
      expect(native().iosAppName, 'My App');
    });

    test('package names and references are not custom names', () {
      expect(native().androidAppName, 'My App', reason: 'label = my_app');
      rename(android: '@string/app_name', ios: r'$(PRODUCT_NAME)');
      expect(native().androidAppName, 'My App');
      expect(native().iosAppName, 'My App');
    });

    test('a new flavor is named after the base name, not a flavor name', () {
      rename(ios: 'Shop Pro');
      native().configureFlavors(['dev', 'prod']);
      // Xcode sorts objects by ID when it saves, so a flavor configuration
      // can come before the base ones.
      const pbxPath = 'ios/Runner.xcodeproj/project.pbxproj';
      var pbxproj = readFile(project, pbxPath);
      final devConfig = RegExp(
        r'\t\t[0-9A-F]{24} /\* Debug-dev \*/ = \{\n.*?\n\t\t\};\n',
        dotAll: true,
      ).allMatches(pbxproj).firstWhere((m) => m[0]!.contains('Shop Pro Dev'));
      pbxproj = pbxproj.replaceFirst(devConfig[0]!, '').replaceFirst(
            '/* Begin XCBuildConfiguration section */\n',
            '/* Begin XCBuildConfiguration section */\n${devConfig[0]}',
          );
      writeFile(project, pbxPath, pbxproj);

      native().configureFlavors(['dev', 'prod', 'uat']);

      expect(
        readFile(project, pbxPath),
        contains('APP_DISPLAY_NAME = "Shop Pro Uat";'),
      );
    });
  });

  group('FPB-05: app.dart follows an existing l10n.yaml', () {
    test('Flutter docs setup: nullable getter, no appTitle', () async {
      final project = createProject();
      writeFile(
        project,
        'l10n.yaml',
        'arb-dir: lib/l10n\ntemplate-arb-file: app_en.arb\n'
            'output-localization-file: app_localizations.dart\n',
      );
      writeFile(project, 'lib/l10n/app_en.arb', '{"helloWorld": "Hello!"}');
      expect(await runCli(project, ['create']), 0);

      final app = readFile(project, 'lib/app.dart');
      expect(app, contains("import 'l10n/app_localizations.dart';"));
      expect(app, contains('AppLocalizations.localizationsDelegates'));
      expect(app, contains('title: ref.watch(appConfigProvider).appName'));
      expect(app, contains("import 'core/config/app_config.dart';"));
      expect(app, isNot(contains('appTitle')));
      expect(readFile(project, 'lib/l10n/app_en.arb'), contains('helloWorld'));
    });

    test('custom class, file and folder; nullable appTitle', () async {
      final project = createProject();
      writeFile(
        project,
        'l10n.yaml',
        'arb-dir: lib/i18n\ntemplate-arb-file: strings_en.arb\n'
            'output-localization-file: strings.dart\noutput-class: S\n',
      );
      writeFile(project, 'lib/i18n/strings_en.arb', '{"appTitle": "Shop"}');
      expect(await runCli(project, ['create']), 0);

      final app = readFile(project, 'lib/app.dart');
      expect(app, contains("import 'i18n/strings.dart';"));
      expect(
        app,
        contains('onGenerateTitle: (context) => S.of(context)!.appTitle'),
      );
      expect(app, contains('supportedLocales: S.supportedLocales'));
    });

    test('output outside lib/ is not imported', () async {
      final project = createProject();
      writeFile(project, 'l10n.yaml', 'output-dir: generated/l10n\n');
      expect(await runCli(project, ['create']), 0);
      final app = readFile(project, 'lib/app.dart');
      expect(app, isNot(contains('localizationsDelegates')));
      expect(app, contains('title: ref.watch(appConfigProvider).appName'));
    });

    test('the generated l10n setup is unchanged', () async {
      final project = createProject();
      expect(await runCli(project, ['create']), 0);
      expect(
        readFile(project, 'lib/app.dart'),
        contains(
          'onGenerateTitle: (context) => AppLocalizations.of(context).appTitle',
        ),
      );
    });
  });

  group('FPB-06: saved options and template presets', () {
    test('`template:` changed after init selects the preset', () async {
      final project = createProject();
      expect(await runCli(project, ['init']), 0);
      final file = File(ProjectConfig.configPath(project.path));
      file.writeAsStringSync(
        file
            .readAsStringSync()
            .replaceFirst('template: clean', 'template: enterprise'),
      );
      expect(
        ProjectConfig.fromDirectory(project.path).flavors,
        PackageConstants.defaultFlavors,
      );
    });

    test('init then create --template=enterprise generates flavors', () async {
      final project = createProject();
      await runCli(project, ['init']);
      expect(await runCli(project, ['create', '--template=enterprise']), 0);
      expect(exists(project, 'lib/main_dev.dart'), isTrue);
    });

    test('preset values are comments; overrides are set; it round-trips', () {
      final config = ProjectConfig.forTemplate('enterprise').copyWith(
        organization: 'io.acme',
        flavors: ['dev', 'qa', 'prod'],
        hive: false,
      );
      final yaml = config.toYaml();
      expect(yaml, contains('\nflavors: [dev, qa, prod]\n'));
      expect(yaml, contains('\nhive: false\n'));
      expect(yaml, contains('\n# dio: true\n'));
      expect(yaml, contains('\n# native_flavors: true\n'));

      final parsed = ProjectConfig.fromYaml(yaml);
      expect(parsed.toYaml(), yaml);
      expect(parsed.flavors, ['dev', 'qa', 'prod']);
      expect(parsed.hive, isFalse);
    });

    test('example/flutter_project_builder.yaml matches toYaml', () {
      expect(
        File('example/flutter_project_builder.yaml').readAsStringSync(),
        ProjectConfig.forTemplate('enterprise')
            .copyWith(organization: 'com.mycompany')
            .toYaml(),
      );
    });
  });

  group('FPB-07: no test for a source file that was kept', () {
    late Directory project;
    setUp(() async {
      project = createProject();
      await runCli(project, ['create']);
      await runCli(project, ['generate', 'feature', 'product']);
    });

    for (final (args, testFile) in [
      (
        ['model', 'product', '--feature=product'],
        'test/features/product/product_model_test.dart'
      ),
      (
        ['provider', 'product'],
        'test/features/product/product_provider_test.dart'
      ),
      (['page', 'users'], 'test/features/users/users_page_test.dart'),
    ]) {
      test('generate ${args.join(' ')}', () async {
        final run = await runCliCaptured(project, ['generate', ...args]);
        expect(run.exitCode, 0, reason: '$run');
        expect(exists(project, testFile), isFalse);
        expect(run.output, contains('Did not write $testFile'));
      });
    }

    test('a feature whose files were kept gets no test', () async {
      writeFile(
        project,
        'lib/features/order/data/models/order_model.dart',
        '// mine\n',
      );
      final run =
          await runCliCaptured(project, ['generate', 'feature', 'order']);
      expect(run.exitCode, 0, reason: '$run');
      expect(
        exists(project, 'test/features/order/order_notifier_test.dart'),
        isFalse,
      );
    });
  });

  group('FPB-08: upgrade reports flavors missing on the Dart side', () {
    test('warns about a new flavor', () async {
      final project = createProject();
      await runCli(project, ['create', '--template=enterprise']);
      writeFile(
        project,
        PackageConstants.configFileName,
        'template: enterprise\nflavors: [dev, stage, prod, uat]\n',
      );

      final run = await runCliCaptured(project, ['upgrade', '--force']);

      expect(run.exitCode, 0, reason: '$run');
      expect(run.output, contains('Flavor "uat" is not set up in Dart'));
      expect(run.output, contains('lib/core/config/flavor_config.dart'));
      expect(run.output, contains('lib/main_uat.dart'));
      expect(run.output, contains('runs with the dev configuration'));
      expect(run.output, isNot(contains('Flavor "stage"')));
    });

    test('reads enhanced enums and comments', () {
      final project = createProject();
      writeFile(project, 'lib/core/config/flavor_config.dart', '''
enum Flavor {
  // Local backend.
  dev('Dev'),
  /* staging */ stage('Stage'),
  prod('');

  const Flavor(this.label);
  final String label;
}
''');
      for (final flavor in ['dev', 'stage', 'prod']) {
        writeFile(project, 'lib/main_$flavor.dart', '');
      }
      final config = const ProjectConfig().copyWith(
        flavors: ['dev', 'stage', 'prod', 'qa'],
      );
      final warnings = UpgradeCommand.missingDartFlavors(project.path, config);
      expect(warnings, hasLength(1));
      expect(warnings.single, contains('"qa"'));
    });
  });

  group('FPB-09 and FPB-10: field names', () {
    test('`other` keeps == correct', () {
      final fields = ModelField.parse('other:int');
      for (final code in [
        CodeTemplate.model(Names('link'), fields),
        CodeTemplate.entity(Names('link'), fields),
      ]) {
        expect(code, contains('other.other == this.other'));
      }
    });

    test('built-in identifiers are accepted, reserved words are not', () {
      expect(
        ModelField.parse('type:String,get:int,on:bool').map((f) => f.name),
        ['type', 'get', 'on'],
      );
      for (final name in ['class', 'await', 'int', 'num', 'dynamic']) {
        expect(
          () => ModelField.parse('$name:String'),
          throwsFormatException,
          reason: name,
        );
      }
      // Flavor and generate names stay strict.
      expect(StringUtils.isValidIdentifier('type'), isFalse);
      expect(
        StringUtils.isValidIdentifier('type', allowBuiltIn: true),
        isTrue,
      );
    });

    test('generated models compile, compare and round-trip JSON', () async {
      final names = [
        ...StringUtils.builtInIdentifiers.where((n) => n != 'dynamic'),
        'other',
      ];
      final fields = ModelField.parse(
        [
          for (final name in names)
            '$name:${name == 'when' ? 'DateTime' : 'String'}',
          'price:double?',
        ].join(','),
      );
      final dir = Directory.systemTemp.createTempSync('fpb_fields_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final root = Directory(dir.path);
      writeFile(
        root,
        'lib/features/x/domain/entities/x_entity.dart',
        CodeTemplate.entity(Names('x'), fields),
      );
      writeFile(
        root,
        'lib/features/x/data/models/x_model.dart',
        CodeTemplate.featureModel(Names('x'), fields),
      );
      writeFile(
        root,
        'lib/y_model.dart',
        CodeTemplate.model(Names('y'), fields),
      );
      final json = {
        for (final name in names)
          name: name == 'when' ? "'2026-01-01T00:00:00.000Z'" : "'v'",
        'price': '1.5',
      };
      writeFile(root, 'main.dart', '''
import 'lib/features/x/data/models/x_model.dart';
import 'lib/y_model.dart';

void main() {
  final json = <String, dynamic>{
    ${json.entries.map((e) => "'${e.key}': ${e.value}").join(',\n    ')}
  };
  final x = XModel.fromJson(json);
  final y = YModel.fromJson(json);
  if (x != XModel.fromJson(json)) throw StateError('XModel ==');
  if (y != YModel.fromJson(json)) throw StateError('YModel ==');
  if (y.copyWith(price: 2.0) == y) throw StateError('copyWith');
  for (final entry in json.entries) {
    if (x.toJson()[entry.key] != entry.value) throw StateError(entry.key);
    if (y.toJson()[entry.key] != entry.value) throw StateError(entry.key);
  }
  print('ok');
}
''');

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['run', 'main.dart'],
        workingDirectory: dir.path,
      );
      expect(result.stdout, contains('ok'), reason: '${result.stderr}');
    });
  });

  group('FPB-11: names that clash with SDK types', () {
    final hasFlutter = NativeProject.flutterRoot() != null;

    test('dart:core names are rejected', () async {
      final project = createProject();
      await runCli(project, ['create', '--no-sample']);
      final before = snapshot(project);
      for (final name in ['string', 'duration', 'date_time']) {
        final run = await runCliCaptured(project, ['generate', 'widget', name]);
        expect(run.exitCode, 1, reason: name);
        expect(run.output, contains("dart:core's"));
      }
      expect(snapshot(project), before);
    });

    test(
      'Flutter names re-exported by material.dart are rejected',
      () async {
        final project = createProject();
        await runCli(project, ['create', '--no-sample']);
        for (final args in [
          ['widget', 'edge_insets'],
          ['widget', 'border_radius'],
          ['widget', 'void_callback'],
          ['widget', 'color'],
          // A notifier provider also declares FormState.
          ['provider', 'form'],
        ]) {
          expect(
            await runCli(project, ['generate', ...args]),
            1,
            reason: args.join(' '),
          );
        }
        // Not visible through material.dart, so no clash.
        expect(await runCli(project, ['generate', 'widget', 'summary']), 0);
        expect(
          await runCli(
            project,
            ['generate', 'provider', 'form', '--type=async'],
          ),
          0,
        );
      },
      skip: hasFlutter ? false : 'Flutter SDK not found',
    );

    test('the export resolver follows show/hide and dart:ui', () {
      final sdk = Directory.systemTemp.createTempSync('fpb_sdk_');
      addTearDown(() => sdk.deleteSync(recursive: true));
      final root = Directory(sdk.path);
      const lib = 'packages/flutter/lib';
      writeFile(root, '$lib/material.dart', '''
export 'src/material/button.dart';
export 'widgets.dart';
''');
      writeFile(root, '$lib/src/material/button.dart', '''
class AppBarButton {}
class _Private {}
''');
      writeFile(root, '$lib/widgets.dart', '''
export 'package:characters/characters.dart';
export 'package:vector_math/vector_math_64.dart' show Matrix4;
export 'foundation.dart' show Brightness, // the platform brightness
    UniqueKey;
export 'painting.dart' hide HiddenThing;
''');
      writeFile(root, '$lib/foundation.dart', '''
export 'src/foundation/annotations.dart';
enum Brightness { light, dark }
class UniqueKey {}
''');
      writeFile(root, '$lib/src/foundation/annotations.dart', '''
class Category {}
''');
      writeFile(root, '$lib/painting.dart', '''
export 'dart:ui' show Color, Offset;
typedef VoidCallback = void Function();
extension type Px(int value) {}
mixin Diagnosticable {}
class HiddenThing {}
''');
      writeFile(root, 'bin/cache/pkg/sky_engine/lib/ui/ui.dart', '''
part 'painting.dart';
class Window {}
''');
      writeFile(root, 'bin/cache/pkg/sky_engine/lib/ui/painting.dart', '''
part of dart.ui;
class Color {}
class Offset {}
class Paint {}
''');

      final names = SdkTypeNames.material(sdk.path);

      expect(
        names,
        containsAll([
          'AppBarButton',
          'Brightness',
          'UniqueKey',
          'Matrix4',
          'Characters',
          'Color',
          'Offset',
          'VoidCallback',
          'Px',
          'Diagnosticable',
        ]),
      );
      for (final hidden in [
        '_Private',
        'Category',
        'HiddenThing',
        'Paint',
        'Window',
      ]) {
        expect(names, isNot(contains(hidden)), reason: hidden);
      }
    });
  });

  group('FPB-12: no answer when stdin is at end of file', () {
    late Directory project;
    setUp(() async {
      project = createProject();
      await runCli(project, ['create']);
    });

    for (final command in ['clean', 'upgrade']) {
      test('$command exits 1 and changes nothing', () async {
        final before = snapshot(project);
        final run = await runCliCaptured(project, [command], stdinLines: []);
        expect(run.exitCode, 1, reason: '$run');
        expect(run.stderr, contains('--force'));
        expect(snapshot(project), before);
      });

      test('$command answered "n" aborts with exit 0', () async {
        final before = snapshot(project);
        final run = await runCliCaptured(project, [command], stdinLines: ['n']);
        expect(run.exitCode, 0, reason: '$run');
        expect(run.stdout, contains('Aborted'));
        expect(snapshot(project), before);
      });
    }

    test('clean answered "y" deletes the generated files', () async {
      final run = await runCliCaptured(project, ['clean'], stdinLines: ['y']);
      expect(run.exitCode, 0, reason: '$run');
      expect(exists(project, 'lib/app.dart'), isFalse);
    });
  });

  group('FPB-13: generated code is formatted', () {
    test('create, generate and upgrade run dart format on what they wrote',
        () async {
      final project = createProject();
      final runner = RecordingRunner();

      await runCliCaptured(project, ['create', '--pub'], runner: runner.call);
      // `pub get`, then `dart format` (in batches) after it.
      expect(runner.calls.first.args, ['pub', 'get']);
      expect(runner.calls.skip(1), isNotEmpty);
      expect(
        runner.calls.skip(1).map((c) => c.executable),
        everyElement('dart'),
      );
      expect(runner.calls.last.cwd, project.path);
      expect(runner.formatted, contains(p.join('lib', 'app.dart')));
      expect(runner.formatted, contains(p.join('test', 'widget_test.dart')));
      expect(runner.formatted.every((f) => f.endsWith('.dart')), isTrue);

      runner.calls.clear();
      await runCliCaptured(
        project,
        ['generate', 'feature', 'product'],
        runner: runner.call,
      );
      expect(
        runner.formatted,
        containsAll([
          p.join('lib', 'router', 'app_router.dart'),
          p.joinAll([
            'lib',
            'features',
            'product',
            'presentation',
            'pages',
            'product_page.dart',
          ]),
        ]),
      );

      runner.calls.clear();
      await runCliCaptured(
        project,
        ['upgrade', '--force'],
        runner: runner.call,
      );
      expect(
        runner.formatted,
        contains(p.join('lib', 'core', 'theme', 'app_theme.dart')),
      );
    });

    test('dry runs format nothing', () async {
      final project = createProject();
      final runner = RecordingRunner();
      await runCliCaptured(
        project,
        ['create', '--dry-run'],
        runner: runner.call,
      );
      expect(runner.calls, isEmpty);
    });

    test('formatDart batches files and ignores a missing dart', () async {
      final project = createProject();
      final files = [
        for (var i = 0; i < 120; i++)
          (File(p.join(project.path, 'lib', 'f$i.dart'))
                ..createSync(recursive: true))
              .path,
        p.join(project.path, 'pubspec.yaml'),
        p.join(project.path, 'lib', 'missing.dart'),
      ];
      final runner = RecordingRunner();
      await FlutterCli(runner: runner.call).formatDart(project.path, files);
      expect(runner.calls.map((c) => c.args.length - 1), [50, 50, 20]);

      await FlutterCli(
        runner: (executable, arguments, {workingDirectory}) =>
            throw ProcessException(executable, arguments),
      ).formatDart(project.path, files);
    });
  });

  test('FPB-14: --firebase allows firebase_core 5.x', () async {
    final project = createProject();
    await runCli(project, ['create', '--firebase']);
    expect(
      readFile(project, 'pubspec.yaml'),
      contains('firebase_core: ^5.1.0'),
    );
  });

  test('FPB-15: generate requires create', () async {
    final project = createProject();
    final before = snapshot(project);

    final run = await runCliCaptured(project, ['generate', 'page', 'settings']);

    expect(run.exitCode, 1);
    expect(run.output, contains('Run `flutter_project_builder create` first'));
    expect(snapshot(project), before);
  });

  test('FPB-16: --version prints the bare version', () async {
    final run = await runCliCaptured(createProject(), ['--version']);
    expect(run.stdout, '${PackageConstants.version}\n');
  });
}
