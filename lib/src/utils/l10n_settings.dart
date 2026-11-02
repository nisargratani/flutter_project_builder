import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'file_utils.dart';

/// How the project's `gen-l10n` output is named, read from `l10n.yaml`.
///
/// `create` keeps an existing `l10n.yaml` and translations, so the generated
/// `app.dart` must use the file, class and getter style they define instead
/// of assuming the generated defaults.
class L10nSettings {
  /// Creates settings; the defaults match the `l10n.yaml` that `create`
  /// generates.
  const L10nSettings({
    this.importPath = 'l10n/app_localizations.dart',
    this.className = 'AppLocalizations',
    this.hasAppTitle = true,
    this.nullableGetter = false,
  });

  /// Import of the generated localizations, relative to `lib/`, or `null`
  /// when they are generated outside `lib/` (and cannot be imported).
  final String? importPath;

  /// The generated class (`output-class`).
  final String className;

  /// Whether the template ARB file defines an `appTitle` message.
  final bool hasAppTitle;

  /// Whether `<className>.of(context)` is nullable (`nullable-getter`,
  /// `true` unless set to `false`).
  final bool nullableGetter;

  /// Reads `l10n.yaml` and its template ARB file in [projectPath] (pending
  /// dry-run writes included). Missing or invalid values fall back to
  /// Flutter's defaults.
  static L10nSettings read(String projectPath) {
    final content = FileUtils.readFile(p.join(projectPath, 'l10n.yaml'));
    if (content == null) return const L10nSettings();
    Map<dynamic, dynamic> yaml;
    try {
      final parsed = loadYaml(content);
      yaml = parsed is Map ? parsed : const {};
    } on YamlException {
      yaml = const {};
    }
    String option(String key, String fallback) {
      final value = yaml[key];
      return value is String && value.trim().isNotEmpty
          ? value.trim()
          : fallback;
    }

    final arbDir = option('arb-dir', 'lib/l10n');
    final outputDir = option('output-dir', arbDir);
    final outputFile =
        option('output-localization-file', 'app_localizations.dart');
    final templateArb = option('template-arb-file', 'app_en.arb');
    final arb = FileUtils.readFile(
      p.joinAll([projectPath, ...arbDir.split('/'), templateArb]),
    );

    final output = p.posix.normalize(p.posix.join(outputDir, outputFile));
    return L10nSettings(
      importPath: p.posix.isWithin('lib', output)
          ? p.posix.relative(output, from: 'lib')
          : null,
      className: option('output-class', 'AppLocalizations'),
      hasAppTitle: arb != null && RegExp(r'"appTitle"\s*:').hasMatch(arb),
      nullableGetter: yaml['nullable-getter'] != false,
    );
  }
}
