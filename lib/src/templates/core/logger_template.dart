// ignore_for_file: public_member_api_docs

/// Template strings for core.
class LoggerTemplate {
  LoggerTemplate._();

  static const String logLevel = r'''
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}
''';

  static const String appLogger = r'''
import 'package:flutter/foundation.dart';
import 'log_level.dart';

class AppLogger {
  AppLogger._();

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;

    final time = DateTime.now().toIso8601String();
    final prefix = _getPrefix(level);
    
    // Simple print for now. In a real app, use a package like logger.
    debugPrint('[$time] $prefix $message');
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return '🐛 DEBUG:';
      case LogLevel.info: return '💡 INFO:';
      case LogLevel.warning: return '⚠️ WARN:';
      case LogLevel.error: return '❌ ERROR:';
      case LogLevel.fatal: return '💀 FATAL:';
    }
  }
}
''';
}
