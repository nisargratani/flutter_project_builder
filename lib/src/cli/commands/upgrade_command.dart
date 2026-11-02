import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/project_config.dart';
import '../../generators/project_generator.dart';
import '../../utils/file_utils.dart';
import '../../utils/flutter_cli.dart';
import '../../utils/native_project.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';
import '../dry_run_report.dart';

/// Command to upgrade existing generated architecture.
///
/// Regenerates `lib/core/` (and adds missing dependencies) using the options
/// in `flutter_project_builder.yaml`. Features, routing, entry points and
/// tests are not touched. With native flavors, missing flavor
/// configurations and Podfile mappings are added (existing ones are kept).
/// Flavors that are configured but missing on the Dart side are reported.
class UpgradeCommand extends Command<int> {
  /// Creates a new [UpgradeCommand].
  ///
  /// [flutter] runs `dart format` on the regenerated files.
  UpgradeCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
    FlutterCli? flutter,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path),
        _flutter = flutter ?? FlutterCli() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Upgrade without prompting, even if no generation marker '
            'exists.',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'List the files that would be overwritten, without writing '
            'anything.',
        negatable: false,
      );
  }

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Regenerate lib/core with the latest templates.';

  final CliLogger _logger;
  final String Function() _workingDirectory;
  final FlutterCli _flutter;

  @override
  Future<int> run() async {
    final currentDir = _workingDirectory();

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    final force = argResults!.flag('force');
    final config = ProjectConfig.fromDirectory(currentDir);

    final generator = ProjectGenerator(
      projectPath: currentDir,
      config: config,
      logger: _logger,
    );

    if (argResults!.flag('dry-run')) {
      final recorder = await FileUtils.dryRun(
        () => generator.generate(upgradeMode: true),
      );
      printDryRun(_logger, recorder, currentDir);
      generator.warnings.forEach(_logger.warning);
      return 0;
    }

    if (!force) {
      if (!ProjectGenerator.isGenerated(currentDir)) {
        _logger
          ..error('No generated architecture found. '
              'Run `flutter_project_builder create` first.')
          ..info('Pass --force to generate lib/core anyway.');
        return 1;
      }
      if (!stdin.hasTerminal) {
        _logger.error(
          'Refusing to overwrite files without confirmation. '
          'Re-run with --force in non-interactive environments.',
        );
        return 1;
      }
      _logger.warning('This will overwrite existing files in lib/core.');
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
      await generator.generate(upgradeMode: true);
      generator.warnings.forEach(_logger.warning);
      await _flutter.formatDart(currentDir, generator.writtenFiles);

      if (config.hasNativeFlavors) {
        // Adds flavors that are new in the config, and maps flavors in a
        // Podfile that Flutter created after `create` ran. Idempotent.
        final native = NativeProject(
          projectPath: currentDir,
          packageName:
              PubspecUtils.getProjectName(currentDir) ?? p.basename(currentDir),
        );
        for (final warning
            in native.configureFlavors(config.flavors).warnings) {
          _logger.warning(warning);
        }
      }

      missingDartFlavors(currentDir, config).forEach(_logger.warning);
      _logger.success('Architecture upgraded successfully.');
      return 0;
    } catch (e, st) {
      _logger
        ..error('Upgrade failed: $e')
        ..trace(st.toString());
      return 1;
    }
  }

  /// Warnings for the configured flavors that the Dart side does not know:
  /// missing from `enum Flavor` in `lib/core/config/flavor_config.dart`, or
  /// without a `lib/main_<flavor>.dart` entry point.
  ///
  /// `upgrade` keeps `flavor_config.dart` because it holds your URLs, but
  /// `FlavorConfig.fromName` falls back to the first flavor for unknown
  /// names, so `--flavor <new>` would silently run with that configuration.
  static List<String> missingDartFlavors(
    String projectPath,
    ProjectConfig config,
  ) {
    if (!config.hasFlavors) return const [];
    const flavorConfig = 'lib/core/config/flavor_config.dart';
    final content =
        (FileUtils.readFile(p.join(projectPath, flavorConfig)) ?? '')
            .replaceAll(RegExp(r'//[^\n]*|/\*.*?\*/', dotAll: true), '');
    // The values of `enum Flavor { dev, prod }`; an enhanced enum lists
    // them before its first `;`.
    final values =
        RegExp(r'enum\s+Flavor\s*\{([^};]*)').firstMatch(content)?[1];
    final declared = {
      for (final value in values?.split(',') ?? const <String>[])
        if (RegExp(r'^\s*([a-z]\w*)').firstMatch(value)?[1] case final name?)
          name,
    };
    // `FlavorConfig.fromName` falls back to the first enum value.
    final fallback = declared.firstOrNull ?? config.flavors.first;
    return [
      for (final flavor in config.flavors)
        if (!declared.contains(flavor) ||
            !FileUtils.fileExists(
              p.join(projectPath, 'lib', 'main_$flavor.dart'),
            ))
          'Flavor "$flavor" is not set up in Dart yet. Add `$flavor` to '
              '`enum Flavor` and a `Flavor.$flavor => AppConfig(...)` case in '
              '$flavorConfig, and create lib/main_$flavor.dart (copy another '
              'main_<flavor>.dart). Until then `--flavor $flavor` runs with '
              'the $fallback configuration.',
    ];
  }
}
