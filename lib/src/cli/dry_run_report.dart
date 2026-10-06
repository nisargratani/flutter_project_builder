import 'package:path/path.dart' as p;

import '../utils/file_utils.dart';
import 'cli_logger.dart';

/// Prints what a dry run would change, grouped by kind of change.
void printDryRun(CliLogger logger, DryRunRecorder recorder, String root) {
  final changes = recorder.changes();
  String relative(String path) => p.relative(path, from: root);

  final groups = {
    'Would overwrite': FileChange.overwrite,
    'Would create': FileChange.create,
  };
  logger.section('Dry run (nothing was written)');
  for (final MapEntry(key: title, value: kind) in groups.entries) {
    final paths = [
      for (final entry in changes.entries)
        if (entry.value == kind) relative(entry.key),
    ]..sort();
    if (paths.isEmpty) continue;
    logger.write('  ${logger.bold('$title (${paths.length}):')}');
    for (final path in paths) {
      final line = kind == FileChange.overwrite
          ? logger.yellow(path)
          : logger.green(path);
      logger.write('    $line');
    }
    logger.newLine();
  }
  final unchanged =
      changes.values.where((change) => change == FileChange.unchanged).length;
  if (unchanged > 0) logger.info('$unchanged file(s) would stay unchanged.');
  if (changes.isEmpty) logger.info('No files would change.');
}
