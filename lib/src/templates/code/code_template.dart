// ignore_for_file: public_member_api_docs

import '../../generators/model_field.dart';
import '../../utils/string_utils.dart';
import '../tests/test_template.dart';

/// Naming variants of a snake_case name.
class Names {
  Names(this.snake)
      : pascal = StringUtils.toPascalCase(snake),
        camel = StringUtils.toCamelCase(snake),
        title = StringUtils.toTitleCase(snake);

  final String snake;
  final String pascal;
  final String camel;
  final String title;

  /// Replaces `__snake__`, `__Pascal__`, `__camel__` and `__Title__`.
  String fill(String template, [String prefix = '']) => template
      .replaceAll('__${prefix}snake__', snake)
      .replaceAll('__${prefix}Pascal__', pascal)
      .replaceAll('__${prefix}camel__', camel)
      .replaceAll('__${prefix}Title__', title);
}

/// Templates for `generate feature|page|widget|provider|model`.
///
/// Static code is kept in raw strings with `__Token__` placeholders so the
/// emitted Dart is exactly what is written here (no `$` escaping).
class CodeTemplate {
  CodeTemplate._();

  static String _fill(String template, Map<String, String> tokens) {
    var result = template;
    tokens.forEach((key, value) => result = result.replaceAll(key, value));
    return result;
  }

  // ── Field helpers ──────────────────────────────────────────────────

  static String _fieldDeclarations(List<ModelField> fields) =>
      fields.map((f) => '  final ${f.dartType} ${f.name};').join('\n');

  static String _constructorParams(
          List<ModelField> fields, String prefix) =>
      fields
          .map((f) => f.nullable
              ? '    $prefix${f.name},'
              : '    required $prefix${f.name},')
          .join('\n');

  static String _equality(String className, List<ModelField> fields) {
    // Inside `==`, a field called `other` is shadowed by the parameter.
    final comparisons = fields
        .map((f) => f.name == 'other'
            ? 'other.other == this.other'
            : 'other.${f.name} == ${f.name}')
        .join(' &&\n          ');
    final hashed = fields.map((f) => f.name).join(', ');
    return '''
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is $className &&
          $comparisons;

  @override
  int get hashCode => Object.hashAll([$hashed]);''';
  }

  static String _fromJson(String className, List<ModelField> fields) {
    final args = fields
        .map((f) => '        ${f.name}: ${f.fromJsonExpression},')
        .join('\n');
    return '''
  factory $className.fromJson(Map<String, dynamic> json) => $className(
$args
      );''';
  }

  static String _toJson(List<ModelField> fields) {
    final entries = fields
        .map((f) => "        '${f.name}': ${f.toJsonExpression},")
        .join('\n');
    return '''
  Map<String, dynamic> toJson() => {
$entries
      };''';
  }

  static String _sampleJson(List<ModelField> fields, int index) {
    final entries =
        fields.map((f) => "'${f.name}': ${f.sampleJson(index)}").join(', ');
    return '{$entries}';
  }

  /// The field shown as a list tile title.
  static ModelField _titleField(List<ModelField> fields) => fields.firstWhere(
        (f) => f.type == 'String' && !f.nullable,
        orElse: () => fields.first,
      );

  static String _display(ModelField field, String receiver) =>
      field.type == 'String' && !field.nullable
          ? '$receiver.${field.name}'
          : "'\${$receiver.${field.name}}'";

  // ── Feature ────────────────────────────────────────────────────────

  static String entity(Names n, List<ModelField> fields) => '''
/// ${n.title} as the rest of the app sees it (domain entity).
class ${n.pascal}Entity {
  const ${n.pascal}Entity({
${_constructorParams(fields, 'this.')}
  });

${_fieldDeclarations(fields)}

${_equality('${n.pascal}Entity', fields)}
}
''';

  static String featureModel(Names n, List<ModelField> fields) => '''
import '../../domain/entities/${n.snake}_entity.dart';

/// Data-layer representation of [${n.pascal}Entity] with JSON support.
class ${n.pascal}Model extends ${n.pascal}Entity {
  const ${n.pascal}Model({
${_constructorParams(fields, 'super.')}
  });

${_fromJson('${n.pascal}Model', fields)}

${_toJson(fields)}
}
''';

  static String repository(Names n) => n.fill(r'''
import '../entities/__snake___entity.dart';

/// Contract implemented by the data layer.
///
/// Implementations throw a `Failure` when items cannot be loaded.
abstract interface class __Pascal__Repository {
  Future<List<__Pascal__Entity>> getAll();
}
''');

  static String remoteDataSource(
    Names n,
    List<ModelField> fields, {
    required bool dio,
  }) {
    final samples =
        [1, 2, 3].map((i) => '    ${_sampleJson(fields, i)},').join('\n');
    final dioImport = dio ? "import 'package:dio/dio.dart';\n\n" : '';
    final dioImpl = dio ? n.fill(r'''

/// Implementation backed by the shared Dio client (`apiClientProvider`).
class Dio__Pascal__RemoteDataSource implements __Pascal__RemoteDataSource {
  Dio__Pascal__RemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<__Pascal__Model>> fetchAll() async {
    final response = await _dio.get<List<dynamic>>('/__snake__');
    final data = response.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(__Pascal__Model.fromJson)
        .toList(growable: false);
  }
}
''') : '';
    return _fill(
      n.fill(r'''
__DIO_IMPORT__import '../models/__snake___model.dart';

abstract interface class __Pascal__RemoteDataSource {
  Future<List<__Pascal__Model>> fetchAll();
}

/// Offline data source with sample data, so the feature works before the
/// API exists.
class Mock__Pascal__RemoteDataSource implements __Pascal__RemoteDataSource {
  const Mock__Pascal__RemoteDataSource({
    this.delay = const Duration(milliseconds: 300),
  });

  final Duration delay;

  static const List<Map<String, dynamic>> _items = [
__SAMPLES__
  ];

  @override
  Future<List<__Pascal__Model>> fetchAll() async {
    await Future<void>.delayed(delay);
    return _items.map(__Pascal__Model.fromJson).toList(growable: false);
  }
}
__DIO_IMPL__'''),
      {
        '__DIO_IMPORT__': dioImport,
        '__SAMPLES__': samples,
        '__DIO_IMPL__': dioImpl,
      },
    );
  }

  static String repositoryImpl(Names n) => n.fill(r'''
import '../../../../core/exceptions/error_mapper.dart';
import '../../domain/entities/__snake___entity.dart';
import '../../domain/repository/__snake___repository.dart';
import '../datasource/__snake___remote_data_source.dart';

class __Pascal__RepositoryImpl implements __Pascal__Repository {
  __Pascal__RepositoryImpl(this._remoteDataSource);

  final __Pascal__RemoteDataSource _remoteDataSource;

  @override
  Future<List<__Pascal__Entity>> getAll() async {
    try {
      return await _remoteDataSource.fetchAll();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ErrorMapper.map(error), stackTrace);
    }
  }
}
''');

  static String featureProvider(Names n, {required bool dio}) {
    final dataSource = dio ? n.fill(r'''
/// Uses mock data. To call the API, return
/// `Dio__Pascal__RemoteDataSource(ref.watch(apiClientProvider))` instead
/// (import `core/network/api_client.dart`).
final __camel__RemoteDataSourceProvider = Provider<__Pascal__RemoteDataSource>(
  (ref) => const Mock__Pascal__RemoteDataSource(),
);''') : n.fill(r'''
/// Uses mock data. Override or replace it with a real data source.
final __camel__RemoteDataSourceProvider = Provider<__Pascal__RemoteDataSource>(
  (ref) => const Mock__Pascal__RemoteDataSource(),
);''');
    return _fill(
      n.fill(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/__snake___remote_data_source.dart';
import '../../data/repository/__snake___repository_impl.dart';
import '../../domain/entities/__snake___entity.dart';
import '../../domain/repository/__snake___repository.dart';

__DATA_SOURCE__

final __camel__RepositoryProvider = Provider<__Pascal__Repository>(
  (ref) => __Pascal__RepositoryImpl(ref.watch(__camel__RemoteDataSourceProvider)),
);

final __camel__Provider =
    AsyncNotifierProvider<__Pascal__Notifier, List<__Pascal__Entity>>(
  __Pascal__Notifier.new,
);

class __Pascal__Notifier extends AsyncNotifier<List<__Pascal__Entity>> {
  @override
  Future<List<__Pascal__Entity>> build() =>
      ref.watch(__camel__RepositoryProvider).getAll();

  /// Reloads the list. Errors are exposed through [state], never thrown.
  Future<void> refresh() async {
    state = const AsyncLoading<List<__Pascal__Entity>>();
    final result = await AsyncValue.guard(
      () => ref.read(__camel__RepositoryProvider).getAll(),
    );
    if (ref.mounted) state = result;
  }
}
'''),
      {'__DATA_SOURCE__': dataSource},
    );
  }

  static String featurePage(Names n, List<ModelField> fields) {
    final title = _titleField(fields);
    final rest = fields.where((f) => f != title).toList();
    final subtitle = rest.isEmpty
        ? ''
        : '\n                      subtitle: Text(${_display(rest.first, 'item')}),';
    return _fill(
      n.fill(r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/exceptions/failure_message_resolver.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../providers/__snake___provider.dart';

class __Pascal__Page extends ConsumerWidget {
  const __Pascal__Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(__camel__Provider);
    final notifier = ref.read(__camel__Provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('__Title__')),
      body: items.when(
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
            ? const EmptyWidget(message: 'Nothing here yet.')
            : RefreshIndicator(
                onRefresh: notifier.refresh,
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return ListTile(
                      title: Text(__TITLE__),__SUBTITLE__
                    );
                  },
                ),
              ),
      ),
    );
  }
}
'''),
      {
        '__TITLE__': _display(title, 'item'),
        '__SUBTITLE__': subtitle,
      },
    );
  }

  static String featureTest(
    Names n,
    List<ModelField> fields,
    String package,
  ) {
    final base = 'package:$package/features/${n.snake}';
    return _fill(
      n.fill(r'''
__HEADER__
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:__package__/core/errors/app_exception.dart';
import 'package:__package__/core/errors/failure.dart';
import '__BASE__/data/datasource/__snake___remote_data_source.dart';
import '__BASE__/data/models/__snake___model.dart';
import '__BASE__/presentation/providers/__snake___provider.dart';

class _FakeDataSource implements __Pascal__RemoteDataSource {
  _FakeDataSource(this._result);

  final Future<List<__Pascal__Model>> Function() _result;

  @override
  Future<List<__Pascal__Model>> fetchAll() => _result();
}

ProviderContainer _container(__Pascal__RemoteDataSource dataSource) {
  final container = ProviderContainer(
    overrides: [
      __camel__RemoteDataSourceProvider.overrideWithValue(dataSource),
    ],
    // Disable Riverpod's automatic retry so failures surface immediately.
    retry: (retryCount, error) => null,
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const json = __SAMPLE__;

  test('loads items from the data source', () async {
    final item = __Pascal__Model.fromJson(json);
    final container = _container(_FakeDataSource(() async => [item]));

    expect(await container.read(__camel__Provider.future), [item]);
  });

  test('maps data source errors to a Failure', () async {
    final container = _container(
      _FakeDataSource(() async => throw const AppException('boom')),
    );
    final subscription = container.listen(
      __camel__Provider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(__camel__Provider.future),
      throwsA(isA<Failure>()),
    );
  });

  test('mock data source returns sample items', () async {
    final items = await const Mock__Pascal__RemoteDataSource(
      delay: Duration.zero,
    ).fetchAll();
    expect(items, hasLength(3));
  });

  test('__Pascal__Model round-trips JSON', () {
    expect(__Pascal__Model.fromJson(json).toJson(), json);
  });
}
'''),
      {
        '__HEADER__': TestTemplate.header,
        '__package__': package,
        '__BASE__': base,
        '__SAMPLE__':
            _sampleJson(fields, 1).replaceFirst('{', '<String, dynamic>{'),
      },
    );
  }

  // ── Page ───────────────────────────────────────────────────────────

  static String page(Names n) => n.fill(r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class __Pascal__Page extends ConsumerWidget {
  const __Pascal__Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('__Title__')),
      body: const Center(child: Text('__Title__ page')),
    );
  }
}
''');

  static String pageTest(Names n, String importPath) => _fill(
        n.fill(r'''
__HEADER__
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '__IMPORT__';

void main() {
  testWidgets('__Pascal__Page renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: __Pascal__Page())),
    );

    expect(find.text('__Title__'), findsOneWidget);
    expect(find.text('__Title__ page'), findsOneWidget);
  });
}
'''),
        {'__HEADER__': TestTemplate.header, '__IMPORT__': importPath},
      );

  // ── Widget ─────────────────────────────────────────────────────────

  static String widget(Names n) => n.fill(r'''
import 'package:flutter/material.dart';

class __Pascal__ extends StatelessWidget {
  const __Pascal__({
    super.key,
    required this.title,
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
''');

  static String widgetTest(Names n, String importPath) => _fill(
        n.fill(r'''
__HEADER__
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '__IMPORT__';

void main() {
  testWidgets('__Pascal__ shows its title and reacts to taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: __Pascal__(title: 'Hello', onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    await tester.tap(find.byType(__Pascal__));
    expect(tapped, isTrue);
  });
}
'''),
        {'__HEADER__': TestTemplate.header, '__IMPORT__': importPath},
      );

  // ── Provider ───────────────────────────────────────────────────────

  static String notifierProvider(Names n) => n.fill(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final __camel__Provider = NotifierProvider<__Pascal__Notifier, __Pascal__State>(
  __Pascal__Notifier.new,
);

/// Immutable state of [__Pascal__Notifier]. Replace the fields with yours.
class __Pascal__State {
  const __Pascal__State({this.value = 0});

  final int value;

  __Pascal__State copyWith({int? value}) =>
      __Pascal__State(value: value ?? this.value);
}

class __Pascal__Notifier extends Notifier<__Pascal__State> {
  @override
  __Pascal__State build() => const __Pascal__State();

  void setValue(int value) => state = state.copyWith(value: value);

  void reset() => state = build();
}
''');

  static String asyncProvider(Names n) => n.fill(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final __camel__Provider = AsyncNotifierProvider<__Pascal__Notifier, String>(
  __Pascal__Notifier.new,
);

class __Pascal__Notifier extends AsyncNotifier<String> {
  @override
  Future<String> build() => _load();

  /// Replace with your data source (e.g. a repository provider).
  Future<String> _load() async => '__Title__';

  /// Reloads the value. Errors are exposed through [state], never thrown.
  Future<void> refresh() async {
    state = const AsyncLoading<String>();
    final result = await AsyncValue.guard(_load);
    if (ref.mounted) state = result;
  }
}
''');

  static String providerTest(
    Names n,
    String importPath, {
    required bool isAsync,
  }) {
    final body = isAsync ? n.fill(r'''
  test('__camel__Provider loads and refreshes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(await container.read(__camel__Provider.future), '__Title__');
    await container.read(__camel__Provider.notifier).refresh();
    expect(container.read(__camel__Provider).value, '__Title__');
  });''') : n.fill(r'''
  test('__camel__Provider updates and resets its state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(__camel__Provider.notifier);

    notifier.setValue(3);
    expect(container.read(__camel__Provider).value, 3);
    notifier.reset();
    expect(container.read(__camel__Provider).value, 0);
  });''');
    return _fill(
      r'''
__HEADER__
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '__IMPORT__';

void main() {
__BODY__
}
''',
      {
        '__HEADER__': TestTemplate.header,
        '__IMPORT__': importPath,
        '__BODY__': body,
      },
    );
  }

  // ── Model ──────────────────────────────────────────────────────────

  static String model(Names n, List<ModelField> fields) {
    final className = '${n.pascal}Model';
    final copyParams =
        fields.map((f) => '    ${f.type}? ${f.name},').join('\n');
    final copyArgs = fields
        .map((f) => '        ${f.name}: ${f.name} ?? this.${f.name},')
        .join('\n');
    final toStringFields =
        fields.map((f) => '${f.name}: \$${f.name}').join(', ');
    return '''
/// ${n.title} with JSON (de)serialisation and value equality.
class $className {
  const $className({
${_constructorParams(fields, 'this.')}
  });

${_fromJson(className, fields)}

${_fieldDeclarations(fields)}

${_toJson(fields)}

  $className copyWith({
$copyParams
  }) =>
      $className(
$copyArgs
      );

${_equality(className, fields)}

  @override
  String toString() => '$className($toStringFields)';
}
''';
  }

  static String modelTest(
    Names n,
    List<ModelField> fields,
    String importPath,
  ) =>
      _fill(
        n.fill(r'''
__HEADER__
import 'package:flutter_test/flutter_test.dart';

import '__IMPORT__';

void main() {
  const json = __SAMPLE__;

  test('__Pascal__Model round-trips JSON', () {
    expect(__Pascal__Model.fromJson(json).toJson(), json);
  });

  test('__Pascal__Model has value equality', () {
    expect(__Pascal__Model.fromJson(json), __Pascal__Model.fromJson(json));
    expect(
      __Pascal__Model.fromJson(json).copyWith(),
      __Pascal__Model.fromJson(json),
    );
  });
}
'''),
        {
          '__HEADER__': TestTemplate.header,
          '__IMPORT__': importPath,
          '__SAMPLE__':
              _sampleJson(fields, 1).replaceFirst('{', '<String, dynamic>{'),
        },
      );

  // ── Routes ─────────────────────────────────────────────────────────

  static String route(Names n) => n.fill(r'''
          GoRoute(
            path: RoutePaths.__camel__,
            name: RouteNames.__camel__,
            builder: (context, state) => const __Pascal__Page(),
          ),
''');
}
