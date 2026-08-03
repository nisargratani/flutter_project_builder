// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for tests.
class TestTemplate {
  TestTemplate._();

  static const String widgetTest = '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_name/core/widgets/app_button.dart'; // Ensure correct import path

void main() {
  testWidgets('AppButton displays text and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Click Me',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
    
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
''';
}
