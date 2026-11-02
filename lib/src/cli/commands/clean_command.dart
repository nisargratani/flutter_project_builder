import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/constants.dart';
import '../../generators/project_generator.dart';
import '../../utils/file_utils.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to clean generated architecture files.
///
/// Deletes only the files listed in the generation marker
/// `lib/.flutter_project_builder` (the code `create`, `upgrade` and
/// `generate` wrote under `lib/` and `test/`), then the marker and the
/// folders left empty. Files you added are kept, even inside generated
/// folders. `lib/main.dart`, `pubspec.yaml`, localization files
/// (`l10n.yaml`, `lib/l10n/`), `lib/firebase_options.dart` and native
/// project changes are never deleted.
class CleanCommand extends Command<int> {
  /// Creates a new [CleanCommand].
  CleanCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Delete without prompting (required in non-interactive '
          'environments).',
      negatable: false,
    );
  }

  @override
  String get name => 'clean';

  @override
  String get description =>
      'Remove the files flutter_project_builder generated.';

  /// How many kept files are listed before the rest is summarised.
  static const int _maxListedKeptFiles = 20;

  final CliLogger _logger;
  final String Function() _workingDirectory;

  @override
  Future<int> run() async {
    final currentDir = _workingDirectory();
    const marker = 'lib/${PackageConstants.generatedMarkerFile}';

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    if (!ProjectGenerator.isGenerated(currentDir)) {
      _logger
        ..error('No generated architecture found ($marker is missing).')
        ..info('`clean` only deletes the files listed in $marker, so there '
            'is nothing to delete.');
      return 1;
    }

    final listed = ProjectGenerator.generatedFiles(currentDir);
    if (listed == null) {
      _logger
        ..error('$marker was written by flutter_project_builder 0.0.1 and '
            'does not list the generated files, so `clean` cannot tell them '
            'apart from yours. Nothing was deleted.')
        ..info('Delete the generated files yourself. Projects set up with '
            'flutter_project_builder 0.1.0 or newer list them in $marker.');
      return 1;
    }
    final generated = listed.where(ProjectGenerator.isCleanable).toList();

    if (!argResults!.flag('force')) {
      if (!stdin.hasTerminal) {
        _logger.error(
          'Refusing to delete files without confirmation. '
          'Re-run with --force in non-interactive environments.',
        );
        return 1;
      }
      _logger.warning(
        'This will delete the ${generated.length} files listed in $marker '
        '(generated code in lib/ and test/). Files you added are kept.',
      );
      stdout.write('Are you sure you want to proceed? (y/N): ');
      final input = stdin.readLineSync()?.trim().toLowerCase();
      if (input == null) {
        // stdin is at end of file (e.g. `< /dev/null` in CI), which Dart
        // reports as a terminal: no answer is not a "no".
        _logger.error(
          '\nNo answer (stdin is closed). '
          'Re-run with --force in non-interactive environments.',
        );
        return 1;
      }
      if (input != 'y' && input != 'yes') {
        _logger.info('Aborted.');
        return 0;
      }
    }

    try {
      _logger
        ..startProgress(total: 2)
        ..step('Deleting ${generated.length} generated files...');
      final folders = <String>{};
      for (final relative in generated) {
        final path = p.joinAll([currentDir, ...relative.split('/')]);
        if (!File(path).existsSync()) continue;
        File(path).deleteSync();
        folders.add(p.dirname(path));
      }
      FileUtils.deleteFile(ProjectGenerator.markerPath(currentDir));

      _logger.step('Removing empty folders...');
      final roots = [p.join(currentDir, 'lib'), p.join(currentDir, 'test')];
      for (final folder in folders) {
        _deleteEmptyFolders(folder, roots);
      }
      _logger.completeProgress();

      _reportKeptFiles(currentDir, generated);
      _logger
        ..info(
          'lib/main.dart still calls bootstrap(); restore it or run '
          '`flutter_project_builder create` again.',
        )
        ..info(
          'Native changes (app IDs, Android flavors, Xcode schemes) and '
          'lib/firebase_options.dart were kept; revert them with git if '
          'needed.',
        );
      return 0;
    } on FileSystemException catch (e) {
      _logger.error('Clean failed: ${e.message} (${e.path})');
      return 1;
    }
  }

  /// Deletes [folder] and then its parents while they are empty, stopping
  /// at (and never deleting) the [roots]. A lone `.DS_Store` counts as
  /// empty.
  static void _deleteEmptyFolders(String folder, List<String> roots) {
    var dir = Directory(folder);
    while (
        roots.any((root) => p.isWithin(root, dir.path)) && dir.existsSync()) {
      final entries = dir.listSync();
      if (entries.any((e) => p.basename(e.path) != '.DS_Store')) return;
      dir.deleteSync(recursive: true);
      dir = dir.parent;
    }
  }

  /// Lists the files left in the folders `clean` deleted from (for example
  /// your own code in `lib/features/`), so it is clear they were kept.
  void _reportKeptFiles(String projectPath, List<String> generated) {
    // Top-level generated folders such as lib/core, lib/features, test/core.
    final folders = {
      for (final relative in generated)
        if (relative.split('/').length > 2)
          relative.split('/').take(2).join('/'),
    };
    final kept = [
      for (final folder in folders)
        for (final path in FileUtils.listFiles(
          p.joinAll([projectPath, ...folder.split('/')]),
        ))
          if (p.basename(path) != '.DS_Store')
            p.split(p.relative(path, from: projectPath)).join('/'),
    ]..sort();
    if (kept.isEmpty) return;
    _logger.info(
      'Kept ${kept.length} file(s) that flutter_project_builder did not '
      'generate:',
    );
    kept.take(_maxListedKeptFiles).forEach(_logger.detail);
    if (kept.length > _maxListedKeptFiles) {
      _logger.detail('... and ${kept.length - _maxListedKeptFiles} more');
    }
  }
}
