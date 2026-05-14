import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 60),
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(ApiLoggingInterceptor());
  }

  final Dio dio;
}

class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌──────────────── API REQUEST ────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    debugPrint('│ Headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('│ Query: ${options.queryParameters}');
    }
    debugPrint('│ Body: ${_formatBody(options.data)}');
    debugPrint('└────────────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('┌──────────────── API RESPONSE ───────────────');
    debugPrint('│ ${response.requestOptions.method} ${response.requestOptions.uri}');
    debugPrint('│ Status: ${response.statusCode}');
    debugPrint('│ Data: ${response.data}');
    debugPrint('└────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌──────────────── API ERROR ──────────────────');
    debugPrint('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
    debugPrint('│ Status: ${err.response?.statusCode}');
    debugPrint('│ Message: ${err.message}');
    debugPrint('│ Data: ${err.response?.data}');
    debugPrint('└────────────────────────────────────────────');
    super.onError(err, handler);
  }

  String _formatBody(dynamic data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fields = data.fields.map((entry) => '${entry.key}: ${entry.value}').join(', ');
      final files = data.files.map((entry) => '${entry.key}: ${entry.value.filename}').join(', ');
      return 'FormData(fields: {$fields}, files: [$files])';
    }
    return data.toString();
  }
}

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

AppException mapDioException(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return AppException(data['message'].toString());
    }
    return AppException(error.message ?? 'تعذر الاتصال بالخادم');
  }
  return AppException('حدث خطأ غير متوقع');
}
