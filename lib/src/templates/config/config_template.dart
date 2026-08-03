// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for config.
class ConfigTemplate {
  ConfigTemplate._();

  static const String main = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Flutter App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
''';

  static const String flavorConfig = '''
enum Flavor { dev, stage, prod }

class FlavorConfig {
  FlavorConfig._();
  
  static late Flavor flavor;
  
  static bool get isDev => flavor == Flavor.dev;
  static bool get isStage => flavor == Flavor.stage;
  static bool get isProd => flavor == Flavor.prod;
}
''';
}
