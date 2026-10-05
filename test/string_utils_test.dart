import 'package:flutter_project_builder/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('toSnakeCase', () {
    test('converts common naming styles', () {
      expect(StringUtils.toSnakeCase('UserProfile'), 'user_profile');
      expect(StringUtils.toSnakeCase('userProfile'), 'user_profile');
      expect(StringUtils.toSnakeCase('user-profile'), 'user_profile');
      expect(StringUtils.toSnakeCase('User Profile'), 'user_profile');
      expect(StringUtils.toSnakeCase('user_profile'), 'user_profile');
    });

    test('keeps acronyms together', () {
      expect(StringUtils.toSnakeCase('HTTPClient'), 'http_client');
      expect(StringUtils.toSnakeCase('parseJSON'), 'parse_json');
    });
  });

  test('toPascalCase and toCamelCase', () {
    expect(StringUtils.toPascalCase('user_profile'), 'UserProfile');
    expect(StringUtils.toCamelCase('user_profile'), 'userProfile');
    expect(StringUtils.toCamelCase(''), '');
  });

  test('toTitleCase and toKebabCase', () {
    expect(StringUtils.toTitleCase('user_profile'), 'User Profile');
    expect(StringUtils.toKebabCase('UserProfile'), 'user-profile');
  });

  test('toSingular and toPlural', () {
    expect(StringUtils.toSingular('users'), 'user');
    expect(StringUtils.toSingular('categories'), 'category');
    expect(StringUtils.toSingular('boxes'), 'box');
    expect(StringUtils.toSingular('class'), 'class');
    expect(StringUtils.toPlural('user'), 'users');
    expect(StringUtils.toPlural('category'), 'categories');
    expect(StringUtils.toPlural('day'), 'days');
    expect(StringUtils.toPlural('box'), 'boxes');
  });

  group('isValidIdentifier', () {
    test('accepts identifiers', () {
      expect(StringUtils.isValidIdentifier('auth'), isTrue);
      expect(StringUtils.isValidIdentifier('user_profile2'), isTrue);
    });

    test('rejects invalid identifiers and reserved words', () {
      for (final input in ['', '1abc', '_private', 'a-b', '../x', 'class']) {
        expect(StringUtils.isValidIdentifier(input), isFalse, reason: input);
      }
    });
  });
}
