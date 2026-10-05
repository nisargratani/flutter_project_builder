// ignore_for_file: public_member_api_docs

/// Template builders for the home page and the sample features.
class FeatureTemplate {
  FeatureTemplate._();

  // ── Home ────────────────────────────────────────────────────────────

  /// `lib/features/home/presentation/pages/home_page.dart`.
  static String homePage({required bool samples}) {
    if (!samples) {
      return r'''
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: const Center(
        child: Text('Start building your features in lib/features/'),
      ),
    );
  }
}
''';
    }
    return r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../router/route_names.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.exposure_plus_1),
            title: const Text('Counter'),
            subtitle: const Text('Synchronous state with Notifier'),
            onTap: () => context.goNamed(RouteNames.counter),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Users'),
            subtitle: const Text('Async data through all Clean Architecture layers'),
            onTap: () => context.goNamed(RouteNames.users),
          ),
        ],
      ),
    );
  }
}
''';
  }

  // ── Counter ─────────────────────────────────────────────────────────

  static const String counterEntity = r'''
/// Immutable counter value (domain entity).
class Counter {
  const Counter(this.value);

  final int value;

  Counter increment() => Counter(value + 1);

  Counter decrement() => Counter(value - 1);
}
''';

  static const String counterProvider = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/counter.dart';

final counterProvider = NotifierProvider<CounterNotifier, Counter>(
  CounterNotifier.new,
);

class CounterNotifier extends Notifier<Counter> {
  @override
  Counter build() => const Counter(0);

  void increment() => state = state.increment();

  void decrement() => state = state.decrement();

  void reset() => state = const Counter(0);
}
''';

  static const String counterPage = r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/counter_provider.dart';

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    final notifier = ref.read(counterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: notifier.reset,
          ),
        ],
      ),
      body: Center(
        child: Text(
          '${counter.value}',
          key: const Key('counter_value'),
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'increment',
            tooltip: 'Increment',
            onPressed: notifier.increment,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'decrement',
            tooltip: 'Decrement',
            onPressed: notifier.decrement,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
''';

  // ── Users ───────────────────────────────────────────────────────────

  static const String userEntity = r'''
/// A user as the rest of the app sees it (domain entity).
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  final int id;
  final String name;
  final String email;
}
''';

  static const String userRepository = r'''
import '../entities/user.dart';

/// Contract implemented by the data layer.
///
/// Implementations throw a `Failure` when users cannot be loaded.
abstract interface class UserRepository {
  Future<List<User>> getUsers();
}
''';

  static const String userModel = r'''
import '../../domain/entities/user.dart';

/// Data-layer representation of [User] with JSON (de)serialisation.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  /// Throws a [FormatException] if [json] does not have the expected shape.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    if (id is! int || name is! String || email is! String) {
      throw FormatException('Invalid user JSON: $json');
    }
    return UserModel(id: id, name: name, email: email);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
''';

  /// `user_remote_data_source.dart`. Includes a Dio implementation when
  /// [dio] is `true`.
  static String userRemoteDataSource({required bool dio}) {
    final dioImport = dio ? "import 'package:dio/dio.dart';\n\n" : '';
    final dioImpl = dio
        ? r'''

/// Real implementation backed by the shared Dio client.
///
/// Swap it in via `userRemoteDataSourceProvider` once your API is ready.
class DioUserRemoteDataSource implements UserRemoteDataSource {
  DioUserRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<UserModel>> fetchUsers() async {
    final response = await _dio.get<List<dynamic>>('/users');
    final data = response.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList(growable: false);
  }
}
'''
        : '';
    return '''
${dioImport}import '../models/user_model.dart';

abstract interface class UserRemoteDataSource {
  Future<List<UserModel>> fetchUsers();
}

/// Offline data source returning canned data after a short delay, so the
/// sample works without a backend.
class MockUserRemoteDataSource implements UserRemoteDataSource {
  const MockUserRemoteDataSource({
    this.delay = const Duration(milliseconds: 300),
  });

  final Duration delay;

  static const List<Map<String, dynamic>> _users = [
    {'id': 1, 'name': 'Ada Lovelace', 'email': 'ada@example.com'},
    {'id': 2, 'name': 'Alan Turing', 'email': 'alan@example.com'},
    {'id': 3, 'name': 'Grace Hopper', 'email': 'grace@example.com'},
  ];

  @override
  Future<List<UserModel>> fetchUsers() async {
    await Future<void>.delayed(delay);
    return _users.map(UserModel.fromJson).toList(growable: false);
  }
}
$dioImpl''';
  }

  static const String userRepositoryImpl = r'''
import '../../../../core/exceptions/error_mapper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/user_repository.dart';
import '../datasource/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource);

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<List<User>> getUsers() async {
    try {
      return await _remoteDataSource.fetchUsers();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ErrorMapper.map(error), stackTrace);
    }
  }
}
''';

  static const String usersProvider = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/user_remote_data_source.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository/user_repository.dart';

/// Override this provider to switch data sources (or to fake it in tests).
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>(
  (ref) => const MockUserRemoteDataSource(),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider)),
);

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(
  UsersNotifier.new,
);

class UsersNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() => ref.watch(userRepositoryProvider).getUsers();

  /// Reloads the list. Errors are exposed through [state], never thrown.
  Future<void> refresh() async {
    state = const AsyncLoading<List<User>>();
    final result = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).getUsers(),
    );
    if (ref.mounted) state = result;
  }
}
''';

  static const String usersPage = r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/exceptions/failure_message_resolver.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../providers/users_provider.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final notifier = ref.read(usersProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is Failure
                      ? FailureMessageResolver.resolve(context, error)
                      : 'Something went wrong.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(text: 'Retry', onPressed: notifier.refresh),
              ],
            ),
          ),
        ),
        data: (list) => list.isEmpty
            ? const EmptyWidget(message: 'No users yet.')
            : RefreshIndicator(
                onRefresh: notifier.refresh,
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.name.isEmpty ? '?' : user.name.characters.first,
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
''';
}
