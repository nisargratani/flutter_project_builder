import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// What a dry run would do to one file.
enum FileChange {
  /// The file does not exist yet.
  create,

  /// The file exists and its content would change.
  overwrite,

  /// The file exists with identical content.
  unchanged,
}

/// Records the writes made inside [FileUtils.dryRun] instead of performing
/// them.
class DryRunRecorder {
  final Map<String, String> _writes = {};

  /// Pending file contents keyed by absolute path, in write order.
  Map<String, String> get writes => Map.unmodifiable(_writes);

  /// Classifies every recorded write against the file system.
  Map<String, FileChange> changes() => {
        for (final entry in _writes.entries)
          entry.key: switch (File(entry.key)) {
            final file when !file.existsSync() => FileChange.create,
            final file when file.readAsStringSync() == entry.value =>
              FileChange.unchanged,
            _ => FileChange.overwrite,
          },
      };
}

/// File system utilities for creating directories and writing files.
///
/// All generators write through this class, so wrapping them in [dryRun]
/// previews every change without touching the disk.
class FileUtils {
  FileUtils._();

  static const Symbol _recorderKey = #flutterProjectBuilderDryRun;

  static DryRunRecorder? get _recorder =>
      Zone.current[_recorderKey] as DryRunRecorder?;

  /// Whether the current code runs inside [dryRun].
  static bool get isDryRun => _recorder != null;

  /// Runs [body] without writing to disk and returns what it would write.
  ///
  /// Reads inside [body] see the pending writes, so later steps behave as if
  /// earlier steps had run.
  static Future<DryRunRecorder> dryRun(Future<void> Function() body) async {
    final recorder = DryRunRecorder();
    await runZoned(body, zoneValues: {_recorderKey: recorder});
    return recorder;
  }

  /// Creates a file at [filePath] with the given [content].
  ///
  /// Creates parent directories if they do not exist.
  /// Will overwrite existing files.
  static void createFile(String filePath, String content) {
    final recorder = _recorder;
    if (recorder != null) {
      recorder._writes[p.normalize(p.absolute(filePath))] = content;
      return;
    }
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  /// Creates a file at [filePath] with [content] only if no file exists
  /// there yet.
  ///
  /// Returns `true` if the file was written.
  static bool createFileIfAbsent(String filePath, String content) {
    if (fileExists(filePath)) return false;
    createFile(filePath, content);
    return true;
  }

  /// Creates a directory at [dirPath] if it does not exist.
  static void createDirectory(String dirPath) {
    if (isDryRun) return;
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Checks if a file exists at [filePath] (including pending dry-run
  /// writes).
  static bool fileExists(String filePath) =>
      (_recorder?._writes.containsKey(p.normalize(p.absolute(filePath))) ??
          false) ||
      File(filePath).existsSync();

  /// Checks if a directory exists at [dirPath] (including directories that
  /// pending dry-run writes would create).
  static bool directoryExists(String dirPath) {
    final recorder = _recorder;
    if (recorder != null) {
      final dir = p.normalize(p.absolute(dirPath));
      if (recorder._writes.keys.any((path) => p.isWithin(dir, path))) {
        return true;
      }
    }
    return Directory(dirPath).existsSync();
  }

  /// Returns the absolute path by joining [base] and [relative].
  static String joinPath(String base, String relative) =>
      p.join(base, relative);

  /// Deletes a file at [filePath] if it exists.
  static void deleteFile(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// Deletes a directory at [dirPath] recursively if it exists.
  static void deleteDirectory(String dirPath) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  /// Lists all files in [dirPath] recursively.
  static List<String> listFiles(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .toList();
  }

  /// Reads the content of a file at [filePath] (including pending dry-run
  /// writes).
  ///
  /// Returns `null` if the file does not exist.
  static String? readFile(String filePath) {
    final pending = _recorder?._writes[p.normalize(p.absolute(filePath))];
    if (pending != null) return pending;
    final file = File(filePath);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  /// Creates a `.gitkeep` file in an empty directory.
  static void createGitKeep(String dirPath) {
    createDirectory(dirPath);
    createFile(p.join(dirPath, '.gitkeep'), '');
  }
}
