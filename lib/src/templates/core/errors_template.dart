// ignore_for_file: public_member_api_docs

/// Template strings for core.
class ErrorsTemplate {
  ErrorsTemplate._();

  static const String appException = r'''
class AppException implements Exception {
  const AppException(this.message, [this.code, this.details]);

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() => 'AppException(message: $message, code: $code, details: $details)';
}
''';

  static const String failure = r'''
/// Base type for all failures surfaced to the presentation layer.
///
/// Implements [Exception] so failures can be thrown from repositories and
/// caught by `AsyncValue.guard` / `AsyncNotifier`.
abstract class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => 'Failure: $message';
}
''';
}
