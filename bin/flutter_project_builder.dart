import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';

/// Entry point for the flutter_project_builder CLI.
///
/// This executable delegates all command processing to
/// [FlutterProjectBuilderCommandRunner].
Future<void> main(List<String> arguments) async {
  final exitCode = await FlutterProjectBuilderCommandRunner().run(arguments);
  exit(exitCode);
}
