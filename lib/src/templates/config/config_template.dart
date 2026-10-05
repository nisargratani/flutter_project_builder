// ignore_for_file: public_member_api_docs

import '../../utils/string_utils.dart';

/// Template builders for the application entry points and flavors.
class ConfigTemplate {
  ConfigTemplate._();

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
        : '      title: AppStrings.appName,\n';
    final stringsImport =
        localization ? '' : "import 'core/constants/app_strings.dart';\n";
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

${stringsImport}import 'core/theme/app_theme.dart';
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
  static String bootstrap({required bool hive}) {
    if (!hive) {
      return '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Initialises services and starts the app.
///
/// Every entry point (`main.dart`, `main_<flavor>.dart`) calls this.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}
''';
    }
    return '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/hive_storage_service.dart';

/// Initialises services and starts the app.
///
/// Every entry point (`main.dart`, `main_<flavor>.dart`) calls this.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = HiveStorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const MyApp(),
    ),
  );
}
''';
  }

  /// `lib/main.dart`: the default entry point.
  static const String main = '''
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

  /// `lib/core/config/flavor_config.dart`.
  ///
  /// The first flavor is the default, so `lib/main.dart` works without
  /// selecting one explicitly.
  static String flavorConfig(List<String> flavors) {
    final getters = flavors
        .map(
          (f) => '  static bool get is${StringUtils.toPascalCase(f)} => '
              'flavor == Flavor.$f;',
        )
        .join('\n');
    return '''
enum Flavor { ${flavors.join(', ')} }

class FlavorConfig {
  FlavorConfig._();

  /// The active flavor. Set by `main_<flavor>.dart` before the app starts.
  static Flavor flavor = Flavor.${flavors.first};

$getters
}
''';
  }
}
