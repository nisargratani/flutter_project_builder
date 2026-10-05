import 'dart:io';

import 'package:flutter_project_builder/src/utils/pubspec_utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'helpers.dart';

void main() {
  YamlMap pubspecOf(Directory project) =>
      loadYaml(readFile(project, 'pubspec.yaml')) as YamlMap;

  test('isFlutterProject and getProjectName', () {
    final flutter = createProject();
    expect(PubspecUtils.isFlutterProject(flutter.path), isTrue);
    expect(PubspecUtils.getProjectName(flutter.path), 'my_app');

    final dart = createProject(pubspec: 'name: cli\n# sdk: flutter\n');
    expect(PubspecUtils.isFlutterProject(dart.path), isFalse);

    final broken = createProject(pubspec: 'name: [');
    expect(PubspecUtils.isFlutterProject(broken.path), isFalse);
    expect(PubspecUtils.getProjectName(broken.path), isNull);
  });

  group('addDependencies', () {
    test('adds regular and SDK dependencies and is idempotent', () {
      final project = createProject();
      final deps = {'dio': '^5.4.0', 'flutter_localizations': 'sdk: flutter'};

      expect(PubspecUtils.addDependencies(project.path, deps), [
        'dio',
        'flutter_localizations',
      ]);
      expect(PubspecUtils.addDependencies(project.path, deps), isEmpty);

      final dependencies = pubspecOf(project)['dependencies'] as YamlMap;
      expect(dependencies['dio'], '^5.4.0');
      expect(
        (dependencies['flutter_localizations'] as YamlMap)['sdk'],
        'flutter',
      );
    });

    test('never changes an existing constraint in either section', () {
      final project = createProject();
      PubspecUtils.addDependencies(project.path, {
        'cupertino_icons': '^9.9.9',
        'flutter_lints': '^1.0.0',
      });
      final pubspec = pubspecOf(project);
      expect((pubspec['dependencies'] as YamlMap)['cupertino_icons'], '^1.0.8');
      expect(
        (pubspec['dependencies'] as YamlMap).containsKey('flutter_lints'),
        isFalse,
      );
    });

    test('adds dev dependencies and keeps comments', () {
      final project = createProject();
      PubspecUtils.addDependencies(
        project.path,
        {'mocktail': '^1.0.4'},
        isDev: true,
      );
      expect(
        (pubspecOf(project)['dev_dependencies'] as YamlMap)['mocktail'],
        '^1.0.4',
      );
      expect(
        readFile(project, 'pubspec.yaml'),
        contains('# The following adds the Cupertino Icons font'),
      );
    });

    test(
        'creates a missing dependencies section '
        '(dev_dependencies alone must not count)', () {
      final project = createProject(
        pubspec: 'name: x\ndev_dependencies:\n  test: any\n',
      );
      PubspecUtils.addDependencies(project.path, {'dio': '^5.4.0'});
      final pubspec = pubspecOf(project);
      expect((pubspec['dependencies'] as YamlMap)['dio'], '^5.4.0');
      expect((pubspec['dev_dependencies'] as YamlMap)['test'], 'any');
    });

    test('preserves CRLF line endings', () {
      final project = createProject(
        pubspec: flutterPubspec.replaceAll('\n', '\r\n'),
      );
      PubspecUtils.addDependencies(project.path, {'dio': '^5.4.0'});
      PubspecUtils.addLocalizationConfig(project.path);
      final content = readFile(project, 'pubspec.yaml');
      expect(content, contains('dio: ^5.4.0\r\n'));
      expect(content.replaceAll('\r\n', ''), isNot(contains('\n')));
    });
  });

  group('addLocalizationConfig', () {
    test('sets flutter.generate once', () {
      final project = createProject();
      PubspecUtils.addLocalizationConfig(project.path);
      PubspecUtils.addLocalizationConfig(project.path);
      final content = readFile(project, 'pubspec.yaml');
      expect((pubspecOf(project)['flutter'] as YamlMap)['generate'], isTrue);
      expect('generate: true'.allMatches(content), hasLength(1));
      expect(content, isNot(contains('flutter_intl')));
    });

    test('handles an empty flutter section', () {
      final project = createProject(
        pubspec: 'name: x\ndependencies:\n  flutter:\n    sdk: flutter\n'
            'flutter:\n',
      );
      PubspecUtils.addLocalizationConfig(project.path);
      expect((pubspecOf(project)['flutter'] as YamlMap)['generate'], isTrue);
    });
  });
}
