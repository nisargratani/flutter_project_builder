import '../utils/string_utils.dart';

/// A field of a generated entity or model, parsed from `name:Type`.
class ModelField {
  /// Creates a field.
  const ModelField(this.name, this.type, {this.nullable = false});

  /// Field name (lowerCamelCase).
  final String name;

  /// Base Dart type, one of [supportedTypes].
  final String type;

  /// Whether the field is nullable (`Type?`).
  final bool nullable;

  /// Types that can be (de)serialised without extra code.
  static const List<String> supportedTypes = [
    'String',
    'int',
    'double',
    'num',
    'bool',
    'DateTime',
  ];

  /// Fields used when no `--fields` are given.
  static const List<ModelField> defaults = [
    ModelField('id', 'int'),
    ModelField('name', 'String'),
  ];

  static const Set<String> _reservedMembers = {
    'hashCode',
    'runtimeType',
    'toString',
    'toJson',
    'fromJson',
    'copyWith',
    'noSuchMethod',
  };

  /// Parses a comma-separated spec such as `id:int,title:String,price:double?`.
  ///
  /// Throws a [FormatException] for unknown types, invalid or duplicate
  /// names.
  static List<ModelField> parse(String? spec) {
    if (spec == null || spec.trim().isEmpty) return defaults;
    final fields = <ModelField>[];
    for (final part in spec.split(',')) {
      final pieces = part.trim().split(':');
      if (pieces.length != 2) {
        throw FormatException(
          'Invalid field "$part". Use name:Type, e.g. "title:String".',
        );
      }
      final name = pieces[0].trim();
      var type = pieces[1].trim();
      final nullable = type.endsWith('?');
      if (nullable) type = type.substring(0, type.length - 1);

      if (!StringUtils.isValidIdentifier(name) ||
          name[0] != name[0].toLowerCase() ||
          _reservedMembers.contains(name)) {
        throw FormatException(
          'Invalid field name "$name". Use a lowerCamelCase identifier that '
          'is not a Dart keyword or an Object member.',
        );
      }
      if (!supportedTypes.contains(type)) {
        throw FormatException(
          'Unsupported type "$type" for field "$name". Supported types: '
          '${supportedTypes.join(', ')} (append ? for nullable).',
        );
      }
      if (fields.any((f) => f.name == name)) {
        throw FormatException('Duplicate field "$name".');
      }
      fields.add(ModelField(name, type, nullable: nullable));
    }
    return fields;
  }

  /// The declared Dart type, e.g. `double?`.
  String get dartType => nullable ? '$type?' : type;

  /// Expression reading this field from a `Map<String, dynamic> json`.
  String get fromJsonExpression {
    final value = "json['$name']";
    return switch (type) {
      'double' => nullable
          ? '($value as num?)?.toDouble()'
          : '($value as num).toDouble()',
      'DateTime' => nullable
          ? '$value == null ? null : DateTime.parse($value as String)'
          : 'DateTime.parse($value as String)',
      _ => '$value as $dartType',
    };
  }

  /// Expression writing this field into JSON.
  String get toJsonExpression => type == 'DateTime'
      ? (nullable ? '$name?.toIso8601String()' : '$name.toIso8601String()')
      : name;

  /// A JSON literal for sample item [index] (1-based), used in mock data.
  String sampleJson(int index) => switch (type) {
        'String' => "'${StringUtils.toTitleCase(StringUtils.toSnakeCase(name))}"
            " $index'",
        'int' || 'num' => '$index',
        'double' => '${index * 1.5}',
        'bool' => '${index.isOdd}',
        'DateTime' => "'2026-01-0${index}T00:00:00.000Z'",
        _ => 'null',
      };
}
