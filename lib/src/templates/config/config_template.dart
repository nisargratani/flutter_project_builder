// ignore_for_file: public_member_api_docs

import '../../utils/string_utils.dart';

/// Template builders for the application entry points, environment
/// configuration and flavors.
class ConfigTemplate {
  ConfigTemplate._();

  /// Flavors that use the production API and app name.
  static const Set<String> productionFlavors = {'prod', 'production'};

  /// `lib/app.dart`: the root widget.
  static String app({required bool localization}) {
    final l10nImport =
        localization ? "import 'l10n/app_localizations.dart';\n" : '';
    final l10nConfig = localization
        ? '''
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
'''
        : '      title: ref.watch(appConfigProvider).appName,\n';
    final configImport =
        localization ? '' : "import 'core/config/app_config.dart';\n";
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

${configImport}import 'core/theme/app_theme.dart';
${l10nImport}import 'router/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
$l10nConfig      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
''';
  }

  /// `lib/bootstrap.dart`: shared startup logic for every entry point.
  static String bootstrap({required bool hive, required bool firebase}) {
    final imports = [
      "import 'app.dart';",
      "import 'core/config/app_config.dart';",
      if (firebase) "import 'core/firebase/firebase_initializer.dart';",
      "import 'core/logger/app_logger.dart';",
      if (hive) "import 'core/storage/hive_storage_service.dart';",
    ].join('\n');
    final firebaseInit =
        firebase ? '\n  await FirebaseInitializer.initialize();\n' : '';
    final storageInit = hive
        ? '''

  final storage = HiveStorageService();
  await storage.init();
'''
        : '';
    final scope = hive
        ? '''
  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const MyApp(),
    ),
  );'''
        : '  runApp(const ProviderScope(child: MyApp()));';
    return '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

$imports

/// Initialises services and starts the app.
///
/// Every entry point (`main.dart`, `main_<flavor>.dart`) calls this.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.current;
  AppLogger.info('Starting \${config.environment} (\${config.baseUrl})');
$firebaseInit$storageInit
$scope
}
''';
  }

  /// `lib/main.dart`: the default entry point.
  ///
  /// With flavors it selects the flavor passed to `flutter run --flavor`
  /// (exposed by Flutter as `appFlavor`), so the Dart and native flavors
  /// always match.
  static String main({required bool flavors}) => flavors
      ? '''
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'core/config/flavor_config.dart';

/// Uses the flavor from `flutter run --flavor <name>` (or the pubspec
/// `default-flavor`), falling back to the first flavor.
Future<void> main() {
  FlavorConfig.flavor = FlavorConfig.fromName(appFlavor);
  return bootstrap();
}
'''
      : '''
import 'bootstrap.dart';

Future<void> main() => bootstrap();
''';

  /// `lib/main_<flavor>.dart`.
  static String flavorMain(String flavor) => '''
import 'bootstrap.dart';
import 'core/config/flavor_config.dart';

Future<void> main() {
  FlavorConfig.flavor = Flavor.$flavor;
  return bootstrap();
}
''';

  /// `lib/core/config/app_config.dart`: per-environment settings.
  static String appConfig({required bool flavors, required String appName}) {
    final source = flavors
        ? '''
  /// The configuration of the running flavor (see [FlavorConfig]).
  static AppConfig get current => _withOverrides(FlavorConfig.config);'''
        : '''
  /// The configuration of the running app.
  static AppConfig get current => _withOverrides(
        const AppConfig(
          environment: 'default',
          appName: '$appName',
          baseUrl: 'https://api.example.com/',
          enableNetworkLogs: kDebugMode,
        ),
      );''';
    final imports = flavors
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n"
            "import 'flavor_config.dart';\n"
        : "import 'package:flutter/foundation.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';\n";
    return '''
${imports}
/// Environment-specific settings (API base URL, app name, logging).
///
/// Read it through [appConfigProvider] so tests can override it.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    this.enableNetworkLogs = false,
  });

  /// Environment name, e.g. `dev` or `prod`.
  final String environment;

  /// Human-readable app name.
  final String appName;

  /// Base URL used by the API client.
  final String baseUrl;

  /// Whether HTTP requests and responses are logged.
  final bool enableNetworkLogs;

  /// `--dart-define=BASE_URL=https://...` overrides [baseUrl] at build time,
  /// e.g. to point CI builds at a test server.
  static const String _baseUrlOverride = String.fromEnvironment('BASE_URL');

$source

  static AppConfig _withOverrides(AppConfig config) =>
      _baseUrlOverride.isEmpty
          ? config
          : config.copyWith(baseUrl: _baseUrlOverride);

  AppConfig copyWith({
    String? environment,
    String? appName,
    String? baseUrl,
    bool? enableNetworkLogs,
  }) =>
      AppConfig(
        environment: environment ?? this.environment,
        appName: appName ?? this.appName,
        baseUrl: baseUrl ?? this.baseUrl,
        enableNetworkLogs: enableNetworkLogs ?? this.enableNetworkLogs,
      );
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);
''';
  }

  /// `lib/core/config/flavor_config.dart`.
  ///
  /// The first flavor is the default, so `lib/main.dart` works without
  /// selecting one explicitly. Each flavor gets its own [appConfig] entry.
  static String flavorConfig(List<String> flavors, {required String appName}) {
    final getters = flavors
        .map(
          (f) => '  static bool get is${StringUtils.toPascalCase(f)} => '
              'flavor == Flavor.$f;',
        )
        .join('\n');
    final cases = flavors.map((f) {
      final isProd = productionFlavors.contains(f);
      final name = isProd ? appName : '$appName ${StringUtils.toTitleCase(f)}';
      final url =
          isProd ? 'https://api.example.com/' : 'https://$f.api.example.com/';
      return '''
        Flavor.$f => const AppConfig(
            environment: '$f',
            appName: '$name',
            baseUrl: '$url',
            enableNetworkLogs: ${!isProd},
          ),''';
    }).join('\n');
    return '''
import 'app_config.dart';

enum Flavor { ${flavors.join(', ')} }

class FlavorConfig {
  FlavorConfig._();

  /// The active flavor. Set by the entry point before the app starts.
  static Flavor flavor = Flavor.${flavors.first};

  /// Returns the flavor called [name], or the first flavor if there is none.
  static Flavor fromName(String? name) =>
      Flavor.values.asNameMap()[name] ?? Flavor.${flavors.first};

  /// Settings of the active flavor. Edit the URLs and names here.
  static AppConfig get config => switch (flavor) {
$cases
      };

$getters
}
''';
  }

  /// `lib/core/firebase/firebase_initializer.dart`.
  static const String firebaseInitializer = r'''
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../logger/app_logger.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  /// Initialises Firebase with the options in `lib/firebase_options.dart`.
  ///
  /// Until you run `flutterfire configure`, that file is a placeholder (or
  /// the current platform is not configured): Firebase is then skipped with
  /// a warning instead of crashing the app. Returns whether Firebase was
  /// initialised.
  static Future<bool> initialize() async {
    final FirebaseOptions options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError catch (error) {
      AppLogger.warning('Firebase is not configured: ${error.message}');
      return false;
    }
    await Firebase.initializeApp(options: options);
    return true;
  }
}
''';

  /// `lib/firebase_options.dart` placeholder, replaced by
  /// `flutterfire configure`. Written only if the file does not exist.
  static const String firebaseOptionsPlaceholder = r'''
// Placeholder generated by flutter_project_builder.
// Run `flutterfire configure` to replace it with your Firebase project's
// options: https://firebase.google.com/docs/flutter/setup
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Run `flutterfire configure` to generate lib/firebase_options.dart.',
      );
}
''';
}
