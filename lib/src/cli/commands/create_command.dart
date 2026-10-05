import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/constants.dart';
import '../../config/project_config.dart';
import '../../generators/project_generator.dart';
import '../../utils/file_utils.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to create a new Flutter project architecture.
///
/// Configuration is resolved in this order (highest priority first):
/// 1. options passed on the command line,
/// 2. `flutter_project_builder.yaml` in the project root,
/// 3. the interactive wizard (only when no file and no options are given and
///    the terminal is interactive),
/// 4. defaults.
class CreateCommand extends Command<int> {
  /// Creates a new [CreateCommand].
  CreateCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path) {
    argParser
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Ask for options interactively when no options and no '
            '${PackageConstants.configFileName} are given.',
        defaultsTo: true,
      )
      ..addOption(
        'template',
        abbr: 't',
        help: 'Architecture template to record in the configuration.',
        allowed: PackageConstants.templates,
        defaultsTo: PackageConstants.defaultTemplate,
      )
      ..addFlag(
        'flavors',
        abbr: 'f',
        help: 'Generate flavor entry points (dev, stage, prod).',
      )
      ..addFlag(
        'firebase',
        help: 'Prepare the lib/core/firebase/ folder.',
      )
      ..addFlag(
        'riverpod',
        help: 'Generate Riverpod UI helpers. Riverpod itself is always used.',
        defaultsTo: true,
        hide: true,
      )
      ..addFlag(
        'dio',
        help: 'Generate the Dio network layer.',
        defaultsTo: true,
      )
      ..addFlag(
        'hive',
        help: 'Generate the Hive CE storage layer.',
        defaultsTo: true,
      )
      ..addFlag(
        'localization',
        help: 'Generate gen-l10n localization (l10n.yaml + ARB).',
        defaultsTo: true,
      )
      ..addFlag(
        'sample',
        abbr: 's',
        help: 'Generate sample features (Counter, Users).',
        defaultsTo: true,
      )
      ..addOption(
        'org',
        abbr: 'o',
        help: 'Organization identifier to record in the configuration.',
        defaultsTo: PackageConstants.defaultOrganization,
      )
      ..addFlag(
        'force',
        help: 'Regenerate even if the architecture was already generated. '
            'Overwrites generated files.',
        negatable: false,
      );
  }

  static const List<String> _configOptions = [
    'template',
    'flavors',
    'firebase',
    'riverpod',
    'dio',
    'hive',
    'localization',
    'sample',
    'org',
  ];

  @override
  String get name => 'create';

  @override
  String get description =>
      'Generate the architecture inside the current Flutter project.';

  final CliLogger _logger;
  final String Function() _workingDirectory;

  @override
  Future<int> run() async {
    final results = argResults!;
    final currentDir = _workingDirectory();

    _logger.header('Generating Architecture');

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger
        ..error('No pubspec.yaml found or not a Flutter project.')
        ..info('Please run this command inside an existing Flutter project.');
      return 1;
    }

    if (ProjectGenerator.isGenerated(currentDir) && !results.flag('force')) {
      _logger
        ..error('The architecture has already been generated here.')
        ..info(
          'Use `flutter_project_builder upgrade` to refresh lib/core, or '
          'pass --force to regenerate everything (overwrites generated '
          'files, including lib/main.dart and lib/router/).',
        );
      return 1;
    }

    final hasConfigFile = ProjectConfig.existsIn(currentDir);
    var config = ProjectConfig.fromDirectory(currentDir);
    final hasExplicitOptions = _configOptions.any(results.wasParsed);

    if (hasConfigFile) {
      _logger.info('Using ${PackageConstants.configFileName}');
    } else if (!hasExplicitOptions &&
        results.flag('interactive') &&
        _isTerminalInteractive()) {
      config = _runInteractiveWizard();
    }
    config = _applyExplicitOptions(config);

    if (!config.riverpod) {
      _logger.warning(
        'riverpod: false only omits the AsyncValue UI helpers; the generated '
        'app, router and providers still use Riverpod.',
      );
    }

    _logger.summaryBox('Configuration', {
      'Template': config.template,
      'Organization': config.organization,
      'Flavors': config.hasFlavors ? config.flavors.join(', ') : 'None',
      'Network (Dio)': _yesNo(config.dio),
      'Storage (Hive CE)': _yesNo(config.hive),
      'Localization': _yesNo(config.localization),
      'Firebase folder': _yesNo(config.firebase),
      'Samples': _yesNo(config.sampleFeatures),
    });

    try {
      await ProjectGenerator(
        projectPath: currentDir,
        config: config,
        logger: _logger,
      ).generate();
    } catch (e, st) {
      _logger
        ..error('Generation failed: $e')
        ..trace(st.toString());
      return 1;
    }

    if (!hasConfigFile) {
      // Persist the effective options so `upgrade` and `generate` reuse them.
      FileUtils.createFile(
        ProjectConfig.configPath(currentDir),
        config.toYaml(),
      );
      _logger.success('Saved options to ${PackageConstants.configFileName}');
    }

    _logger.nextSteps([
      'Run `flutter pub get` to install dependencies'
          '${config.localization ? ' and generate localizations' : ''}',
      'Run `flutter test` to run the generated tests',
      'Read `ARCHITECTURE.md` for an overview of the generated structure',
      if (config.hasFlavors)
        'Run `flutter run -t lib/main_${config.flavors.first}.dart` to start'
      else
        'Run `flutter run` to start the app',
    ]);

    return 0;
  }

  ProjectConfig _applyExplicitOptions(ProjectConfig config) {
    final results = argResults!;
    bool? flag(String name) =>
        results.wasParsed(name) ? results.flag(name) : null;
    String? option(String name) =>
        results.wasParsed(name) ? results.option(name) : null;

    List<String>? flavors;
    if (results.wasParsed('flavors')) {
      flavors = results.flag('flavors')
          ? (config.hasFlavors
              ? config.flavors
              : PackageConstants.defaultFlavors)
          : const [];
    }

    return config.copyWith(
      template: option('template'),
      organization: option('org'),
      flavors: flavors,
      riverpod: flag('riverpod'),
      firebase: flag('firebase'),
      dio: flag('dio'),
      hive: flag('hive'),
      localization: flag('localization'),
      sampleFeatures: flag('sample'),
    );
  }

  static String _yesNo(bool value) => value ? 'Yes' : 'No';

  bool _isTerminalInteractive() => stdin.hasTerminal && stdout.hasTerminal;

  String? _ask(String question) {
    stdout.write('? $question ');
    return stdin.readLineSync()?.trim();
  }

  bool _confirm(String question, {required bool defaultValue}) {
    final answer =
        _ask('$question ${defaultValue ? '(Y/n)' : '(y/N)'}:')?.toLowerCase();
    if (answer == null || answer.isEmpty) return defaultValue;
    return answer == 'y' || answer == 'yes';
  }

  ProjectConfig _runInteractiveWizard() {
    _logger
      ..info('Interactive wizard started. Press Enter to use defaults.')
      ..newLine();

    final templateInput = _ask(
      'Architecture template (${PackageConstants.templates.join('/')}) '
      '[${PackageConstants.defaultTemplate}]:',
    );
    final template = PackageConstants.templates.contains(templateInput)
        ? templateInput!
        : PackageConstants.defaultTemplate;

    final orgInput =
        _ask('Organization [${PackageConstants.defaultOrganization}]:');
    final org = orgInput == null || orgInput.isEmpty
        ? PackageConstants.defaultOrganization
        : orgInput;

    final config = ProjectConfig(
      template: template,
      organization: org,
      flavors:
          _confirm('Include flavors (dev, stage, prod)?', defaultValue: false)
              ? PackageConstants.defaultFlavors
              : const [],
      dio: _confirm('Include Dio network layer?', defaultValue: true),
      hive: _confirm('Include Hive CE storage?', defaultValue: true),
      localization: _confirm('Include localization?', defaultValue: true),
      firebase: _confirm('Prepare Firebase folder?', defaultValue: false),
      sampleFeatures: _confirm('Generate sample features?', defaultValue: true),
    );

    _logger.newLine();
    return config;
  }
}
