import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../../config/constants.dart';
import '../../config/project_config.dart';
import '../../generators/project_generator.dart';
import '../../utils/file_utils.dart';
import '../../utils/flutter_cli.dart';
import '../../utils/pubspec_utils.dart';
import '../../utils/string_utils.dart';
import '../cli_logger.dart';
import '../dry_run_report.dart';

/// Command to create a new Flutter project architecture.
///
/// `create` works in the current Flutter project, or with a directory
/// argument (`create my_app`) it first runs `flutter create` when that
/// directory does not exist yet (or is empty), then generates inside it.
///
/// Configuration is resolved in this order (highest priority first):
/// 1. options passed on the command line,
/// 2. `flutter_project_builder.yaml` in the project root,
/// 3. the interactive wizard (only when no file and no options are given and
///    the terminal is interactive),
/// 4. the preset of the chosen template (`clean` by default).
class CreateCommand extends Command<int> {
  /// Creates a new [CreateCommand].
  CreateCommand({
    required CliLogger logger,
    String Function()? workingDirectory,
    FlutterCli? flutter,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? (() => Directory.current.path),
        _flutter = flutter ?? FlutterCli() {
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
        help: 'Preset for options that are not set explicitly.',
        allowed: PackageConstants.templates,
        allowedHelp: {
          'basic': 'Core, theme, router and home page only.',
          'clean': 'Adds network, storage, localization and samples.',
          'enterprise': 'clean + dev/stage/prod flavors (Dart and native).',
        },
        defaultsTo: PackageConstants.defaultTemplate,
      )
      ..addOption(
        'org',
        abbr: 'o',
        help: 'Organization (reverse domain). Sets the Android application '
            'ID and iOS/macOS bundle IDs to <org>.<package>.',
        defaultsTo: PackageConstants.defaultOrganization,
      )
      ..addFlag(
        'flavors',
        abbr: 'f',
        help: 'Generate dev, stage and prod flavors.',
      )
      ..addFlag(
        'native-flavors',
        help: 'Also configure Android product flavors and Xcode schemes so '
            '`flutter run --flavor <name>` works.',
        defaultsTo: true,
      )
      ..addFlag(
        'firebase',
        help: 'Add firebase_core and initialise Firebase on startup.',
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
      ..addFlag(
        'dry-run',
        help: 'List the files that would be created or overwritten, without '
            'writing anything.',
        negatable: false,
      )
      ..addFlag(
        'force',
        help: 'Regenerate even if the architecture was already generated. '
            'Overwrites generated files.',
        negatable: false,
      )
      ..addOption(
        'project-name',
        help: 'Package name for a new project (defaults to the directory '
            'name). Only used when `create <directory>` creates the project.',
        valueHelp: 'name',
      )
      ..addMultiOption(
        'platforms',
        help: 'Platforms for a new project (defaults to all). Only used when '
            '`create <directory>` creates the project.',
        allowed: FlutterCli.platforms,
      )
      ..addFlag(
        'pub',
        help: 'Run `flutter pub get` afterwards. Defaults to on when a new '
            'project is created or native flavors are configured (so the '
            'flavors can be mapped in a CocoaPods Podfile), off otherwise.',
      );
  }

  @override
  String get invocation => 'flutter_project_builder create [directory]';

  static const List<String> _configOptions = [
    'template',
    'flavors',
    'native-flavors',
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
  final FlutterCli _flutter;

  @override
  Future<int> run() async {
    final results = argResults!;
    final dryRun = results.flag('dry-run');

    if (results.rest.length > 1) {
      usageException('Expected at most one directory, got '
          '${results.rest.length}: ${results.rest.join(' ')}.');
    }
    final directoryArg = results.rest.firstOrNull;
    final currentDir = directoryArg == null
        ? _workingDirectory()
        : p.normalize(p.join(_workingDirectory(), directoryArg));
    final needsFlutterCreate =
        directoryArg != null && _isMissingOrEmpty(currentDir);

    _logger.header('Generating Architecture');

    if (results.wasParsed('org') &&
        !ProjectConfig.isValidOrganization(results.option('org')!)) {
      usageException('Invalid --org "${results.option('org')}". Use a '
          'reverse-domain identifier such as "com.mycompany".');
    }

    String? projectName;
    if (needsFlutterCreate) {
      projectName = results.option('project-name') ?? p.basename(currentDir);
      if (!_isValidPackageName(projectName)) {
        usageException(
          '"$projectName" is not a valid package name. Use lowercase '
          'letters, digits and underscores (e.g. my_app), or pass '
          '--project-name.',
        );
      }
    } else {
      for (final option in ['project-name', 'platforms']) {
        if (results.wasParsed(option)) {
          _logger.warning('--$option is only used when a new project is '
              'created; ignoring it.');
        }
      }
      if (!PubspecUtils.isFlutterProject(currentDir)) {
        _logger
          ..error(
            directoryArg == null
                ? 'No pubspec.yaml found or not a Flutter project.'
                : '$directoryArg exists but is not a Flutter project.',
          )
          ..info(
            directoryArg == null
                ? 'Run this command inside a Flutter project, or pass a new '
                    'directory name: flutter_project_builder create my_app'
                : 'Choose a new directory name, or an existing Flutter '
                    'project.',
          );
        return 1;
      }
      if (ProjectGenerator.isGenerated(currentDir) &&
          !results.flag('force') &&
          !dryRun) {
        _logger
          ..error('The architecture has already been generated here.')
          ..info(
            'Use `flutter_project_builder upgrade` to refresh lib/core, or '
            'pass --force to regenerate everything (overwrites generated '
            'files, including lib/main.dart and lib/router/). Add --dry-run '
            'to preview.',
          );
        return 1;
      }
    }

    final hasConfigFile = ProjectConfig.existsIn(currentDir);
    final templateOverride =
        results.wasParsed('template') ? results.option('template') : null;
    var config = ProjectConfig.fromDirectory(
      currentDir,
      templateOverride: templateOverride,
    );
    final hasExplicitOptions = _configOptions.any(results.wasParsed);

    if (hasConfigFile) {
      _logger.info('Using ${PackageConstants.configFileName}');
    } else if (!hasExplicitOptions &&
        !dryRun &&
        results.flag('interactive') &&
        _isTerminalInteractive()) {
      config = _runInteractiveWizard();
    }
    config = _applyExplicitOptions(config);

    if (needsFlutterCreate) {
      final arguments = FlutterCli.createArguments(
        currentDir,
        projectName: projectName!,
        organization: config.hasCustomOrganization ? config.organization : null,
        platforms: results.multiOption('platforms'),
      );
      if (dryRun) {
        _logger
          ..section('Dry run (nothing was written)')
          ..info('Would run: flutter ${arguments.join(' ')}')
          ..info('Then generate the architecture in $directoryArg with:');
        _printSummary(config);
        return 0;
      }
      final created = await _runFlutterCreate(currentDir, projectName, config);
      if (!created) return 1;
    }

    if (!config.riverpod) {
      _logger.warning(
        'riverpod: false only omits the AsyncValue UI helpers; the generated '
        'app, router and providers still use Riverpod.',
      );
    }

    _printSummary(config);

    final generator = ProjectGenerator(
      projectPath: currentDir,
      config: config,
      logger: _logger,
    );

    Future<void> generate() async {
      await generator.generate();
      if (!hasConfigFile) {
        // Persist the effective options so `upgrade` and `generate` reuse
        // them.
        FileUtils.createFile(
          ProjectConfig.configPath(currentDir),
          config.toYaml(),
        );
      }
    }

    try {
      if (dryRun) {
        final recorder = await FileUtils.dryRun(generate);
        printDryRun(_logger, recorder, currentDir);
        _printWarnings(generator.warnings);
        return 0;
      }
      await generate();
    } catch (e, st) {
      _logger
        ..error('Generation failed: $e')
        ..trace(st.toString());
      return 1;
    }

    if (!hasConfigFile) {
      _logger.success('Saved options to ${PackageConstants.configFileName}');
    }
    _printWarnings(generator.warnings);

    final runPubGet = results.wasParsed('pub')
        ? results.flag('pub')
        : needsFlutterCreate || config.hasNativeFlavors;
    final pubGetDone = runPubGet && await _runPubGet(currentDir);
    if (pubGetDone && generator.needsNativeConfiguration) {
      // `pub get` lets Flutter choose CocoaPods or Swift Package Manager and
      // create a Podfile only if needed; map the flavors in it now.
      final before = generator.warnings.length;
      await generator.configureNative();
      _printWarnings(generator.warnings.sublist(before));
    } else if (!pubGetDone && config.hasNativeFlavors) {
      _logger.info(
        'After `flutter pub get`, run `flutter_project_builder upgrade` so '
        'the flavors are also mapped in any Podfile Flutter creates.',
      );
    }

    final firstFlavor = config.hasFlavors ? config.flavors.first : null;
    _logger.nextSteps([
      if (directoryArg != null) 'cd $directoryArg',
      if (!pubGetDone)
        'Run `flutter pub get` to install dependencies'
            '${config.localization ? ' and generate localizations' : ''}',
      if (config.firebase)
        'Run `flutterfire configure` to connect your Firebase project',
      'Run `flutter test` to run the generated tests',
      'Read `ARCHITECTURE.md` for an overview of the generated structure',
      if (config.hasNativeFlavors)
        'Run `flutter run --flavor $firstFlavor` (plain `flutter run` uses '
            '$firstFlavor)'
      else if (config.hasFlavors)
        'Run `flutter run -t lib/main_$firstFlavor.dart` to start'
      else
        'Run `flutter run` to start the app',
    ]);

    return 0;
  }

  void _printSummary(ProjectConfig config) {
    _logger.summaryBox('Configuration', {
      'Template': config.template,
      'Organization': config.hasCustomOrganization
          ? '${config.organization} (sets app IDs)'
          : '${config.organization} (app IDs unchanged)',
      'Flavors': config.hasFlavors
          ? '${config.flavors.join(', ')}'
              '${config.hasNativeFlavors ? ' (Dart + native)' : ' (Dart only)'}'
          : 'None',
      'Network (Dio)': _yesNo(config.dio),
      'Storage (Hive CE)': _yesNo(config.hive),
      'Localization': _yesNo(config.localization),
      'Firebase': _yesNo(config.firebase),
      'Samples': _yesNo(config.sampleFeatures),
    });
  }

  static bool _isMissingOrEmpty(String path) {
    final dir = Directory(path);
    return !dir.existsSync() || dir.listSync().isEmpty;
  }

  static bool _isValidPackageName(String name) =>
      RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name) &&
      StringUtils.isValidIdentifier(name);

  Future<bool> _runFlutterCreate(
    String directory,
    String projectName,
    ProjectConfig config,
  ) async {
    _logger.info('Running flutter create for $projectName...');
    final ProcessResult result;
    try {
      result = await _flutter.create(
        directory,
        projectName: projectName,
        organization: config.hasCustomOrganization ? config.organization : null,
        platforms: argResults!.multiOption('platforms'),
      );
    } on ProcessException {
      _logger.error('Could not run `flutter`. Make sure the Flutter SDK is on '
          'your PATH (check with `flutter_project_builder doctor`).');
      return false;
    }
    if (result.exitCode != 0 || !PubspecUtils.isFlutterProject(directory)) {
      _logger.error('flutter create failed (exit code ${result.exitCode}).');
      final output = '${result.stderr}'.trim().isNotEmpty
          ? '${result.stderr}'
          : '${result.stdout}';
      if (output.trim().isNotEmpty) _logger.write(output.trim());
      return false;
    }
    _logger.success('Created Flutter project in $directory');
    return true;
  }

  Future<bool> _runPubGet(String directory) async {
    _logger.info('Running flutter pub get...');
    try {
      final result = await _flutter.pubGet(directory);
      if (result.exitCode == 0) {
        _logger.success('Dependencies installed');
        return true;
      }
      _logger.warning(
        '`flutter pub get` failed (exit code ${result.exitCode}); run it '
        'manually. ${'${result.stderr}'.trim()}',
      );
    } on ProcessException {
      _logger.warning('Could not run `flutter pub get`; run it manually.');
    }
    return false;
  }

  void _printWarnings(List<String> warnings) {
    for (final warning in warnings) {
      _logger.warning(warning);
    }
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
      nativeFlavors: flag('native-flavors'),
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
    // The template's preset provides the default answers.
    final preset = ProjectConfig.forTemplate(template);

    var org = PackageConstants.defaultOrganization;
    while (true) {
      final input = _ask('Organization, e.g. com.mycompany '
          '[${PackageConstants.defaultOrganization}]:');
      if (input == null || input.isEmpty) break;
      if (ProjectConfig.isValidOrganization(input)) {
        org = input;
        break;
      }
      _logger.warning('Use a reverse-domain identifier such as com.acme.');
    }

    final flavors = _confirm(
      'Include flavors (dev, stage, prod)?',
      defaultValue: preset.hasFlavors,
    );
    final config = preset.copyWith(
      organization: org,
      flavors: flavors ? PackageConstants.defaultFlavors : const [],
      nativeFlavors: flavors &&
          _confirm(
            'Configure native Android/iOS flavors?',
            defaultValue: true,
          ),
      dio: _confirm('Include Dio network layer?', defaultValue: preset.dio),
      hive: _confirm('Include Hive CE storage?', defaultValue: preset.hive),
      localization: _confirm(
        'Include localization?',
        defaultValue: preset.localization,
      ),
      firebase: _confirm('Set up Firebase?', defaultValue: preset.firebase),
      sampleFeatures: _confirm(
        'Generate sample features?',
        defaultValue: preset.sampleFeatures,
      ),
    );

    _logger.newLine();
    return config;
  }
}
