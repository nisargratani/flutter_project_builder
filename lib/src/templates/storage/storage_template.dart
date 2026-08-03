// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for storage.
class StorageTemplate {
  StorageTemplate._();

  static const String storageService = '''
abstract class StorageService {
  Future<void> init();
  Future<void> save<T>(String key, T value);
  T? read<T>(String key);
  Future<void> delete(String key);
  Future<void> clear();
  bool contains(String key);
}
''';

  static const String hiveStorageService = '''
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return HiveStorageService();
});

class HiveStorageService implements StorageService {
  late Box _box;
  static const String _boxName = 'app_cache';

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<void> save<T>(String key, T value) async {
    await _box.put(key, value);
  }

  @override
  T? read<T>(String key) {
    return _box.get(key) as T?;
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  @override
  bool contains(String key) {
    return _box.containsKey(key);
  }
}
''';
}
