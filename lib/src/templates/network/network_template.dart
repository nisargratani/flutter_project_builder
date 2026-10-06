// ignore_for_file: public_member_api_docs

/// Template strings for network.
class NetworkTemplate {
  NetworkTemplate._();

  static const String apiClient = r'''
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_interceptors.dart';

/// Shared HTTP client configured from the active [AppConfig].
final apiClientProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  if (config.enableNetworkLogs) {
    dio.interceptors.add(LoggingInterceptor());
  }

  ref.onDispose(dio.close);
  return dio;
});
''';

  static const String apiInterceptors = r'''
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger/app_logger.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.ref);
  final Ref ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add auth token here
    // options.headers['Authorization'] = 'Bearer token';
    super.onRequest(options, handler);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('=> ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info('<= ${response.statusCode} ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error('<= Error ${err.response?.statusCode} ${err.requestOptions.uri}');
    super.onError(err, handler);
  }
}
''';
}
