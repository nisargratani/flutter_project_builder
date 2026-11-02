import 'dart:io';

import 'package:path/path.dart' as p;

/// Public type names that generated code can see, read from the installed
/// Flutter SDK's sources.
///
/// A generated class with one of these names would clash (ambiguous
/// import) or shadow the SDK type that the templates themselves use.
class SdkTypeNames {
  SdkTypeNames._();

  /// Public `dart:core` types, visible in every Dart file.
  static const Set<String> dartCore = {
    'BigInt', 'Comparable', 'Comparator', 'DateTime', 'Deprecated', //
    'Duration', 'Enum', 'Error', 'Exception', 'Expando', 'Finalizer',
    'Function', 'Future', 'Invocation', 'Iterable', 'Iterator', 'List', 'Map',
    'MapEntry', 'Match', 'Never', 'Null', 'Object', 'Pattern', 'Record',
    'RegExp', 'RegExpMatch', 'RuneIterator', 'Runes', 'Set', 'Sink',
    'StackTrace', 'Stopwatch', 'Stream', 'String', 'StringBuffer', 'StringSink',
    'Symbol', 'Type', 'Uri', 'UriData', 'WeakReference',
  };

  /// Types that `package:flutter/widgets.dart` re-exports from packages
  /// outside the SDK (`characters`), which cannot be read here.
  static const Set<String> _externalExports = {'Characters', 'CharacterRange'};

  static final RegExp _declaration = RegExp(
    '^(?:abstract |base |final |sealed |interface |mixin )*'
    r'(?:class|mixin|enum|typedef|extension type) ([A-Z]\w*)',
    multiLine: true,
  );

  static final RegExp _export =
      RegExp(r'''^export\s+['"]([^'"]+)['"]([^;]*);''', multiLine: true);

  static final RegExp _part =
      RegExp(r'''^part\s+['"]([^'"]+)['"]\s*;''', multiLine: true);

  /// Public types visible through `package:flutter/material.dart` (the
  /// library generated code imports), including what it re-exports from
  /// other Flutter libraries and `dart:ui`, for the Flutter SDK at
  /// [flutterRoot]. Empty if the SDK sources cannot be found.
  static Set<String> material(String flutterRoot) {
    final library =
        p.join(flutterRoot, 'packages', 'flutter', 'lib', 'material.dart');
    if (!File(library).existsSync()) return <String>{};
    return {
      ..._ExportResolver(flutterRoot).namespace(library),
      ..._externalExports,
    };
  }

  /// Public types declared in [source] (top-level declarations only).
  static Iterable<String> declaredIn(String source) =>
      _declaration.allMatches(source).map((m) => m[1]!);
}

/// Follows `export` directives (with `show`/`hide`) through the SDK.
class _ExportResolver {
  _ExportResolver(this.flutterRoot);

  final String flutterRoot;
  final Map<String, Set<String>> _cache = {};

  /// The public types the library at [path] declares or exports.
  Set<String> namespace(String path) {
    final cached = _cache[path];
    if (cached != null) return cached;
    _cache[path] = const {}; // Breaks export cycles.

    final file = File(path);
    if (!file.existsSync()) return const {};
    final source = file.readAsStringSync();
    final names = {...SdkTypeNames.declaredIn(source)};
    for (final part in SdkTypeNames._part.allMatches(source)) {
      final partFile = File(p.join(p.dirname(path), part[1]));
      if (partFile.existsSync()) {
        names.addAll(SdkTypeNames.declaredIn(partFile.readAsStringSync()));
      }
    }
    for (final export in SdkTypeNames._export.allMatches(source)) {
      final combinators =
          export[2]!.replaceAll(RegExp(r'//[^\n]*'), ' ').trim();
      final show = _names(combinators, 'show');
      final hide = _names(combinators, 'hide');
      final target = _resolve(path, export[1]!);
      if (target == null) {
        // A package outside the SDK: only `show` tells what it exports.
        names.addAll(show);
        continue;
      }
      var exported = namespace(target);
      if (show.isNotEmpty) exported = exported.intersection(show);
      names.addAll(exported.difference(hide));
    }
    return _cache[path] = names;
  }

  /// The names after [keyword] (`show` or `hide`) in [combinators].
  static Set<String> _names(String combinators, String keyword) => {
        for (final match
            in RegExp('\\b$keyword\\s+([\\w\\s,]+?)(?=\\s+(?:show|hide)\\b|\$)')
                .allMatches(combinators))
          ...match[1]!.split(',').map((name) => name.trim()),
      }..remove('');

  String? _resolve(String from, String uri) {
    if (uri.startsWith('package:flutter/')) {
      return p.joinAll([
        flutterRoot,
        'packages',
        'flutter',
        'lib',
        ...uri.substring('package:flutter/'.length).split('/'),
      ]);
    }
    if (uri == 'dart:ui') {
      return p.join(
        flutterRoot,
        'bin',
        'cache',
        'pkg',
        'sky_engine',
        'lib',
        'ui',
        'ui.dart',
      );
    }
    if (uri.contains(':')) return null;
    return p.normalize(p.joinAll([p.dirname(from), ...uri.split('/')]));
  }
}
