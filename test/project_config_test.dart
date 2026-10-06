import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('ProjectConfig.fromYaml', () {
    test('empty content yields defaults', () {
      final config = ProjectConfig.fromYaml('');
      expect(config.template, PackageConstants.defaultTemplate);
      expect(config.organization, PackageConstants.defaultOrganization);
      expect(config.flavors, isEmpty);
      expect(config.dio && config.hive && config.localization, isTrue);
      expect(config.sampleFeatures, isTrue);
      expect(config.firebase, isFalse);
    });

    test('parses every option', () {
      final config = ProjectConfig.fromYaml('''
organization: io.acme
template: enterprise
flavors: [dev, qa, prod, qa]
riverpod: false
firebase: true
hive: false
dio: false
localization: false
sample_features: false
''');
      expect(config.organization, 'io.acme');
      expect(config.template, 'enterprise');
      expect(config.flavors, ['dev', 'qa', 'prod'], reason: 'deduplicated');
      expect(config.riverpod, isFalse);
      expect(config.firebase, isTrue);
      expect(config.hive, isFalse);
      expect(config.dio, isFalse);
      expect(config.localization, isFalse);
      expect(config.sampleFeatures, isFalse);
    });

    test('toYaml round-trips', () {
      const original = ProjectConfig(
        organization: 'io.acme',
        template: 'basic',
        flavors: ['dev', 'prod'],
        dio: false,
        firebase: true,
      );
      final parsed = ProjectConfig.fromYaml(original.toYaml());
      expect(parsed.organization, original.organization);
      expect(parsed.template, original.template);
      expect(parsed.flavors, original.flavors);
      expect(parsed.dio, isFalse);
      expect(parsed.firebase, isTrue);
      expect(
        ProjectConfig.fromYaml(const ProjectConfig().toYaml()).flavors,
        isEmpty,
      );
    });

    test('rejects malformed content with a FormatException', () {
      for (final content in [
        '- just\n- a list\n',
        'template: [unclosed',
        'template: huge',
        'dio: "yes"',
        'flavors: dev',
        'flavors: [Dev-1]',
        'flavors: [class]',
      ]) {
        expect(
          () => ProjectConfig.fromYaml(content),
          throwsFormatException,
          reason: content,
        );
      }
    });
  });

  group('templates', () {
    test('presets differ', () {
      final basic = ProjectConfig.forTemplate('basic');
      expect(
        [basic.dio, basic.hive, basic.localization, basic.sampleFeatures],
        everyElement(isFalse),
      );
      expect(ProjectConfig.forTemplate('clean').dio, isTrue);
      expect(
        ProjectConfig.forTemplate('enterprise').flavors,
        PackageConstants.defaultFlavors,
      );
      expect(() => ProjectConfig.forTemplate('x'), throwsFormatException);
    });

    test('missing keys fall back to the template preset', () {
      final config = ProjectConfig.fromYaml('template: basic\ndio: true\n');
      expect(config.dio, isTrue, reason: 'explicit key wins');
      expect(config.hive, isFalse, reason: 'basic preset');
      expect(
        ProjectConfig.fromYaml('dio: false', templateOverride: 'enterprise')
            .flavors,
        PackageConstants.defaultFlavors,
      );
      expect(
        ProjectConfig.fromYaml('template: enterprise\nflavors: []\n').flavors,
        isEmpty,
      );
    });
  });

  test('organization and native_flavors', () {
    expect(ProjectConfig.isValidOrganization('com.acme'), isTrue);
    expect(ProjectConfig.isValidOrganization('io.acme_labs.app'), isTrue);
    for (final value in ['acme', 'com.', '.com', 'com..acme', 'com.1acme']) {
      expect(ProjectConfig.isValidOrganization(value), isFalse, reason: value);
    }
    expect(
      () => ProjectConfig.fromYaml('organization: acme'),
      throwsFormatException,
    );
    final config = ProjectConfig.fromYaml(
      'organization: io.acme\nflavors: [dev]\nnative_flavors: false\n',
    );
    expect(config.hasCustomOrganization, isTrue);
    expect(config.hasNativeFlavors, isFalse);
    expect(ProjectConfig.fromYaml(config.toYaml()).nativeFlavors, isFalse);
  });

  test('fromDirectory falls back to defaults without a file', () {
    final project = createProject();
    expect(ProjectConfig.existsIn(project.path), isFalse);
    expect(
      ProjectConfig.fromDirectory(project.path).template,
      PackageConstants.defaultTemplate,
    );

    File(p.join(project.path, PackageConstants.configFileName))
        .writeAsStringSync('template: basic\n');
    expect(ProjectConfig.existsIn(project.path), isTrue);
    expect(ProjectConfig.fromDirectory(project.path).template, 'basic');
  });

  test('the example configuration file is valid', () {
    final config = ProjectConfig.fromYaml(
      File('example/flutter_project_builder.yaml').readAsStringSync(),
    );
    expect(config.template, 'enterprise');
    expect(config.hasNativeFlavors, isTrue);
  });
}
