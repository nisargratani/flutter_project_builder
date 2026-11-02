// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:path/path.dart' as p;

import '../cli/cli_logger.dart';
import '../config/project_config.dart';
import '../templates/code/code_template.dart';
import '../templates/features/feature_template.dart';
import '../templates/router/router_template.dart';
import '../utils/file_utils.dart';
import '../utils/native_project.dart';
import '../utils/pubspec_utils.dart';
import '../utils/sdk_type_names.dart';
import '../utils/string_utils.dart';
import 'model_field.dart';

/// What a `generate` command wrote.
class GenerationReport {
  /// Project-relative paths of files that were written.
  final List<String> created = [];

  /// Project-relative paths that already existed and were left untouched.
  final List<String> skipped = [];

  /// Things the user has to do by hand.
  final List<String> warnings = [];

  /// Whether a route was added to the router.
  bool routeRegistered = false;
}

/// The kind of provider created by `generate provider`.
enum ProviderKind {
  /// A synchronous `Notifier` with an immutable state class.
  notifier,

  /// An `AsyncNotifier` with loading/error handling.
  async,
}

/// Scaffolds features and their building blocks (pages, widgets, providers,
/// models) following the generated Clean Architecture.
class FeatureGenerator {
  FeatureGenerator({
    required this.projectPath,
    required this.config,
    this.logger,
  });

  /// The path to the project.
  final String projectPath;

  /// The project configuration.
  final ProjectConfig config;

  /// The CLI logger.
  final CliLogger? logger;

  static const List<List<String>> _layerFolders = [
    ['data', 'datasource'],
    ['data', 'models'],
    ['data', 'repository'],
    ['domain', 'entities'],
    ['domain', 'repository'],
    ['domain', 'usecases'],
    ['presentation', 'pages'],
    ['presentation', 'widgets'],
    ['presentation', 'providers'],
  ];

  /// Class names that would shadow Flutter, Riverpod or generated types.
  static const Set<String> _reservedClassNames = {
    'App', 'MyApp', 'Widget', 'State', 'Key', 'Text', 'Icon', 'Image', //
    'Card', 'Center', 'Column', 'Row', 'Container', 'Padding', 'InkWell',
    'Scaffold', 'Material', 'Theme', 'Color', 'Colors', 'Route', 'Navigator',
    'Page', 'MaterialPage', 'CupertinoPage', 'HomePage', 'Provider', 'Ref',
    'Notifier', 'AsyncNotifier', 'AsyncValue', 'Override', 'ListTile',
    'Divider', 'Gap', 'AppButton', 'EmptyWidget', 'Failure',
  };

  /// Converts [input] (e.g. `UserProfile`, `user-profile`) to the snake_case
  /// name used for files and folders.
  ///
  /// Throws a [FormatException] if the result is not a valid lowercase Dart
  /// identifier (this also rejects path separators such as `../`) or is a
  /// reserved word.
  static String normalizeName(String input) {
    final name = StringUtils.toSnakeCase(input);
    if (name.isEmpty ||
        name != name.toLowerCase() ||
        !StringUtils.isValidIdentifier(name)) {
      throw FormatException(
        'Invalid name "$input". Use letters, digits and underscores, '
        'starting with a letter (e.g. "user_profile"), and avoid Dart '
        'reserved words.',
      );
    }
    return name;
  }

  static Set<String>? _flutterClasses;

  /// Public type names of the installed Flutter SDK that generated code can
  /// see or that would be confusing to shadow: everything
  /// `package:flutter/material.dart` exports (including `dart:ui` and the
  /// painting, foundation, ... types it re-exports), plus the classes of
  /// the material, cupertino and widgets libraries. Empty if the SDK cannot
  /// be found.
  static Set<String> get flutterClassNames => _flutterClasses ??= () {
        final root = NativeProject.flutterRoot();
        if (root == null) return <String>{};
        final names = SdkTypeNames.material(root);
        for (final library in ['material', 'cupertino', 'widgets']) {
          final dir = Directory(
            p.join(root, 'packages', 'flutter', 'lib', 'src', library),
          );
          if (!dir.existsSync()) continue;
          for (final file in dir.listSync().whereType<File>()) {
            names.addAll(SdkTypeNames.declaredIn(file.readAsStringSync()));
          }
        }
        return names;
      }();

  static void _checkClassName(String className) {
    final owner = SdkTypeNames.dartCore.contains(className)
        ? "dart:core's $className"
        : flutterClassNames.contains(className)
            ? "Flutter's own $className"
            : _reservedClassNames.contains(className)
                ? 'an existing Flutter or project type'
                : null;
    if (owner != null) {
      throw FormatException(
        'The generated class "$className" would clash with $owner. Choose '
        'another name (for example prefix it with your feature).',
      );
    }
  }

  /// Returns the folder of feature [name] (already normalized).
  String featurePath(String name) =>
      p.join(projectPath, 'lib', 'features', name);

  String get _package =>
      PubspecUtils.getProjectName(projectPath) ?? p.basename(projectPath);

  /// Writes [content] to [relative] unless the file exists; returns
  /// whether it was written.
  bool _write(GenerationReport report, String relative, String content) {
    final written =
        FileUtils.createFileIfAbsent(p.join(projectPath, relative), content);
    (written ? report.created : report.skipped).add(relative);
    return written;
  }

  /// Writes a generated test, unless code it tests already existed and was
  /// kept ([keptSources]): that code has its own API, so the template's test
  /// would not compile or pass against it.
  void _writeTest(
    GenerationReport report,
    String relative,
    String content, {
    required List<String> keptSources,
  }) {
    if (keptSources.isNotEmpty &&
        !FileUtils.fileExists(p.join(projectPath, relative))) {
      report.warnings.add(
        'Did not write $relative: ${keptSources.join(', ')} already '
        'existed, and the generated test would not match it.',
      );
      return;
    }
    _write(report, relative, content);
  }

  // ── Feature ────────────────────────────────────────────────────────

  /// Scaffolds feature [name] with starter files in every layer: entity,
  /// repository contract, model, data source (mock, plus Dio when the
  /// network layer is enabled), repository implementation, provider,
  /// page and a test. The page is registered in the router unless
  /// [registerRoute] is `false`.
  ///
  /// Existing files are never modified. Throws a [FormatException] for
  /// invalid names or [fields].
  Future<GenerationReport> generateFeature(
    String name, {
    List<ModelField> fields = ModelField.defaults,
    bool registerRoute = true,
  }) async {
    final n = Names(normalizeName(name));
    _checkClassName('${n.pascal}Page');
    final report = GenerationReport();
    final base = p.join('lib', 'features', n.snake);

    final files = {
      'domain/entities/${n.snake}_entity.dart': CodeTemplate.entity(n, fields),
      'domain/repository/${n.snake}_repository.dart':
          CodeTemplate.repository(n),
      'data/models/${n.snake}_model.dart': CodeTemplate.featureModel(n, fields),
      'data/datasource/${n.snake}_remote_data_source.dart':
          CodeTemplate.remoteDataSource(n, fields, dio: config.dio),
      'data/repository/${n.snake}_repository_impl.dart':
          CodeTemplate.repositoryImpl(n),
      'presentation/providers/${n.snake}_provider.dart':
          CodeTemplate.featureProvider(n, dio: config.dio),
      'presentation/pages/${n.snake}_page.dart':
          CodeTemplate.featurePage(n, fields),
    };
    final kept = <String>[];
    for (final entry in files.entries) {
      final relative = p.join(base, entry.key);
      if (!_write(report, relative, entry.value)) kept.add(relative);
    }
    for (final folder in ['domain/usecases', 'presentation/widgets']) {
      final dir = p.join(projectPath, base, folder);
      if (!FileUtils.directoryExists(dir)) {
        _write(report, p.join(base, folder, '.gitkeep'), '');
      }
    }
    // The test drives the notifier, repository and data source together.
    _writeTest(
      report,
      p.join('test', 'features', n.snake, '${n.snake}_notifier_test.dart'),
      CodeTemplate.featureTest(n, fields, _package),
      keptSources: kept,
    );

    if (registerRoute) {
      _registerRoute(n, 'features/${n.snake}/presentation/pages', report);
    }
    return report;
  }

  // ── Page / widget / provider / model ───────────────────────────────

  /// Generates `<name>_page.dart` in [feature] (defaults to [name]) with a
  /// widget test, and registers it in the router unless [registerRoute] is
  /// `false`.
  Future<GenerationReport> generatePage(
    String name, {
    String? feature,
    bool registerRoute = true,
  }) async {
    final n = Names(normalizeName(name));
    final featureName = normalizeName(feature ?? name);
    _checkClassName('${n.pascal}Page');
    final report = GenerationReport();
    final dir = 'features/$featureName/presentation/pages';

    final source = p.join('lib', dir, '${n.snake}_page.dart');
    final written = _write(report, source, CodeTemplate.page(n));
    _writeTest(
      report,
      p.join('test', 'features', featureName, '${n.snake}_page_test.dart'),
      CodeTemplate.pageTest(
        n,
        'package:$_package/$dir/${n.snake}_page.dart',
      ),
      keptSources: [if (!written) source],
    );
    if (registerRoute) _registerRoute(n, dir, report);
    return report;
  }

  /// Generates a reusable widget in `lib/core/widgets/` or, with
  /// [feature], in that feature's `presentation/widgets/`, plus a test.
  Future<GenerationReport> generateWidget(
    String name, {
    String? feature,
  }) async {
    final n = Names(normalizeName(name));
    _checkClassName(n.pascal);
    final report = GenerationReport();
    final dir = feature == null
        ? 'core/widgets'
        : 'features/${normalizeName(feature)}/presentation/widgets';
    final testDir = feature == null
        ? p.join('test', 'core', 'widgets')
        : p.join('test', 'features', normalizeName(feature));

    final source = p.join('lib', dir, '${n.snake}.dart');
    final written = _write(report, source, CodeTemplate.widget(n));
    _writeTest(
      report,
      p.join(testDir, '${n.snake}_test.dart'),
      CodeTemplate.widgetTest(n, 'package:$_package/$dir/${n.snake}.dart'),
      keptSources: [if (!written) source],
    );
    return report;
  }

  /// Generates a Riverpod provider in [feature] (defaults to [name]) plus a
  /// test.
  Future<GenerationReport> generateProvider(
    String name, {
    String? feature,
    ProviderKind kind = ProviderKind.notifier,
  }) async {
    final n = Names(normalizeName(name));
    final featureName = normalizeName(feature ?? name);
    final isAsync = kind == ProviderKind.async;
    _checkClassName('${n.pascal}Notifier');
    // A notifier provider also declares its state class.
    if (!isAsync) _checkClassName('${n.pascal}State');
    final report = GenerationReport();
    final dir = 'features/$featureName/presentation/providers';

    final source = p.join('lib', dir, '${n.snake}_provider.dart');
    final written = _write(
      report,
      source,
      isAsync
          ? CodeTemplate.asyncProvider(n)
          : CodeTemplate.notifierProvider(n),
    );
    _writeTest(
      report,
      p.join('test', 'features', featureName, '${n.snake}_provider_test.dart'),
      CodeTemplate.providerTest(
        n,
        'package:$_package/$dir/${n.snake}_provider.dart',
        isAsync: isAsync,
      ),
      keptSources: [if (!written) source],
    );
    return report;
  }

  /// Generates a data model with JSON support, `copyWith` and value
  /// equality in [feature] (defaults to [name]), plus a test.
  Future<GenerationReport> generateModel(
    String name, {
    String? feature,
    List<ModelField> fields = ModelField.defaults,
  }) async {
    final n = Names(normalizeName(name));
    final featureName = normalizeName(feature ?? name);
    _checkClassName('${n.pascal}Model');
    final report = GenerationReport();
    final dir = 'features/$featureName/data/models';

    final source = p.join('lib', dir, '${n.snake}_model.dart');
    final written = _write(report, source, CodeTemplate.model(n, fields));
    _writeTest(
      report,
      p.join('test', 'features', featureName, '${n.snake}_model_test.dart'),
      CodeTemplate.modelTest(
        n,
        fields,
        'package:$_package/$dir/${n.snake}_model.dart',
      ),
      keptSources: [if (!written) source],
    );
    return report;
  }

  // ── Routes ─────────────────────────────────────────────────────────

  /// Adds a child route of the home route for `<Pascal>Page` in [pageDir]
  /// (relative to `lib/`), plus its `RouteNames`/`RoutePaths` constants.
  void _registerRoute(Names n, String pageDir, GenerationReport report) {
    const routerFile = 'lib/router/app_router.dart';
    const namesFile = 'lib/router/route_names.dart';
    final routerPath = p.join(projectPath, routerFile);
    final namesPath = p.join(projectPath, namesFile);
    final router = FileUtils.readFile(routerPath);
    final names = FileUtils.readFile(namesPath);

    final manual = 'Add this route to $routerFile:\n'
        '${CodeTemplate.route(n)}'
        "and `static const String ${n.camel} = '${n.snake}';` to RouteNames "
        'and RoutePaths in $namesFile.';

    if (router == null ||
        names == null ||
        !router.contains(RouterTemplate.routesMarker) ||
        !names.contains(RouterTemplate.namesMarker) ||
        !names.contains(RouterTemplate.pathsMarker)) {
      report.warnings.add('Route markers not found. $manual');
      return;
    }
    if (router.contains('RoutePaths.${n.camel},')) return;
    if (RegExp('static const String ${n.camel} =').hasMatch(names)) {
      report.warnings.add(
        'RouteNames.${n.camel} already exists, so no route was added. '
        '$manual',
      );
      return;
    }

    // Router: import + route before the marker line.
    final import = "import '../$pageDir/${n.snake}_page.dart';";
    var updatedRouter = router.replaceFirst(
      RegExp(
        '^[ \\t]*${RegExp.escape(RouterTemplate.routesMarker)}',
        multiLine: true,
      ),
      '${CodeTemplate.route(n)}          ${RouterTemplate.routesMarker}',
    );
    if (!updatedRouter.contains(import)) {
      final lastImport = RegExp(r'^import .*;$', multiLine: true)
          .allMatches(updatedRouter)
          .last;
      updatedRouter = updatedRouter.replaceRange(
        lastImport.end,
        lastImport.end,
        '\n$import',
      );
    }

    final path = StringUtils.toKebabCase(n.snake);
    final updatedNames = names
        .replaceFirst(
          RouterTemplate.namesMarker,
          "static const String ${n.camel} = '${n.camel}';\n"
          '  ${RouterTemplate.namesMarker}',
        )
        .replaceFirst(
          RouterTemplate.pathsMarker,
          "static const String ${n.camel} = '$path';\n"
          '  ${RouterTemplate.pathsMarker}',
        );

    FileUtils.createFile(routerPath, updatedRouter);
    FileUtils.createFile(namesPath, updatedNames);
    report
      ..created.addAll([routerFile, namesFile])
      ..routeRegistered = true;
  }

  // ── Architecture (used by `create`) ────────────────────────────────

  /// Creates only the empty layer folders of feature [name].
  Future<void> generateFeatureFolders(String name) async {
    final basePath = featurePath(normalizeName(name));
    for (final segments in _layerFolders) {
      final dir = p.joinAll([basePath, ...segments]);
      if (FileUtils.directoryExists(dir)) continue;
      FileUtils.createGitKeep(dir);
    }
  }

  /// Generates the home page used as the router's initial route.
  Future<void> generateHome() async {
    FileUtils.createFile(
      p.join(featurePath('home'), 'presentation', 'pages', 'home_page.dart'),
      FeatureTemplate.homePage(samples: config.sampleFeatures),
    );
  }

  /// Generates the Counter sample feature (synchronous `Notifier`).
  Future<void> generateCounterSample() async {
    final base = featurePath('counter');
    FileUtils.createFile(
      p.join(base, 'domain', 'entities', 'counter.dart'),
      FeatureTemplate.counterEntity,
    );
    FileUtils.createFile(
      p.join(base, 'presentation', 'providers', 'counter_provider.dart'),
      FeatureTemplate.counterProvider,
    );
    FileUtils.createFile(
      p.join(base, 'presentation', 'pages', 'counter_page.dart'),
      FeatureTemplate.counterPage,
    );
  }

  /// Generates the Users sample feature (all layers, `AsyncNotifier`).
  Future<void> generateUsersSample() async {
    final base = featurePath('users');
    final files = {
      p.join('domain', 'entities', 'user.dart'): FeatureTemplate.userEntity,
      p.join('domain', 'repository', 'user_repository.dart'):
          FeatureTemplate.userRepository,
      p.join('data', 'models', 'user_model.dart'): FeatureTemplate.userModel,
      p.join('data', 'datasource', 'user_remote_data_source.dart'):
          FeatureTemplate.userRemoteDataSource(dio: config.dio),
      p.join('data', 'repository', 'user_repository_impl.dart'):
          FeatureTemplate.userRepositoryImpl,
      p.join('presentation', 'providers', 'users_provider.dart'):
          FeatureTemplate.usersProvider,
      p.join('presentation', 'pages', 'users_page.dart'):
          FeatureTemplate.usersPage,
    };
    for (final entry in files.entries) {
      FileUtils.createFile(p.join(base, entry.key), entry.value);
    }
  }
}
