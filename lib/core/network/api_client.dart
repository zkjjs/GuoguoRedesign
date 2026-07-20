import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import 'auth_interceptor.dart';
import 'redacting_log_interceptor.dart';

final class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    required SessionRefresher sessionRefresher,
    String? xToken,
    RedactedLogSink? logSink,
    Dio? dio,
  }) : dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    this.dio.interceptors.add(
      AuthInterceptor(
        dio: this.dio,
        tokenStore: tokenStore,
        sessionRefresher: sessionRefresher,
        xToken: xToken,
      ),
    );
    if (logSink != null) {
      this.dio.interceptors.add(RedactingLogInterceptor(logSink));
    }
  }

  final Dio dio;
}
