// ignore_for_file: cascade_invocations, lines_longer_than_80_chars

import 'dart:io';

import 'package:args/command_runner.dart';

import '../../config/constants.dart';
import '../../config/project_config.dart';
import '../../generators/project_generator.dart';
import '../../utils/pubspec_utils.dart';
import '../cli_logger.dart';

/// Command to create a new Flutter project architecture.
class CreateCommand extends Command<int> {
  /// Creates a new [CreateCommand].
  CreateCommand({required CliLogger logger}) : _logger = logger {
    argParser
      ..addFlag(
        'interactive',
        abbr: 'i',
        help: 'Use interactive wizard to configure the project.',
        defaultsTo: true,
      )
      ..addOption(
        'template',
        abbr: 't',
        help: 'Architecture template to use.',
        allowed: PackageConstants.templates,
        defaultsTo: PackageConstants.defaultTemplate,
      )
      ..addFlag(
        'flavors',
        abbr: 'f',
        help: 'Generate flavor configurations (dev, stage, prod).',
      )
      ..addFlag(
        'firebase',
        help: 'Prepare Firebase folder structure.',
      )
      ..addFlag(
        'riverpod',
        help: 'Generate Riverpod state management.',
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
        help: 'Organization identifier.',
        defaultsTo: PackageConstants.defaultOrganization,
      );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Generate a Flutter project architecture.';

  final CliLogger _logger;

  @override
  Future<int> run() async {
    _logger.header('Generating Architecture');

    final currentDir = Directory.current.path;

    if (!PubspecUtils.isFlutterProject(currentDir)) {
      _logger.error('No pubspec.yaml found or not a Flutter project.');
      _logger
          .info('Please run this command inside an existing Flutter project.');
      return 1;
    }

    final isInteractive = argResults?['interactive'] as bool;
    late ProjectConfig config;

    if (isInteractive && _isTerminalInteractive()) {
      config = await _runInteractiveWizard();
    } else {
      config = _getConfigFromArgs();
    }

    _logger.summaryBox('Configuration', {
      'Template': config.template,
      'Organization': config.organization,
      'Flavors': config.flavors.isNotEmpty ? config.flavors.join(', ') : 'None',
      'Riverpod': config.riverpod ? 'Yes' : 'No',
      'Firebase': config.firebase ? 'Yes' : 'No',
      'Samples': config.sampleFeatures ? 'Yes' : 'No',
    });

    try {
      final generator = ProjectGenerator(
        projectPath: currentDir,
        config: config,
        logger: _logger,
      );

      await generator.generate();

      _logger.nextSteps([
        'Run `flutter pub get` to install new dependencies',
        'Run `dart run build_runner build -d` if you use code generation',
        'Review the generated `README.md` for architecture details',
        if (config.hasFlavors)
          'Run `flutter run -t lib/main_dev.dart --flavor dev` to start'
        else
          'Run `flutter run` to start the app',
      ]);

      return 0;
    } catch (e, st) {
      _logger.error('Generation failed: $e');
      _logger.detail(st.toString());
      return 1;
    }
  }

  bool _isTerminalInteractive() => stdin.hasTerminal && stdout.hasTerminal;

  ProjectConfig _getConfigFromArgs() => ProjectConfig(
        template: argResults?['template'] as String,
        organization: argResults?['org'] as String,
        flavors: (argResults?['flavors'] as bool? ?? false)
            ? PackageConstants.defaultFlavors
            : [],
        riverpod: argResults?['riverpod'] as bool? ?? true,
        firebase: argResults?['firebase'] as bool? ?? false,
        sampleFeatures: argResults?['sample'] as bool? ?? true,
      );

  Future<ProjectConfig> _runInteractiveWizard() async {
    _logger.info('Interactive wizard started. Press Enter to use defaults.');
    _logger.newLine();

    // Template
    stdout.write(
      '? Architecture template (${PackageConstants.templates.join('/')}) [${PackageConstants.defaultTemplate}]: ',
    );
    final templateInput = stdin.readLineSync()?.trim();
    final template = templateInput != null &&
            PackageConstants.templates.contains(templateInput)
        ? templateInput
        : PackageConstants.defaultTemplate;

    // Org
    stdout.write('? Organization [${PackageConstants.defaultOrganization}]: ');
    final orgInput = stdin.readLineSync()?.trim();
    final org = orgInput != null && orgInput.isNotEmpty
        ? orgInput
        : PackageConstants.defaultOrganization;

    // Flavors
    stdout.write('? Include flavors (dev, stage, prod)? (y/N): ');
    final flavorsInput = stdin.readLineSync()?.trim().toLowerCase();
    final flavors =
        flavorsInput == 'y' ? PackageConstants.defaultFlavors : <String>[];

    // Firebase
    stdout.write('? Prepare Firebase structure? (y/N): ');
    final firebaseInput = stdin.readLineSync()?.trim().toLowerCase();
    final firebase = firebaseInput == 'y';

    // Samples
    stdout.write('? Generate sample features? (Y/n): ');
    final samplesInput = stdin.readLineSync()?.trim().toLowerCase();
    final sampleFeatures = samplesInput != 'n';

    _logger.newLine();

    return ProjectConfig(
      template: template,
      organization: org,
      flavors: flavors,
      firebase: firebase,
      sampleFeatures: sampleFeatures,
    );
  }
}
