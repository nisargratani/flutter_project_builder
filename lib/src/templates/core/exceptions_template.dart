// ignore_for_file: public_member_api_docs

/// Template strings for core.
class ExceptionsTemplate {
  ExceptionsTemplate._();

  static const String networkFailure = r'''
import '../errors/failure.dart';

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.statusCode});
  final int? statusCode;
}
''';

  static const String cacheFailure = r'''
import '../errors/failure.dart';

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
''';

  static const String unknownFailure = r'''
import '../errors/failure.dart';

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [this.exception]);
  final dynamic exception;
}
''';

  static const String validationFailure = r'''
import '../errors/failure.dart';

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
''';

  /// Builds `error_mapper.dart`. When [dio] is `true`, `DioException`s are
  /// mapped to `NetworkFailure`.
  static String errorMapper({required bool dio}) {
    final imports = dio
        ? "import 'package:dio/dio.dart';\n\n"
            "import '../errors/app_exception.dart';\n"
            "import '../errors/failure.dart';\n"
            "import 'network_failure.dart';\n"
            "import 'unknown_failure.dart';\n"
        : "import '../errors/app_exception.dart';\n"
            "import '../errors/failure.dart';\n"
            "import 'unknown_failure.dart';\n";
    final dioCase = dio ? _dioErrorCase : '';
    return '''
$imports
/// Converts any thrown object into a [Failure] the UI can render.
class ErrorMapper {
  ErrorMapper._();

  static Failure map(Object error) {
    if (error is Failure) {
      return error;
    }$dioCase
    if (error is AppException) {
      return UnknownFailure(error.message, error);
    }
    return UnknownFailure(error.toString(), error);
  }
}
''';
  }

  static const String _dioErrorCase = r'''
    if (error is DioException) {
      return NetworkFailure(
        error.message ?? 'Network request failed',
        statusCode: error.response?.statusCode,
      );
    }''';

  static const String failureMessageResolver = r'''
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
