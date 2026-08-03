// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Utilities for reading and modifying `pubspec.yaml` files.
///
/// Provides methods to add dependencies, update SDK constraints,
/// and validate Flutter project structure.
class PubspecUtils {
  PubspecUtils._();

  /// Checks if the given [path] contains a valid Flutter project.
  ///
  /// A valid Flutter project has a `pubspec.yaml` with a Flutter SDK
  /// dependency.
  static bool isFlutterProject(String path) {
    final pubspecPath = p.join(path, 'pubspec.yaml');
    final file = File(pubspecPath);
    if (!file.existsSync()) return false;

    final content = file.readAsStringSync();
    return content.contains('flutter:') && content.contains('sdk: flutter');
  }

  /// Returns the project name from `pubspec.yaml`.
  static String? getProjectName(String path) {
    final pubspecPath = p.join(path, 'pubspec.yaml');
    final file = File(pubspecPath);
    if (!file.existsSync()) return null;

    final yaml = loadYaml(file.readAsStringSync()) as YamlMap?;
    return yaml?['name'] as String?;
  }

  /// Adds dependencies to `pubspec.yaml`.
  ///
  /// This modifies the pubspec file by appending dependencies.
  /// Handles both regular and SDK-based dependencies.
  static void addDependencies(
    String projectPath,
    Map<String, String> dependencies, {
    bool isDev = false,
  }) {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    final file = File(pubspecPath);
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    final section = isDev ? 'dev_dependencies' : 'dependencies';

    // Ensure the section exists.
    if (!content.contains('$section:')) {
      content += '\n$section:\n';
    }

    final sectionIndex = content.indexOf('$section:');

    if (sectionIndex == -1) return;

    // Find the end of the section.
    final lines = content.split('\n');
    var insertIndex = 0;
    var inSection = false;

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trimRight() == '$section:') {
        inSection = true;
        insertIndex = i + 1;
        continue;
      }
      if (inSection) {
        if (lines[i].startsWith('  ') || lines[i].trim().isEmpty) {
          insertIndex = i + 1;
        } else {
          break;
        }
      }
    }

    // Build new dependency lines.
    final newDeps = StringBuffer();
    for (final entry in dependencies.entries) {
      final name = entry.key;
      final version = entry.value;

      // Skip if already present.
      if (content.contains('  $name:')) continue;

      if (version.startsWith('sdk:')) {
        newDeps.writeln('  $name:');
        newDeps.writeln('    $version');
      } else {
        newDeps.writeln('  $name: $version');
      }
    }

    if (newDeps.isEmpty) return;

    // Insert at the correct position.
    lines.insert(insertIndex, newDeps.toString().trimRight());
    file.writeAsStringSync(lines.join('\n'));
  }

  /// Adds Flutter localization configuration to `pubspec.yaml`.
  static void addLocalizationConfig(String projectPath) {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    final file = File(pubspecPath);
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();

    if (content.contains('generate: true')) return;
    
    final lines = content.split('\n');
    final flutterIndex = lines.indexWhere((l) => l == 'flutter:');
    if (flutterIndex != -1) {
      lines.insert(flutterIndex + 1, '  generate: true');
    } else {
      lines.add('\nflutter:\n  generate: true\n');
    }

    lines.add('''

flutter_intl:
  enabled: true
  arb_dir: lib/l10n
  template_arb_file: app_en.arb
  output_localization_file: app_localizations.dart
''');

    file.writeAsStringSync(lines.join('\n'));
  }
}
