import 'dart:async';
import 'dart:convert';
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

/// Every file below [project] (relative path → content), to check that a
/// command wrote nothing.
Map<String, String> snapshot(Directory project) => {
      for (final file in project.listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: project.path): file.readAsStringSync(),
    };

/// Copies the real `flutter create` platform files from test/fixtures into a
/// new project.
Directory nativeProject() {
  final project = createProject();
  final fixtures = Directory(p.join('test', 'fixtures', 'native'));
  for (final file in fixtures.listSync(recursive: true).whereType<File>()) {
    final target = File(
      p.join(project.path, p.relative(file.path, from: fixtures.path)),
    );
    target.parent.createSync(recursive: true);
    file.copySync(target.path);
  }
  return project;
}

/// Writes [content] to [relativePath] in [project], creating folders.
void writeFile(Directory project, String relativePath, String content) =>
    File(p.join(project.path, relativePath))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);

/// The result of [runCliCaptured].
class CliRun {
  CliRun(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;

  /// stdout and stderr together.
  String get output => '$stdout$stderr';

  @override
  String toString() => 'exit $exitCode\n$output';
}

/// Like [runCli], but captures stdout/stderr. Without [stdinLines] stdin is
/// not a terminal (like CI); with them it is a terminal that answers each
/// prompt with the next line, then reports end of file (`null`).
Future<CliRun> runCliCaptured(
  Directory project,
  List<String> args, {
  List<String?>? stdinLines,
  ProcessRunner? runner,
}) async {
  // In-memory buffers; there is nothing to close.
  // ignore: close_sinks
  final out = _CapturedOutput();
  // ignore: close_sinks
  final err = _CapturedOutput();
  final code = await IOOverrides.runZoned(
    () => FlutterProjectBuilderCommandRunner(
      logger: CliLogger(useColors: false),
      workingDirectory: project.path,
      flutter: FlutterCli(
        runner: runner ??
            (executable, arguments, {workingDirectory}) async =>
                ProcessResult(0, 0, '', ''),
      ),
    ).run(args),
    stdout: () => out,
    stderr: () => err,
    stdin: () => _FakeStdin(stdinLines),
  );
  return CliRun(code, '${out.buffer}', '${err.buffer}');
}

class _CapturedOutput implements Stdout {
  final StringBuffer buffer = StringBuffer();

  @override
  bool get hasTerminal => false;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  void write(Object? object) => buffer.write(object);

  @override
  void writeln([Object? object = '']) => buffer.writeln(object);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStdin extends Stream<List<int>> implements Stdin {
  _FakeStdin(List<String?>? lines)
      : _lines = [...?lines],
        hasTerminal = lines != null;

  final List<String?> _lines;

  @override
  final bool hasTerminal;

  @override
  String? readLineSync({
    Encoding encoding = systemEncoding,
    bool retainNewlines = false,
  }) =>
      _lines.isEmpty ? null : _lines.removeAt(0);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      const Stream<List<int>>.empty().listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
