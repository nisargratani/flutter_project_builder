// ignore_for_file: public_member_api_docs

/// Template strings for Flutter's `gen-l10n` localization setup.
class L10nTemplate {
  L10nTemplate._();

  /// `l10n.yaml` in the project root.
  ///
  /// Output is generated into `lib/l10n/` by `flutter pub get` /
  /// `flutter run` (Flutter 3.32+).
  static const String l10nYaml = r'''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
''';

  /// `lib/l10n/app_en.arb`.
  static const String appEnArb = r'''
{
  "@@locale": "en",
  "appTitle": "Flutter App",
  "@appTitle": {
    "description": "The application title shown by the operating system."
  }
}
''';
}
