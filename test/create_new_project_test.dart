import 'dart:io';

import 'package:flutter_project_builder/flutter_project_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

/// Records `flutter` invocations; `flutter create` writes a minimal project.
class FakeFlutter {
  final List<List<String>> calls = [];
  int createExitCode = 0;
  bool missing = false;

  FlutterCli get cli => FlutterCli(runner: _run);

  Future<ProcessResult> _run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    if (missing) throw const ProcessException('flutter', []);
    calls.add(arguments);
    if (arguments.first == 'create') {
      if (createExitCode != 0) {
        return ProcessResult(0, createExitCode, '', 'boom');
      }
      final name = arguments[arguments.indexOf('--project-name') + 1];
      final dir = Directory(arguments.last)..createSync(recursive: true);
      File(p.join(dir.path, 'pubspec.yaml'))
          .writeAsStringSync(flutterPubspec.replaceFirst('my_app', name));
    }
    return ProcessResult(0, 0, '', '');
  }
}

void main() {
  late Directory root;
  late FakeFlutter flutter;

  setUp(() {
    root = Directory.systemTemp.createTempSync('fpb_new_');
    addTearDown(() => root.deleteSync(recursive: true));
    flutter = FakeFlutter();
  });

  Future<int> run(List<String> args) => FlutterProjectBuilderCommandRunner(
        logger: CliLogger(useColors: false),
        workingDirectory: root.path,
        flutter: flutter.cli,
      ).run(args);

  Directory project(String name) => Directory(p.join(root.path, name));

  test('creates the Flutter project, generates and runs pub get', () async {
    final code = await run([
      'create',
      'my_shop',
      '--org=com.acme',
      '--platforms=android,ios',
      '--no-interactive',
    ]);

    expect(code, 0);
    expect(flutter.calls.first, [
      'create',
      '--no-pub',
      '--project-name',
      'my_shop',
      '--org',
      'com.acme',
      '--platforms=android,ios',
      p.join(root.path, 'my_shop'),
    ]);
    expect(flutter.calls.last, ['pub', 'get']);
    expect(exists(project('my_shop'), 'lib/app.dart'), isTrue);
    expect(
      ProjectConfig.fromDirectory(project('my_shop').path).organization,
      'com.acme',
    );
  });

  test('--project-name, default org and --no-pub', () async {
    expect(
      await run(['create', 'shop-app', '--project-name=shop', '--no-pub']),
      0,
    );
    final create = flutter.calls.single;
    expect(create, containsAllInOrder(['--project-name', 'shop']));
    expect(create, isNot(contains('--org')));
    final pubspec = readFile(project('shop-app'), 'pubspec.yaml');
    expect(pubspec, contains('name: shop'));
  });

  test('fills an empty existing directory', () async {
    project('empty').createSync();
    expect(await run(['create', 'empty', '--no-pub']), 0);
    expect(flutter.calls.single.first, 'create');
    expect(exists(project('empty'), 'lib/main.dart'), isTrue);
  });

  test('generates inside an existing Flutter project without flutter create',
      () async {
    final existing = project('existing')..createSync();
    File(p.join(existing.path, 'pubspec.yaml'))
        .writeAsStringSync(flutterPubspec);

    expect(await run(['create', 'existing']), 0);
    expect(flutter.calls, isEmpty, reason: 'no create, and pub get is opt-in');
    expect(exists(existing, 'lib/app.dart'), isTrue);

    expect(await run(['create', 'existing', '--force', '--pub']), 0);
    expect(flutter.calls.single, ['pub', 'get']);
  });

  test('native flavors: pub get runs, then the native setup is reapplied',
      () async {
    final existing = project('flavored')..createSync();
    File(p.join(existing.path, 'pubspec.yaml'))
        .writeAsStringSync(flutterPubspec);

    expect(await run(['create', 'flavored', '--template=enterprise']), 0);
    expect(flutter.calls, [
      ['pub', 'get'],
    ]);
    expect(readFile(existing, 'pubspec.yaml'), contains('default-flavor: dev'));
  });

  test('rejects invalid names and non-Flutter directories', () async {
    expect(await run(['create', 'My-App']), 1);
    expect(await run(['create', 'class']), 1);

    final notes = project('notes')..createSync();
    File(p.join(notes.path, 'readme.txt')).writeAsStringSync('hi');
    expect(await run(['create', 'notes']), 1);
    expect(notes.listSync(), hasLength(1));

    expect(await run(['create', 'a', 'b']), 1);
    expect(flutter.calls, isEmpty);
  });

  test('reports flutter failures without generating', () async {
    flutter.createExitCode = 1;
    expect(await run(['create', 'broken']), 1);
    expect(exists(project('broken'), 'lib'), isFalse);

    flutter
      ..createExitCode = 0
      ..missing = true;
    expect(await run(['create', 'no_sdk']), 1);
  });

  test('--dry-run does not run flutter create', () async {
    expect(await run(['create', 'preview', '--dry-run']), 0);
    expect(flutter.calls, isEmpty);
    expect(project('preview').existsSync(), isFalse);
  });

  test('createArguments builds the flutter create command', () {
    expect(
      FlutterCli.createArguments('app', projectName: 'app'),
      ['create', '--no-pub', '--project-name', 'app', 'app'],
    );
  });
}
