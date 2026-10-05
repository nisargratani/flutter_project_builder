import 'dart:io';

import 'package:path/path.dart' as p;

/// File system utilities for creating directories and writing files.
///
/// Provides safe file operations with directory creation, overwrite
/// protection, and path normalization.
class FileUtils {
  FileUtils._();

  /// Creates a file at [filePath] with the given [content].
  ///
  /// Creates parent directories if they do not exist.
  /// Will overwrite existing files.
  static void createFile(String filePath, String content) {
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
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  /// Checks if a file exists at [filePath].
  static bool fileExists(String filePath) => File(filePath).existsSync();

  /// Checks if a directory exists at [dirPath].
  static bool directoryExists(String dirPath) =>
      Directory(dirPath).existsSync();

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

  /// Reads the content of a file at [filePath].
  ///
  /// Returns `null` if the file does not exist.
  static String? readFile(String filePath) {
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
