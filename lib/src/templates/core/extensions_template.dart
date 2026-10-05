// ignore_for_file: public_member_api_docs

/// Template strings for core.
class ExtensionsTemplate {
  ExtensionsTemplate._();

  static const String contextExtensions = r'''
import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
''';

  static const String stringExtensions = r'''
extension StringX on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  bool get isValidEmail {
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    return regex.hasMatch(this);
  }
}
''';

  static const String dateExtensions = r'''
import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String toFormattedString([String format = 'yyyy-MM-dd']) {
    return DateFormat(format).format(this);
  }
}
''';

  static const String asyncValueExtensions = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../exceptions/failure_message_resolver.dart';
import '../errors/failure.dart';

extension AsyncValueUIX on AsyncValue<dynamic> {
  void showSnackbarOnError(BuildContext context) {
    if (!isLoading && hasError) {
      final errorObj = error;
      String message = errorObj.toString();
      
      if (errorObj is Failure) {
        message = FailureMessageResolver.resolve(context, errorObj);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
''';
}
