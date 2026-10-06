import 'dart:io';

import 'package:flutter_project_builder/src/utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('dryRun records writes without touching the disk', () async {
    final project = createProject();
    final existing = p.join(project.path, 'pubspec.yaml');
    final same = p.join(project.path, 'same.txt');
    File(same).writeAsStringSync('same');
    final created = p.join(project.path, 'lib', 'new.dart');

    final recorder = await FileUtils.dryRun(() async {
      FileUtils.createFile(existing, 'changed');
      FileUtils.createFile(same, 'same');
      FileUtils.createFile(created, 'new');
      // Reads inside the dry run see pending writes.
      expect(FileUtils.readFile(created), 'new');
      expect(FileUtils.fileExists(created), isTrue);
      expect(FileUtils.directoryExists(p.join(project.path, 'lib')), isTrue);
      expect(FileUtils.isDryRun, isTrue);
    });

    expect(File(created).existsSync(), isFalse);
    expect(readFile(project, 'pubspec.yaml'), flutterPubspec);
    expect(recorder.changes(), {
      p.normalize(existing): FileChange.overwrite,
      p.normalize(same): FileChange.unchanged,
      p.normalize(created): FileChange.create,
    });
    expect(FileUtils.isDryRun, isFalse);
  });

  test('createFileIfAbsent never overwrites', () {
    final project = createProject();
    final path = p.join(project.path, 'a.txt');
    expect(FileUtils.createFileIfAbsent(path, 'one'), isTrue);
    expect(FileUtils.createFileIfAbsent(path, 'two'), isFalse);
    expect(File(path).readAsStringSync(), 'one');
  });
}
