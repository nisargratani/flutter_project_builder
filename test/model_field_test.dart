import 'package:flutter_project_builder/src/generators/model_field.dart';
import 'package:test/test.dart';

void main() {
  test('defaults to id and name', () {
    expect(ModelField.parse(null).map((f) => f.dartType), ['int', 'String']);
    expect(ModelField.parse('  '), ModelField.defaults);
  });

  test('parses names, types and nullability', () {
    final fields = ModelField.parse(
      'id:int, title:String,price:double?,createdAt:DateTime,active:bool',
    );
    expect(fields.map((f) => '${f.name}:${f.dartType}'), [
      'id:int',
      'title:String',
      'price:double?',
      'createdAt:DateTime',
      'active:bool',
    ]);
  });

  test('builds JSON expressions for special types', () {
    final fields =
        ModelField.parse('price:double,due:DateTime?,count:int?,at:DateTime');
    expect(fields[0].fromJsonExpression, "(json['price'] as num).toDouble()");
    expect(
      fields[1].fromJsonExpression,
      "json['due'] == null ? null : DateTime.parse(json['due'] as String)",
    );
    expect(fields[2].fromJsonExpression, "json['count'] as int?");
    expect(fields[1].toJsonExpression, 'due?.toIso8601String()');
    expect(fields[3].toJsonExpression, 'at.toIso8601String()');
  });

  test('rejects invalid specs', () {
    for (final spec in [
      'id',
      'id:Integer',
      'Id:int',
      'class:String',
      'hashCode:int',
      'a:int,a:String',
      'a:b:c',
    ]) {
      expect(() => ModelField.parse(spec), throwsFormatException, reason: spec);
    }
  });
}
