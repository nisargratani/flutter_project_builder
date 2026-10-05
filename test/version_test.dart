import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('PackageConstants.version matches pubspec.yaml', () {
    final pubspec =
        loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    expect(PackageConstants.version, pubspec['version']);
  });
}
