// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'package:args/command_runner.dart';

import '../../flutter_project_builder.dart';
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
class FlutterProjectBuilderCommandRunner extends CommandRunner<int> {
  /// Creates a new [FlutterProjectBuilderCommandRunner].
  FlutterProjectBuilderCommandRunner({
    CliLogger? logger,
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
        help: 'Enable verbose logging.',
        negatable: false,
      );

    addCommand(CreateCommand(logger: _logger));
    addCommand(DoctorCommand(logger: _logger));
    addCommand(CleanCommand(logger: _logger));
    addCommand(UpgradeCommand(logger: _logger));
    addCommand(InitCommand(logger: _logger));
    addCommand(GenerateCommand(logger: _logger));
  }

  final CliLogger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);

      if (topLevelResults.flag('verbose')) {
        // We could enable verbose mode on the logger here if implemented.
      }

      if (topLevelResults.flag('version')) {
        _logger.info(PackageConstants.version);
        return 0;
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
    } on FormatException catch (e, stackTrace) {
      _logger.error(e.message);
      _logger.detail('\n$stackTrace');
      _logger.info('\nUsage:');
      printUsage();
      return 1;
    } on UsageException catch (e) {
      _logger.error(e.message);
      _logger.info('\n${e.usage}');
      return 1;
    } catch (e, stackTrace) {
      _logger.error('An unexpected error occurred: $e');
      _logger.detail('\n$stackTrace');
      return 1;
    }
  }
}
