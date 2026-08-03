// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for router.
class RouterTemplate {
  RouterTemplate._();

  static const String appRouter = '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import 'navigation_logger.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    observers: [NavigationLogger()],
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.home,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Home'))),
      ),
    ],
  );
});
''';

  static const String routeNames = '''
class RouteNames {
  RouteNames._();
  
  static const String home = 'home';
  static const String counter = 'counter';
  static const String users = 'users';
}
''';

  static const String navigationLogger = '''
import 'package:flutter/material.dart';
import '../core/logger/app_logger.dart';

class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info('Navigation: pushed \${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info('Navigation: popped \${route.settings.name}');
  }
}
''';
}
