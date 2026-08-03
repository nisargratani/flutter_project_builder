/// String manipulation utilities for template generation.
///
/// Provides case conversion, naming convention helpers, and
/// string formatting used by the code generators.
class StringUtils {
  StringUtils._();

  /// Converts a string to PascalCase.
  ///
  /// Example: `'user_profile'` → `'UserProfile'`
  static String toPascalCase(String input) => input
      .split(RegExp(r'[_\-\s]+'))
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join();

  /// Converts a string to camelCase.
  ///
  /// Example: `'user_profile'` → `'userProfile'`
  static String toCamelCase(String input) {
    final pascal = toPascalCase(input);
    if (pascal.isEmpty) return pascal;
    return '${pascal[0].toLowerCase()}${pascal.substring(1)}';
  }

  /// Converts a string to snake_case.
  ///
  /// Example: `'UserProfile'` → `'user_profile'`
  static String toSnakeCase(String input) => input
      .replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => match.start == 0
            ? match.group(0)!.toLowerCase()
            : '_${match.group(0)!.toLowerCase()}',
      )
      .replaceAll(RegExp(r'[_\-\s]+'), '_')
      .toLowerCase();

  /// Converts a string to Title Case.
  ///
  /// Example: `'user_profile'` → `'User Profile'`
  static String toTitleCase(String input) => input
      .split(RegExp(r'[_\-\s]+'))
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');

  /// Converts a string to kebab-case.
  ///
  /// Example: `'UserProfile'` → `'user-profile'`
  static String toKebabCase(String input) =>
      toSnakeCase(input).replaceAll('_', '-');

  /// Returns the singular form of a simple plural word.
  ///
  /// Handles basic English plurals only.
  /// Example: `'users'` → `'user'`
  static String toSingular(String input) {
    if (input.endsWith('ies')) {
      return '${input.substring(0, input.length - 3)}y';
    }
    if (input.endsWith('ses') || input.endsWith('xes')) {
      return input.substring(0, input.length - 2);
    }
    if (input.endsWith('s') && !input.endsWith('ss')) {
      return input.substring(0, input.length - 1);
    }
    return input;
  }

  /// Returns the plural form of a simple singular word.
  ///
  /// Handles basic English plurals only.
  /// Example: `'user'` → `'users'`
  static String toPlural(String input) {
    if (input.endsWith('y') &&
        !input.endsWith('ay') &&
        !input.endsWith('ey') &&
        !input.endsWith('oy') &&
        !input.endsWith('uy')) {
      return '${input.substring(0, input.length - 1)}ies';
    }
    if (input.endsWith('s') ||
        input.endsWith('x') ||
        input.endsWith('ch') ||
        input.endsWith('sh')) {
      return '${input}es';
    }
    return '${input}s';
  }
}
