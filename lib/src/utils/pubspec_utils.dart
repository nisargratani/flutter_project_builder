import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'file_utils.dart';

/// Utilities for reading and modifying `pubspec.yaml` files.
///
/// Edits are performed with `package:yaml_edit`, which preserves existing
/// comments, formatting and line endings.
class PubspecUtils {
  PubspecUtils._();

  static const List<String> _dependencySections = [
    'dependencies',
    'dev_dependencies',
  ];

  /// Checks if the given [path] contains a valid Flutter project.
  ///
  /// A valid Flutter project has a parseable `pubspec.yaml` that declares
  /// `flutter: {sdk: flutter}` under `dependencies`.
  static bool isFlutterProject(String path) {
    final pubspec = _load(path);
    if (pubspec == null) return false;
    final dependencies = pubspec['dependencies'];
    if (dependencies is! YamlMap) return false;
    final flutter = dependencies['flutter'];
    return flutter is YamlMap && flutter['sdk'] == 'flutter';
  }

  /// Returns the project name from `pubspec.yaml`, or `null` if it cannot be
  /// read.
  static String? getProjectName(String path) {
    final name = _load(path)?['name'];
    return name is String ? name : null;
  }

  /// Adds [dependencies] to the `dependencies` (or `dev_dependencies` when
  /// [isDev] is `true`) section of `pubspec.yaml` in [projectPath].
  ///
  /// Values are version constraints (e.g. `^1.0.0`, `any`) or SDK
  /// dependencies written as `sdk: flutter`. A package that is already
  /// declared in either `dependencies` or `dev_dependencies` is left
  /// untouched, so existing constraints are never changed.
  ///
  /// Returns the names of the packages that were added.
  static List<String> addDependencies(
    String projectPath,
    Map<String, String> dependencies, {
    bool isDev = false,
  }) {
    final path = p.join(projectPath, 'pubspec.yaml');
    final content = FileUtils.readFile(path);
    if (content == null) return const [];

    final editor = YamlEditor(content);
    final pubspec = editor.parseAt([]).value;
    if (pubspec is! Map) return const [];

    final section = isDev ? 'dev_dependencies' : 'dependencies';
    final added = <String>[];

    for (final entry in dependencies.entries) {
      if (_isDeclared(pubspec, entry.key)) continue;

      final value = _dependencyValue(entry.value);
      final sectionNode =
          editor.parseAt([section], orElse: () => wrapAsYamlNode(null));
      if (sectionNode.value is Map) {
        editor.update([section, entry.key], value);
      } else {
        editor.update([section], {entry.key: value});
      }
      added.add(entry.key);
    }

    if (added.isNotEmpty) FileUtils.createFile(path, editor.toString());
    return added;
  }

  /// Returns the packages of [required] (name → version constraint, as in
  /// [addDependencies]) that `pubspec.yaml` in [projectPath] already
  /// declares with a constraint that allows none of the required versions,
  /// mapped to that existing constraint.
  ///
  /// For example `flutter_riverpod: ^2.6.1` when the generated code needs
  /// `^3.0.0`. [addDependencies] keeps existing constraints, so these must be
  /// reported. SDK, path and git dependencies, `any`, and packages listed in
  /// `dependency_overrides` are not checked.
  static Map<String, String> incompatibleConstraints(
    String projectPath,
    Map<String, String> required,
  ) {
    final pubspec = _load(projectPath);
    if (pubspec == null) return const {};
    final overrides = pubspec['dependency_overrides'];
    final result = <String, String>{};
    for (final MapEntry(key: name, value: wanted) in required.entries) {
      if (wanted == 'any' || wanted.startsWith('sdk:')) continue;
      if (overrides is Map && overrides.containsKey(name)) continue;
      for (final section in _dependencySections) {
        final deps = pubspec[section];
        final declared = deps is Map ? deps[name] : null;
        // `name: ^1.0.0`, or a hosted map with an explicit `version:`.
        final existing = declared is Map ? declared['version'] : declared;
        if (existing is! String) continue;
        try {
          if (!VersionConstraint.parse(existing)
              .allowsAny(VersionConstraint.parse(wanted))) {
            result[name] = existing;
          }
        } on FormatException {
          // Not a version constraint; `pub get` will report it.
        }
      }
    }
    return result;
  }

  /// Enables Flutter's localization code generation by setting
  /// `flutter: generate: true` in `pubspec.yaml`.
  ///
  /// Does nothing if the flag is already set.
  static void addLocalizationConfig(String projectPath) =>
      setFlutterOption(projectPath, 'generate', true);

  /// Sets `flutter: <key>: <value>` in `pubspec.yaml` (for example
  /// `default-flavor`). Does nothing if the value is already set.
  static void setFlutterOption(String projectPath, String key, Object value) {
    final path = p.join(projectPath, 'pubspec.yaml');
    final content = FileUtils.readFile(path);
    if (content == null) return;

    final editor = YamlEditor(content);
    final flutter =
        editor.parseAt(['flutter'], orElse: () => wrapAsYamlNode(null));
    if (flutter.value is Map) {
      if ((flutter.value as Map)[key] == value) return;
      editor.update(['flutter', key], value);
    } else {
      editor.update(['flutter'], {key: value});
    }
    FileUtils.createFile(path, editor.toString());
  }

  static bool _isDeclared(Map<dynamic, dynamic> pubspec, String name) =>
      _dependencySections.any((section) {
        final deps = pubspec[section];
        return deps is Map && deps.containsKey(name);
      });

  static Object _dependencyValue(String constraint) {
    if (constraint.startsWith('sdk:')) {
      return {'sdk': constraint.substring('sdk:'.length).trim()};
    }
    return constraint;
  }

  static YamlMap? _load(String path) {
    final content = FileUtils.readFile(p.join(path, 'pubspec.yaml'));
    if (content == null) return null;
    try {
      final yaml = loadYaml(content);
      return yaml is YamlMap ? yaml : null;
    } on YamlException {
      return null;
    }
  }
}
