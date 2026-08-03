// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for core.
class ErrorsTemplate {
  ErrorsTemplate._();

  static const String appException = '''
class AppException implements Exception {
  const AppException(this.message, [this.code, this.details]);

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() => 'AppException(message: \$message, code: \$code, details: \$details)';
}
''';

  static const String failure = '''
abstract class Failure {
  const Failure(this.message);
  final String message;
}
''';
}
