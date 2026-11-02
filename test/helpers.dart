import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A minimal pubspec equivalent to the one produced by `flutter create`.
const String flutterPubspec = '''
name: my_app
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
''';

/// Creates a temporary Flutter-like project and deletes it after the test.
Directory createProject({
  String pubspec = flutterPubspec,
  String dirName = 'project',
}) {
  final root = Directory.systemTemp.createTempSync('fpb_test_');
  addTearDown(() => root.deleteSync(recursive: true));
  final project = Directory(p.join(root.path, dirName))..createSync();
  File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync(pubspec);
  return project;
}

/// Runs the CLI in [project] and returns the exit code.
/// `flutter` calls (e.g. `pub get`) succeed without doing anything.
Future<int> runCli(Directory project, List<String> args) =>
    FlutterProjectBuilderCommandRunner(
      logger: CliLogger(useColors: false),
      workingDirectory: project.path,
      flutter: FlutterCli(
        runner: (executable, arguments, {workingDirectory}) async =>
            ProcessResult(0, 0, '', ''),
      ),
    ).run(args);

/// Reads a project file relative to [project].
String readFile(Directory project, String relativePath) =>
    File(p.join(project.path, relativePath)).readAsStringSync();

/// Whether a project file exists relative to [project].
bool exists(Directory project, String relativePath) =>
    FileSystemEntity.typeSync(p.join(project.path, relativePath)) !=
    FileSystemEntityType.notFound;
