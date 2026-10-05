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
}
