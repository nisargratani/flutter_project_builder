import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'file_utils.dart';
import 'string_utils.dart';

/// Outcome of a native project edit.
class NativeEditResult {
  /// Project-relative paths that were (or, in a dry run, would be) changed.
  final List<String> changed = [];

  /// Problems that need the user's attention; the edit continued.
  final List<String> warnings = [];
}

/// Edits the platform folders created by `flutter create` (`android/`,
/// `ios/`, `macos/`, `linux/`, `windows/`).
///
/// All edits are idempotent and preserve the rest of each file. Platforms
/// whose folder does not exist are skipped.
class NativeProject {
  /// Creates an editor for the Flutter project at [projectPath] whose
  /// pubspec name is [packageName].
  NativeProject({required this.projectPath, required this.packageName});

  /// Root of the Flutter project.
  final String projectPath;

  /// The pubspec package name (e.g. `my_app`).
  final String packageName;

  /// Flavors that keep the base application ID and display name.
  static const Set<String> productionFlavors = {'prod', 'production'};

  /// Human-readable app name derived from the package name (`My App`).
  String get displayName => StringUtils.toTitleCase(packageName);

  /// Android application ID / Linux application ID for [organization].
  String androidIdFor(String organization) => '$organization.$packageName';

  /// iOS/macOS bundle identifier for [organization].
  ///
  /// Bundle identifiers may not contain underscores, so they are replaced by
  /// hyphens and the app segment is camelCased, as `flutter create` does.
  String appleIdFor(String organization) =>
      '${organization.replaceAll('_', '-')}.'
      '${StringUtils.toCamelCase(packageName)}';

  String _path(String relative) => p.join(projectPath, relative);

  void _write(NativeEditResult result, String relative, String content) {
    FileUtils.createFile(_path(relative), content);
    if (!result.changed.contains(relative)) result.changed.add(relative);
  }

  // ── Organization ───────────────────────────────────────────────────

  /// Sets the application ID / bundle identifiers to
  /// `<organization>.<package>` on every platform that has one.
  ///
  /// The Android `namespace` (Kotlin package of `MainActivity`) is left
  /// unchanged; only the `applicationId` that identifies the app changes.
  NativeEditResult applyOrganization(String organization) {
    final result = NativeEditResult();
    final androidId = androidIdFor(organization);
    final appleId = appleIdFor(organization);

    // Android.
    final gradle = _gradleFile();
    if (gradle != null) {
      final content = FileUtils.readFile(_path(gradle))!;
      final updated = content.replaceFirstMapped(
        RegExp(r'(applicationId\s*=?\s*)"[^"]*"'),
        (m) => '${m[1]}"$androidId"',
      );
      if (updated != content) _write(result, gradle, updated);
    }

    // iOS: every bundle ID in the project shares the Runner ID as prefix.
    for (final platform in ['ios', 'macos']) {
      final pbxproj = '$platform/Runner.xcodeproj/project.pbxproj';
      final content = FileUtils.readFile(_path(pbxproj));
      if (content == null) continue;

      var oldId = _runnerBundleId(content);
      if (platform == 'macos') {
        const xcconfig = 'macos/Runner/Configs/AppInfo.xcconfig';
        final config = FileUtils.readFile(_path(xcconfig));
        final match = config == null
            ? null
            : RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = (\S+)').firstMatch(config);
        if (match != null) {
          oldId = match[1];
          if (oldId != appleId) {
            _write(
              result,
              xcconfig,
              config!.replaceFirst(
                  match[0]!,
                  'PRODUCT_BUNDLE_IDENTIFIER = '
                  '$appleId'),
            );
          }
        }
      }
      if (oldId == null || oldId == appleId) continue;
      final updated = _replaceBundleIdPrefix(content, oldId, appleId);
      if (updated != content) _write(result, pbxproj, updated);
    }

    // Linux.
    const cmake = 'linux/CMakeLists.txt';
    final cmakeContent = FileUtils.readFile(_path(cmake));
    if (cmakeContent != null) {
      final updated = cmakeContent.replaceFirst(
        RegExp(r'set\(APPLICATION_ID "[^"]*"\)'),
        'set(APPLICATION_ID "$androidId")',
      );
      if (updated != cmakeContent) _write(result, cmake, updated);
    }

    // Windows: the organization appears as the company name.
    const rc = 'windows/runner/Runner.rc';
    final rcContent = FileUtils.readFile(_path(rc));
    if (rcContent != null) {
      final updated = rcContent.replaceAllMapped(
        RegExp('(VALUE "CompanyName", )"[^"]*"'),
        (m) => '${m[1]}"$organization"',
      );
      if (updated != rcContent) _write(result, rc, updated);
    }

    return result;
  }

  // ── Flavors ────────────────────────────────────────────────────────

  /// Configures [flavors] natively so `flutter run --flavor <name>` works:
  ///
  /// - Android: a `flavor` dimension with one product flavor per flavor
  ///   (application ID suffix and app name), and the manifest label reads
  ///   the flavor's app name.
  /// - iOS/macOS: `Debug-<flavor>`, `Profile-<flavor>`, `Release-<flavor>`
  ///   build configurations, a `<flavor>` scheme, per-flavor bundle IDs,
  ///   (iOS) per-flavor display names, and matching CocoaPods mappings in
  ///   an existing Podfile (run this again after `flutter pub get` creates
  ///   one; it is idempotent).
  ///
  /// Production flavors ([productionFlavors]) keep the base IDs and name.
  NativeEditResult configureFlavors(List<String> flavors) {
    final result = NativeEditResult();
    if (flavors.isEmpty) return result;
    _configureAndroidFlavors(flavors, result);
    for (final platform in ['ios', 'macos']) {
      _configureXcodeFlavors(platform, flavors, result);
    }
    return result;
  }

  String _suffixFor(String flavor) =>
      productionFlavors.contains(flavor) ? '' : '.$flavor';

  String _nameFor(String flavor) => productionFlavors.contains(flavor)
      ? displayName
      : '$displayName ${StringUtils.toTitleCase(flavor)}';

  String? _gradleFile() {
    for (final name in ['build.gradle.kts', 'build.gradle']) {
      final relative = 'android/app/$name';
      if (FileUtils.fileExists(_path(relative))) return relative;
    }
    return null;
  }

  void _configureAndroidFlavors(
    List<String> flavors,
    NativeEditResult result,
  ) {
    final gradle = _gradleFile();
    if (gradle == null) return;
    final content = FileUtils.readFile(_path(gradle))!;

    if (content.contains('productFlavors')) {
      final missing = flavors
          .where(
            (f) =>
                !content.contains('create("$f")') && !content.contains('$f {'),
          )
          .toList();
      if (missing.isNotEmpty) {
        result.warnings.add(
          '$gradle already defines productFlavors; add ${missing.join(', ')} '
          'manually.',
        );
      }
    } else {
      final insertAt = _blockEnd(content, 'defaultConfig');
      if (insertAt == null) {
        result.warnings.add(
          'Could not find defaultConfig in $gradle; Android flavors were not '
          'configured.',
        );
        return;
      }
      final block = gradle.endsWith('.kts')
          ? _kotlinFlavors(flavors)
          : _groovyFlavors(flavors);
      _write(
        result,
        gradle,
        '${content.substring(0, insertAt)}\n\n$block'
        '${content.substring(insertAt)}',
      );
    }

    const manifest = 'android/app/src/main/AndroidManifest.xml';
    final manifestContent = FileUtils.readFile(_path(manifest));
    if (manifestContent != null && !manifestContent.contains(r'${appName}')) {
      _write(
        result,
        manifest,
        manifestContent.replaceFirst(
          RegExp('android:label="[^"]*"'),
          r'android:label="${appName}"',
        ),
      );
    }
  }

  String _kotlinFlavors(List<String> flavors) {
    final buffer = StringBuffer()
      ..writeln('    flavorDimensions += "flavor"')
      ..writeln('    productFlavors {');
    for (final flavor in flavors) {
      buffer
        ..writeln('        create("$flavor") {')
        ..writeln('            dimension = "flavor"');
      final suffix = _suffixFor(flavor);
      if (suffix.isNotEmpty) {
        buffer.writeln('            applicationIdSuffix = "$suffix"');
      }
      buffer
        ..writeln(
          '            manifestPlaceholders["appName"] = "${_nameFor(flavor)}"',
        )
        ..writeln('        }');
    }
    buffer.write('    }');
    return buffer.toString();
  }

  String _groovyFlavors(List<String> flavors) {
    final buffer = StringBuffer()
      ..writeln('    flavorDimensions "flavor"')
      ..writeln('    productFlavors {');
    for (final flavor in flavors) {
      buffer
        ..writeln('        $flavor {')
        ..writeln('            dimension "flavor"');
      final suffix = _suffixFor(flavor);
      if (suffix.isNotEmpty) {
        buffer.writeln('            applicationIdSuffix "$suffix"');
      }
      buffer
        ..writeln(
          '            manifestPlaceholders = [appName: "${_nameFor(flavor)}"]',
        )
        ..writeln('        }');
    }
    buffer.write('    }');
    return buffer.toString();
  }

  /// Returns the index just after the closing brace of the first
  /// `<name> {` block, or `null`.
  static int? _blockEnd(String content, String name) {
    final start = RegExp('\\b$name\\s*\\{').firstMatch(content);
    if (start == null) return null;
    var depth = 0;
    for (var i = start.end - 1; i < content.length; i++) {
      if (content[i] == '{') depth++;
      if (content[i] == '}' && --depth == 0) return i + 1;
    }
    return null;
  }

  // ── Xcode ──────────────────────────────────────────────────────────

  static const List<String> _baseConfigurations = [
    'Debug',
    'Profile',
    'Release',
  ];

  static final RegExp _buildConfigurationPattern = RegExp(
    r'\t\t([0-9A-F]{24}) /\* ([^*]+?) \*/ = \{\n'
    r'\t\t\tisa = XCBuildConfiguration;\n.*?\n\t\t\};\n',
    dotAll: true,
  );

  static final RegExp _configurationListPattern = RegExp(
    r'\t\t[0-9A-F]{24} /\* Build configuration list for (\w+) "([^"]+)" \*/'
    r' = \{\n\t\t\tisa = XCConfigurationList;\n'
    r'\t\t\tbuildConfigurations = \(\n(.*?)\t\t\t\);',
    dotAll: true,
  );

  static final RegExp _listEntryPattern =
      RegExp(r'\t\t\t\t([0-9A-F]{24}) /\* ([^*]+?) \*/,\n');

  void _configureXcodeFlavors(
    String platform,
    List<String> flavors,
    NativeEditResult result,
  ) {
    final pbxproj = '$platform/Runner.xcodeproj/project.pbxproj';
    var content = FileUtils.readFile(_path(pbxproj));
    if (content == null) return;

    final baseId = platform == 'macos'
        ? _macosBundleId() ?? _runnerBundleId(content)
        : _runnerBundleId(content);
    if (baseId == null) {
      result.warnings.add('Could not find the Runner bundle identifier in '
          '$pbxproj; $platform flavors were not configured.');
      return;
    }

    final configurations = {
      for (final m in _buildConfigurationPattern.allMatches(content))
        m[1]!: m[0]!,
    };
    final random = Random.secure();
    String newId() {
      while (true) {
        final id = List.generate(
          12,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join().toUpperCase();
        if (!content!.contains(id)) return id;
      }
    }

    final newObjects = StringBuffer();
    // Original text of a list's entries → replacement text.
    final listEdits = <String, String>{};
    // Original config object → replacement (display names on Runner).
    final configEdits = <String, String>{};
    final setDisplayName = platform == 'ios';

    for (final list in _configurationListPattern.allMatches(content)) {
      final isRunner = list[1] == 'PBXNativeTarget' && list[2] == 'Runner';
      final entriesText = list[3]!;
      final entries = {
        for (final e in _listEntryPattern.allMatches(entriesText)) e[2]!: e[1]!,
      };
      final added = StringBuffer();

      for (final base in _baseConfigurations) {
        final baseObjectId = entries[base];
        final baseObject =
            baseObjectId == null ? null : configurations[baseObjectId];
        if (baseObject == null) continue;

        if (isRunner && setDisplayName) {
          configEdits[baseObject] = _setBuildSetting(
            baseObject,
            'APP_DISPLAY_NAME',
            '"$displayName"',
            onlyIfMissing: true,
          );
        }

        for (final flavor in flavors) {
          final name = '$base-$flavor';
          if (entries.containsKey(name)) continue;
          final id = newId();
          var clone = baseObject
              .replaceFirst(baseObjectId!, id)
              .replaceFirst('/* $base */', '/* $name */')
              .replaceFirst('\t\t\tname = $base;', '\t\t\tname = $name;');
          if (isRunner) {
            clone = _setBuildSetting(
              clone,
              'PRODUCT_BUNDLE_IDENTIFIER',
              '$baseId${_suffixFor(flavor)}',
            );
            if (setDisplayName) {
              clone = _setBuildSetting(
                clone,
                'APP_DISPLAY_NAME',
                '"${_nameFor(flavor)}"',
              );
            }
          }
          newObjects.write(clone);
          added.write('\t\t\t\t$id /* $name */,\n');
        }
      }
      if (added.isNotEmpty) {
        listEdits[list[0]!] = list[0]!.replaceFirst(
          '$entriesText\t\t\t);',
          '$entriesText$added\t\t\t);',
        );
      }
    }

    final original = content;
    configEdits
        .forEach((from, to) => content = content!.replaceFirst(from, to));
    listEdits.forEach((from, to) => content = content!.replaceFirst(from, to));
    if (newObjects.isNotEmpty) {
      content = content!.replaceFirst(
        '/* End XCBuildConfiguration section */',
        '$newObjects/* End XCBuildConfiguration section */',
      );
    }
    if (content != original) _write(result, pbxproj, content!);

    if (setDisplayName) _useDisplayNameSetting(result);
    _writeSchemes(platform, flavors, result);
    _mapPodConfigurations(platform, flavors, result);
  }

  /// Sets [key] to [value] in the `buildSettings` of a configuration object.
  static String _setBuildSetting(
    String object,
    String key,
    String value, {
    bool onlyIfMissing = false,
  }) {
    final existing = RegExp('\\t\\t\\t\\t$key = [^;]*;').firstMatch(object);
    if (existing != null) {
      return onlyIfMissing
          ? object
          : object.replaceFirst(existing[0]!, '\t\t\t\t$key = $value;');
    }
    return object.replaceFirst(
      '\t\t\tbuildSettings = {\n',
      '\t\t\tbuildSettings = {\n\t\t\t\t$key = $value;\n',
    );
  }

  void _useDisplayNameSetting(NativeEditResult result) {
    const plist = 'ios/Runner/Info.plist';
    final content = FileUtils.readFile(_path(plist));
    if (content == null) return;
    final match = RegExp(
      r'(<key>CFBundleDisplayName</key>\s*<string>)([^<]*)(</string>)',
    ).firstMatch(content);
    if (match == null || match[2] == r'$(APP_DISPLAY_NAME)') return;
    _write(
      result,
      plist,
      content.replaceFirst(
        match[0]!,
        '${match[1]}\$(APP_DISPLAY_NAME)${match[3]}',
      ),
    );
  }

  void _writeSchemes(
    String platform,
    List<String> flavors,
    NativeEditResult result,
  ) {
    const schemesDir = 'Runner.xcodeproj/xcshareddata/xcschemes';
    final runner = FileUtils.readFile(
      _path('$platform/$schemesDir/'
          'Runner.xcscheme'),
    );
    if (runner == null) {
      result.warnings.add('No Runner.xcscheme in $platform; create the '
          'flavor schemes in Xcode.');
      return;
    }
    for (final flavor in flavors) {
      final relative = '$platform/$schemesDir/$flavor.xcscheme';
      if (FileUtils.fileExists(_path(relative))) continue;
      var scheme = runner;
      for (final base in _baseConfigurations) {
        scheme = scheme.replaceAll(
          'buildConfiguration = "$base"',
          'buildConfiguration = "$base-$flavor"',
        );
      }
      _write(result, relative, scheme);
    }
  }

  /// Maps the flavor configurations in the Podfile so CocoaPods (and
  /// Flutter's podhelper) treat `Debug-<flavor>` as a debug build. Without
  /// this, flavored debug builds would link the release engine.
  void _mapPodConfigurations(
    String platform,
    List<String> flavors,
    NativeEditResult result,
  ) {
    final relative = '$platform/Podfile';
    final podfile = _readPodfile(platform);
    if (podfile == null) return;

    final block = RegExp(r"project 'Runner', \{\n(.*?)\}", dotAll: true)
        .firstMatch(podfile);
    if (block == null) {
      result.warnings.add('Could not find `project \'Runner\'` in $relative; '
          'map the flavor configurations manually.');
      return;
    }
    final mappings = StringBuffer();
    for (final flavor in flavors) {
      for (final base in _baseConfigurations) {
        final name = '$base-$flavor';
        if (block[1]!.contains("'$name'")) continue;
        mappings.writeln(
          "  '$name' => :${base == 'Debug' ? 'debug' : 'release'},",
        );
      }
    }
    if (mappings.isEmpty) return;
    final updated = podfile.replaceFirst(
      block[0]!,
      "project 'Runner', {\n${block[1]}$mappings}",
    );
    _write(result, relative, updated);
  }

  /// Returns the existing Podfile of [platform], or `null`.
  ///
  /// A Podfile is never created here: Flutter creates one itself (during
  /// `flutter pub get`) only when the project uses CocoaPods. With Swift
  /// Package Manager, an extra Podfile would break the build.
  String? _readPodfile(String platform) =>
      FileUtils.readFile(_path('$platform/Podfile'));

  // ── Deployment targets ─────────────────────────────────────────────

  /// Raises the minimum iOS/macOS versions to at least [ios] / [macos]
  /// (for example because a plugin such as `firebase_core` requires them).
  ///
  /// Updates the Xcode project, an explicit Podfile `platform` line and
  /// `AppFrameworkInfo.plist`. Targets that are already higher are kept.
  NativeEditResult raiseDeploymentTargets({String? ios, String? macos}) {
    final result = NativeEditResult();
    for (final (platform, minimum, setting, podPlatform) in [
      ('ios', ios, 'IPHONEOS_DEPLOYMENT_TARGET', 'ios'),
      ('macos', macos, 'MACOSX_DEPLOYMENT_TARGET', 'osx'),
    ]) {
      if (minimum == null) continue;
      final pbxproj = '$platform/Runner.xcodeproj/project.pbxproj';
      final content = FileUtils.readFile(_path(pbxproj));
      if (content == null) continue;

      final updated = content.replaceAllMapped(
        RegExp('$setting = ([0-9.]+);'),
        (m) => _isLower(m[1]!, minimum) ? '$setting = $minimum;' : m[0]!,
      );
      if (updated != content) _write(result, pbxproj, updated);

      // CocoaPods infers the platform from the Xcode project when the
      // Podfile does not set one, so only an explicit lower value is raised.
      final podfile = _readPodfile(platform);
      final line = podfile == null
          ? null
          : RegExp(
              "^platform :$podPlatform, '([0-9.]+)'",
              multiLine: true,
            ).firstMatch(podfile);
      if (line != null && _isLower(line[1]!, minimum)) {
        _write(
          result,
          '$platform/Podfile',
          podfile!.replaceFirst(line[0]!, "platform :$podPlatform, '$minimum'"),
        );
      }

      if (platform == 'ios') {
        const plist = 'ios/Flutter/AppFrameworkInfo.plist';
        final info = FileUtils.readFile(_path(plist));
        final match = info == null
            ? null
            : RegExp(r'(<key>MinimumOSVersion</key>\s*<string>)([0-9.]+)'
                    '(</string>)')
                .firstMatch(info);
        if (match != null && _isLower(match[2]!, minimum)) {
          _write(
            result,
            plist,
            info!.replaceFirst(match[0]!, '${match[1]}$minimum${match[3]}'),
          );
        }
      }
    }
    return result;
  }

  /// Whether version [a] is lower than [b] (e.g. `13.0` < `15.0`).
  static bool _isLower(String a, String b) {
    final left = a.split('.').map(int.parse).toList();
    final right = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < left.length ? left[i] : 0;
      final y = i < right.length ? right[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }

  /// Locates the Flutter SDK from `FLUTTER_ROOT` or the `flutter`
  /// executable on `PATH`.
  static String? flutterRoot() {
    final env = Platform.environment['FLUTTER_ROOT'];
    if (env != null && Directory(env).existsSync()) return env;
    final separator = Platform.isWindows ? ';' : ':';
    final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
    for (final dir in (Platform.environment['PATH'] ?? '').split(separator)) {
      final candidate = File(p.join(dir, executable));
      if (!candidate.existsSync()) continue;
      final resolved = candidate.resolveSymbolicLinksSync();
      final root = p.dirname(p.dirname(resolved));
      if (Directory(p.join(root, 'packages', 'flutter_tools')).existsSync()) {
        return root;
      }
    }
    return null;
  }

  String? _macosBundleId() {
    final config =
        FileUtils.readFile(_path('macos/Runner/Configs/AppInfo.xcconfig'));
    if (config == null) return null;
    return RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = (\S+)').firstMatch(config)?[1];
  }

  /// The most common bundle ID that is not a test target's.
  static String? _runnerBundleId(String pbxproj) {
    final counts = <String, int>{};
    for (final m
        in RegExp('PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(pbxproj)) {
      final id = m[1]!.replaceAll('"', '');
      if (id.endsWith('Tests')) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return (counts.entries.toList()..sort((a, b) => b.value - a.value))
        .first
        .key;
  }

  static String _replaceBundleIdPrefix(
    String pbxproj,
    String oldId,
    String newId,
  ) =>
      pbxproj.replaceAllMapped(
        RegExp('PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'),
        (m) {
          final id = m[1]!;
          if (id == oldId || id.startsWith('$oldId.')) {
            return 'PRODUCT_BUNDLE_IDENTIFIER = $newId'
                '${id.substring(oldId.length)};';
          }
          return m[0]!;
        },
      );
}
