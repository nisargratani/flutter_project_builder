// ignore_for_file: public_member_api_docs, use_raw_strings, unnecessary_string_escapes

/// Template strings for core.
class ExceptionsTemplate {
  ExceptionsTemplate._();

  static const String networkFailure = '''
import '../errors/failure.dart';

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.statusCode});
  final int? statusCode;
}
''';

  static const String cacheFailure = '''
import '../errors/failure.dart';

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
''';

  static const String unknownFailure = '''
import '../errors/failure.dart';

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [this.exception]);
  final dynamic exception;
}
''';

  static const String validationFailure = '''
import '../errors/failure.dart';

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
''';

  static const String errorMapper = '''
import '../errors/app_exception.dart';
import '../errors/failure.dart';
import 'unknown_failure.dart';

class ErrorMapper {
  ErrorMapper._();

  static Failure map(Object error) {
    if (error is Failure) {
      return error;
    }
    if (error is AppException) {
      return UnknownFailure(error.message, error);
    }
    // Add specific mappers here (e.g. DioException -> NetworkFailure)
    return UnknownFailure(error.toString(), error);
  }
}
''';

  static const String failureMessageResolver = '''
import 'package:flutter/widgets.dart';

import '../errors/failure.dart';
import 'unknown_failure.dart';
import 'validation_failure.dart';
import 'network_failure.dart';
import 'cache_failure.dart';

class FailureMessageResolver {
  FailureMessageResolver._();

  static String resolve(BuildContext context, Failure failure) {
    // You can use context here for localization (e.g. AppLocalizations.of(context))
    switch (failure) {
      case NetworkFailure():
        return 'Network connection issue. Please try again.';
      case CacheFailure():
        return 'Failed to load local data.';
      case ValidationFailure():
        return failure.message;
      case UnknownFailure():
        return 'An unexpected error occurred.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
''';
}
