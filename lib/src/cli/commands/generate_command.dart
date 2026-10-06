import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/project_config.dart';
import '../../generators/feature_generator.dart';
import '../../generators/model_field.dart';
import '../../utils/file_utils.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';
import '../dry_run_report.dart';

/// Command to scaffold features and their building blocks.
class GenerateCommand extends Command<int> {
  /// Creates a new [GenerateCommand].
  GenerateCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  }) {
    final cwd = workingDirectory ?? (() => Directory.current.path);
    addSubcommand(
      GenerateFeatureCommand(logger: logger, workingDirectory: cwd),
    );
    addSubcommand(GeneratePageCommand(logger: logger, workingDirectory: cwd));
    addSubcommand(GenerateWidgetCommand(logger: logger, workingDirectory: cwd));
    addSubcommand(
      GenerateProviderCommand(logger: logger, workingDirectory: cwd),
    );
    addSubcommand(GenerateModelCommand(logger: logger, workingDirectory: cwd));
  }

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generate features, pages, widgets, providers and models.';
}

/// Shared behaviour of the `generate <target> <name>` subcommands.
abstract class _GenerateTargetCommand extends Command<int> {
  _GenerateTargetCommand({
    required CliLogger logger,
    required String Function() workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory {
    argParser.addFlag(
      'dry-run',
      help: 'List the files that would be created, without writing anything.',
      negatable: false,
    );
  }

  final CliLogger _logger;
  final String Function() _workingDirectory;

  @override
  String get invocation => 'flutter_project_builder generate $name <name>';

  /// Generates the target named [targetName] (already validated).
  Future<GenerationReport> generate(
    FeatureGenerator generator,
    String targetName,
  );

  void addFeatureOption({required String help}) =>
      argParser.addOption('feature', help: help, valueHelp: 'name');

  void addFieldsOption() => argParser.addOption(
        'fields',
        help: 'Comma-separated fields, e.g. '
            '"id:int,title:String,price:double?". '
            'Types: ${ModelField.supportedTypes.join(', ')}.',
        valueHelp: 'spec',
      );

  void addRouteFlag() => argParser.addFlag(
        'route',
        help: 'Register the page in lib/router/.',
        defaultsTo: true,
      );

  /// The `--fields` value parsed into fields.
  List<ModelField> get fields => ModelField.parse(argResults!.option('fields'));

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.length != 1) {
      _logger
        ..error(
          args.isEmpty
              ? 'Please provide a $name name.'
              : 'Expected a single $name name but got ${args.length}: '
                  '${args.join(' ')}. Use snake_case for multi-word names.',
        )
        ..info('Usage: $invocation');
      return 1;
    }

    final currentDir = _workingDirectory();
    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      return 1;
    }

    final generator = FeatureGenerator(
      projectPath: currentDir,
      config: ProjectConfig.fromDirectory(currentDir),
      logger: _logger,
    );

    final GenerationReport report;
    try {
      if (argResults!.flag('dry-run')) {
        late GenerationReport dryReport;
        final recorder = await FileUtils.dryRun(() async {
          dryReport = await generate(generator, args.single);
        });
        printDryRun(_logger, recorder, currentDir);
        _printSkippedAndWarnings(dryReport);
        return 0;
      }
      report = await generate(generator, args.single);
    } on FormatException catch (e) {
      _logger.error(e.message);
      return 1;
    } on FileSystemException catch (e) {
      _logger.error('Generation failed: ${e.message} (${e.path})');
      return 1;
    }

    for (final path in report.created) {
      _logger.success('Created $path');
    }
    _printSkippedAndWarnings(report);
    if (report.created.isEmpty) {
      _logger.info('Nothing to do; all files already exist.');
    }
    return 0;
  }

  void _printSkippedAndWarnings(GenerationReport report) {
    for (final path in report.skipped) {
      _logger.info('Kept existing $path');
    }
    for (final warning in report.warnings) {
      _logger.warning(warning);
    }
  }
}

/// `generate feature <name>`: a complete feature with starter files.
class GenerateFeatureCommand extends _GenerateTargetCommand {
  /// Creates a new [GenerateFeatureCommand].
  GenerateFeatureCommand({
    required super.logger,
    String Function()? workingDirectory,
  }) : super(
          workingDirectory: workingDirectory ?? (() => Directory.current.path),
        ) {
    addFieldsOption();
    addRouteFlag();
  }

  @override
  String get name => 'feature';

  @override
  String get description =>
      'Generate a Clean Architecture feature: entity, model, data source, '
      'repository, provider, page, test and route.';

  @override
  Future<GenerationReport> generate(
    FeatureGenerator generator,
    String targetName,
  ) =>
      generator.generateFeature(
        targetName,
        fields: fields,
        registerRoute: argResults!.flag('route'),
      );
}

/// `generate page <name>`: a page, its test and a route.
class GeneratePageCommand extends _GenerateTargetCommand {
  /// Creates a new [GeneratePageCommand].
  GeneratePageCommand({
    required super.logger,
    String Function()? workingDirectory,
  }) : super(
          workingDirectory: workingDirectory ?? (() => Directory.current.path),
        ) {
    addFeatureOption(help: 'Feature folder (defaults to the page name).');
    addRouteFlag();
  }

  @override
  String get name => 'page';

  @override
  String get description => 'Generate a page with a widget test and a route.';

  @override
  Future<GenerationReport> generate(
    FeatureGenerator generator,
    String targetName,
  ) =>
      generator.generatePage(
        targetName,
        feature: argResults!.option('feature'),
        registerRoute: argResults!.flag('route'),
      );
}

/// `generate widget <name>`: a reusable widget and its test.
class GenerateWidgetCommand extends _GenerateTargetCommand {
  /// Creates a new [GenerateWidgetCommand].
  GenerateWidgetCommand({
    required super.logger,
    String Function()? workingDirectory,
  }) : super(
          workingDirectory: workingDirectory ?? (() => Directory.current.path),
        ) {
    addFeatureOption(
      help: 'Put the widget in this feature instead of lib/core/widgets.',
    );
  }

  @override
  String get name => 'widget';

  @override
  String get description => 'Generate a reusable widget with a widget test.';

  @override
  Future<GenerationReport> generate(
    FeatureGenerator generator,
    String targetName,
  ) =>
      generator.generateWidget(
        targetName,
        feature: argResults!.option('feature'),
      );
}

/// `generate provider <name>`: a Riverpod notifier and its test.
class GenerateProviderCommand extends _GenerateTargetCommand {
  /// Creates a new [GenerateProviderCommand].
  GenerateProviderCommand({
    required super.logger,
    String Function()? workingDirectory,
  }) : super(
          workingDirectory: workingDirectory ?? (() => Directory.current.path),
        ) {
    addFeatureOption(help: 'Feature folder (defaults to the provider name).');
    argParser.addOption(
      'type',
      help: 'Kind of provider.',
      allowed: ['notifier', 'async'],
      allowedHelp: {
        'notifier': 'Notifier with an immutable state class.',
        'async': 'AsyncNotifier with loading/error state and refresh().',
      },
      defaultsTo: 'notifier',
    );
  }

  @override
  String get name => 'provider';

  @override
  String get description => 'Generate a Riverpod notifier with a test.';

  @override
  Future<GenerationReport> generate(
    FeatureGenerator generator,
    String targetName,
  ) =>
      generator.generateProvider(
        targetName,
        feature: argResults!.option('feature'),
        kind: argResults!.option('type') == 'async'
            ? ProviderKind.async
            : ProviderKind.notifier,
      );
}

/// `generate model <name>`: a JSON model and its test.
class GenerateModelCommand extends _GenerateTargetCommand {
  /// Creates a new [GenerateModelCommand].
  GenerateModelCommand({
    required super.logger,
    String Function()? workingDirectory,
  }) : super(
          workingDirectory: workingDirectory ?? (() => Directory.current.path),
        ) {
    addFeatureOption(help: 'Feature folder (defaults to the model name).');
    addFieldsOption();
  }

  @override
  String get name => 'model';

  @override
  String get description => 'Generate a data model with fromJson/toJson, '
      'copyWith, equality and a test.';

  @override
  Future<GenerationReport> generate(
    FeatureGenerator generator,
    String targetName,
  ) =>
      generator.generateModel(
        targetName,
        feature: argResults!.option('feature'),
        fields: fields,
      );
}
