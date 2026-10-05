// ignore_for_file: public_member_api_docs

/// Template strings for core.
class UtilsTemplate {
  UtilsTemplate._();

  static const String debouncer = r'''
import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  Debouncer({required this.milliseconds});
  final int milliseconds;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
''';

  static const String validators = r'''
class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
''';
}
