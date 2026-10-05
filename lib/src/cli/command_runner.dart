import 'dart:io';

import 'package:args/command_runner.dart';

import '../config/constants.dart';
import 'cli_logger.dart';
import 'commands/clean_command.dart';
import 'commands/create_command.dart';
import 'commands/doctor_command.dart';
import 'commands/generate_command.dart';
import 'commands/init_command.dart';
import 'commands/upgrade_command.dart';

/// Main entry point for the flutter_project_builder CLI.
///
/// Registers all subcommands and handles global flags like `--version`
/// and `--verbose`.
///
/// ```dart
/// final exitCode = await FlutterProjectBuilderCommandRunner()
///     .run(['generate', 'feature', 'auth']);
/// ```
class FlutterProjectBuilderCommandRunner extends CommandRunner<int> {
  /// Creates a new [FlutterProjectBuilderCommandRunner].
  ///
  /// Commands operate on [workingDirectory], which defaults to the current
  /// directory of the process.
  FlutterProjectBuilderCommandRunner({
    CliLogger? logger,
    String? workingDirectory,
  })  : _logger = logger ?? CliLogger(),
        super(
          PackageConstants.packageName,
          PackageConstants.description,
        ) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        help: 'Enable verbose logging (including stack traces).',
        negatable: false,
      );

    String cwd() => workingDirectory ?? Directory.current.path;

    addCommand(CreateCommand(logger: _logger, workingDirectory: cwd));
    addCommand(DoctorCommand(logger: _logger, workingDirectory: cwd));
    addCommand(CleanCommand(logger: _logger, workingDirectory: cwd));
    addCommand(UpgradeCommand(logger: _logger, workingDirectory: cwd));
    addCommand(InitCommand(logger: _logger, workingDirectory: cwd));
    addCommand(GenerateCommand(logger: _logger, workingDirectory: cwd));
  }

  final CliLogger _logger;

  /// Runs the CLI with [args] and returns the process exit code.
  ///
  /// Never throws: usage errors and unexpected failures are reported through
  /// the logger and result in a non-zero exit code.
  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);

      if (topLevelResults.flag('verbose')) {
        _logger.verbose = true;
      }

      if (topLevelResults.flag('version')) {
        _logger.info(PackageConstants.version);
        return 0;
      }

      if (topLevelResults.command == null && topLevelResults.rest.isNotEmpty) {
        throw UsageException(
          'Could not find a command named "${topLevelResults.rest.first}".',
          usage,
        );
      }

      // Default to help if no command is provided.
      if (topLevelResults.command == null) {
        _logger.header(
          'flutter_project_builder',
          subtitle: 'v${PackageConstants.version}',
        );
        printUsage();
        return 0;
      }

      final exitCode = await runCommand(topLevelResults);
      return exitCode ?? 0;
    } on UsageException catch (e) {
      _logger
        ..error(e.message)
        ..info('\n${e.usage}');
      return 1;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..error(e.message)
        ..trace('$stackTrace');
      return 1;
    } catch (e, stackTrace) {
      _logger
        ..error('An unexpected error occurred: $e')
        ..trace('$stackTrace');
      return 1;
    }
  }
}
