import 'dart:io';

/// Runs an executable; matches the signature of [Process.run] that
/// [FlutterCli] needs. Replace it in tests to avoid calling the real SDK.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
});

/// Thin wrapper around the `flutter` command-line tool.
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
}
