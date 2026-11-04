import 'dart:io';

import 'package:path/path.dart' as p;

/// Recognises the starter files `flutter create` writes (`lib/main.dart`,
/// `test/widget_test.dart`), so `create` replaces them only while the user
/// has not changed them.
class FlutterTemplates {
  FlutterTemplates._();

  /// The `test/widget_test.dart` that `flutter create` writes for the app
  /// [projectName] (the counter smoke test). It has not changed since 2022.
  static String defaultWidgetTest(String projectName) => '''
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:$projectName/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
''';

  /// Whether [content] of the project file [relativePath] (`lib/main.dart`
  /// or `test/widget_test.dart`, `/`-separated) is still exactly what
  /// `flutter create` wrote for the app [projectName].
  ///
  /// `lib/main.dart` is compared with the templates of the Flutter SDK at
  /// [flutterRoot] (the counter app and the `--empty` app), so without an
  /// SDK it is never recognised. `test/widget_test.dart` is also compared
  /// with [defaultWidgetTest], including the version older Flutter releases
  /// wrote (`MyApp()` without `const`). Line endings and trailing whitespace
  /// are ignored.
  static bool isUnmodified(
    String relativePath,
    String content,
    String projectName, {
    String? flutterRoot,
  }) {
    final candidates = <String?>[
      if (relativePath == 'test/widget_test.dart') ...[
        defaultWidgetTest(projectName),
        defaultWidgetTest(projectName).replaceFirst('const MyApp()', 'MyApp()'),
        _renderSdkTemplate(
          flutterRoot,
          'app_test_widget/test/widget_test.dart.tmpl',
          projectName,
        ),
      ],
      if (relativePath == 'lib/main.dart')
        for (final empty in [false, true])
          _renderSdkTemplate(
            flutterRoot,
            'app/lib/main.dart.tmpl',
            projectName,
            sections: {'withEmptyMain': empty},
          ),
    ];
    final actual = _normalize(content);
    return candidates.any((c) => c != null && _normalize(c) == actual);
  }

  static String _normalize(String content) =>
      content.replaceAll('\r\n', '\n').trimRight();

  static String? _renderSdkTemplate(
    String? flutterRoot,
    String template,
    String projectName, {
    Map<String, bool> sections = const {},
  }) {
    if (flutterRoot == null) return null;
    final file = File(
      p.joinAll([
        flutterRoot,
        'packages',
        'flutter_tools',
        'templates',
        ...template.split('/'),
      ]),
    );
    if (!file.existsSync()) return null;
    return render(
      file.readAsStringSync(),
      sections: sections,
      values: {'projectName': projectName},
    );
  }

  static final RegExp _sectionTag =
      RegExp(r'^\s*\{\{([#^/])\s*([\w.]+)\s*\}\}\s*$');

  /// Renders a `flutter_tools` Mustache template for an app: sections not in
  /// [sections] are off (plugin and FFI variants), `{{name}}` is replaced
  /// with [values].
  ///
  /// Returns `null` for templates this simple renderer cannot handle
  /// (section tags inside a line, unknown variables in the output), so
  /// they are never mistaken for a match.
  static String? render(
    String template, {
    Map<String, bool> sections = const {},
    Map<String, String> values = const {},
  }) {
    final output = StringBuffer();
    // Whether each open section is rendered.
    final open = <({String name, bool on})>[];
    for (final line in template.split('\n')) {
      final tag = _sectionTag.firstMatch(line);
      if (tag != null) {
        final name = tag[2]!;
        if (tag[1] == '/') {
          if (open.isEmpty || open.last.name != name) return null;
          open.removeLast();
        } else {
          final value = sections[name] ?? false;
          open.add((name: name, on: tag[1] == '#' ? value : !value));
        }
        continue;
      }
      if (open.any((section) => !section.on)) continue;
      var rendered = line;
      values.forEach((key, value) {
        rendered = rendered.replaceAll('{{$key}}', value);
      });
      if (rendered.contains('{{')) return null;
      output.writeln(rendered);
    }
    if (open.isNotEmpty) return null;
    // Every line got a '\n'; the template's own line breaks are one fewer.
    final result = output.toString();
    return result.substring(0, result.length - 1);
  }
}
