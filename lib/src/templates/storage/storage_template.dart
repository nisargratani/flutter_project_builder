// ignore_for_file: public_member_api_docs

/// Template strings for storage.
class StorageTemplate {
  StorageTemplate._();

  static const String storageService = r'''
abstract class StorageService {
  Future<void> init();
  Future<void> save<T>(String key, T value);
  T? read<T>(String key);
  Future<void> delete(String key);
  Future<void> clear();
  bool contains(String key);
}
''';

  static const String hiveStorageService = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'storage_service.dart';

/// Provides the app-wide [StorageService].
///
/// The service must be initialised before use, so this provider is
/// overridden in `bootstrap.dart` with an initialised instance:
///
/// ```dart
/// final storage = HiveStorageService();
/// await storage.init();
/// ProviderScope(
///   overrides: [storageServiceProvider.overrideWithValue(storage)],
///   child: const MyApp(),
/// );
/// ```
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden with an initialised '
    'StorageService (see bootstrap.dart).',
  );
});

class HiveStorageService implements StorageService {
  HiveStorageService({this.boxName = 'app_cache'});

  final String boxName;
  Box<dynamic>? _box;

  Box<dynamic> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('HiveStorageService.init() must be awaited before use.');
    }
    return box;
  }

  @override
  Future<void> init() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(boxName);
  }

  @override
  Future<void> save<T>(String key, T value) => _requireBox.put(key, value);

  @override
  T? read<T>(String key) => _requireBox.get(key) as T?;

  @override
  Future<void> delete(String key) => _requireBox.delete(key);

  @override
  Future<void> clear() async {
    await _requireBox.clear();
  }

  @override
  bool contains(String key) => _requireBox.containsKey(key);
}
''';
}
