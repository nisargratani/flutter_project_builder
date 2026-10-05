// ignore_for_file: public_member_api_docs

/// Template builders for the router.
class RouterTemplate {
  RouterTemplate._();

  /// `lib/router/app_router.dart`.
  static String appRouter({required bool samples}) {
    final imports = [
      if (samples)
        "import '../features/counter/presentation/pages/counter_page.dart';",
      "import '../features/home/presentation/pages/home_page.dart';",
      if (samples)
        "import '../features/users/presentation/pages/users_page.dart';",
      "import 'navigation_logger.dart';",
      "import 'route_names.dart';",
    ].join('\n');
    final sampleRoutes = samples
        ? '''
        routes: [
          GoRoute(
            path: RoutePaths.counter,
            name: RouteNames.counter,
            builder: (context, state) => const CounterPage(),
          ),
          GoRoute(
            path: RoutePaths.users,
            name: RouteNames.users,
            builder: (context, state) => const UsersPage(),
          ),
        ],
'''
        : '';
    return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

$imports

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.home,
    observers: [NavigationLogger()],
    routes: [
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
$sampleRoutes      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
''';
  }

  static const String routeNames = r'''
/// Route names, used with `context.goNamed(...)`.
class RouteNames {
  RouteNames._();

  static const String home = 'home';
  static const String counter = 'counter';
  static const String users = 'users';
}

/// Route paths. Child paths are relative to their parent route.
class RoutePaths {
  RoutePaths._();

  static const String home = '/';
  static const String counter = 'counter';
  static const String users = 'users';
}
''';

  static const String navigationLogger = r'''
import 'package:flutter/widgets.dart';

import '../core/logger/app_logger.dart';

class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info('Navigation: pushed ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.info('Navigation: popped ${route.settings.name}');
  }
}
''';
}
