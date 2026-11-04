import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs an executable; matches the signature of [Process.run] that
/// [FlutterCli] needs. Replace it in tests to avoid calling the real SDK.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
});

/// Thin wrapper around the `flutter` and `dart` command-line tools.
class FlutterCli {
  /// Creates a wrapper that runs `flutter` through [runner] (defaults to
  /// [Process.run]).
  FlutterCli({ProcessRunner? runner}) : _run = runner ?? _processRun;

  final ProcessRunner _run;

  /// Platforms accepted by `flutter create --platforms`.
  static const List<String> platforms = [
    'android',
    'ios',
    'linux',
    'macos',
    'web',
    'windows',
  ];

  static Future<ProcessResult> _processRun(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) =>
      Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        // `flutter` is a batch script on Windows and needs a shell.
        runInShell: Platform.isWindows,
      );

  /// The arguments [create] passes to `flutter create`.
  static List<String> createArguments(
    String directory, {
    required String projectName,
    String? organization,
    List<String> platforms = const [],
  }) =>
      [
        'create',
        '--no-pub',
        '--project-name',
        projectName,
        if (organization != null) ...['--org', organization],
        if (platforms.isNotEmpty) '--platforms=${platforms.join(',')}',
        directory,
      ];

  /// Runs `flutter create` for a new app in [directory].
  ///
  /// `pub get` is skipped because dependencies are added afterwards.
  /// Throws a [ProcessException] if `flutter` cannot be started.
  Future<ProcessResult> create(
    String directory, {
    required String projectName,
    String? organization,
    List<String> platforms = const [],
  }) =>
      _run(
        'flutter',
        createArguments(
          directory,
          projectName: projectName,
          organization: organization,
          platforms: platforms,
        ),
      );

  /// Runs `flutter pub get` in [directory].
  ///
  /// Throws a [ProcessException] if `flutter` cannot be started.
  Future<ProcessResult> pubGet(String directory) =>
      _run('flutter', ['pub', 'get'], workingDirectory: directory);

  /// Formats the existing `.dart` files among [paths] (absolute, inside
  /// [projectPath]) with `dart format`, so generated code passes
  /// `dart format --set-exit-if-changed`.
  ///
  /// Runs in [projectPath] after `flutter pub get` where possible, so the
  /// formatter uses the project's language version. Formatting is cosmetic:
  /// if `dart` cannot be run or fails, the files are left as they are.
  Future<void> formatDart(String projectPath, Iterable<String> paths) async {
    final files = [
      for (final path in paths)
        if (path.endsWith('.dart') && File(path).existsSync())
          p.relative(path, from: projectPath),
    ]..sort();
    try {
      // Batches keep the command line short (Windows runs it in a shell).
      for (var i = 0; i < files.length; i += 50) {
        await _run(
          'dart',
          ['format', ...files.skip(i).take(50)],
          workingDirectory: projectPath,
        );
      }
    } on ProcessException {
      // `dart` is not on the PATH; keep the unformatted files.
    }
  }
}
