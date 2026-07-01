import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../auth/auth_token_store.dart';
import '../auth/session_expired_handler.dart';
import '../constants/app_constants.dart';

class ApiClient {
  ApiClient(this._tokenStore, this._sessionExpiredHandler)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 60),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(AuthInterceptor(_tokenStore));
    dio.interceptors.add(
      UnauthorizedInterceptor(_sessionExpiredHandler),
    );
    dio.interceptors.add(ApiLoggingInterceptor());
  }

  final AuthTokenStore _tokenStore;
  final SessionExpiredHandler _sessionExpiredHandler;
  final Dio dio;
}

class UnauthorizedInterceptor extends Interceptor {
  const UnauthorizedInterceptor(this._sessionExpiredHandler);

  final SessionExpiredHandler _sessionExpiredHandler;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      final path = err.requestOptions.uri.path;
      // Attachment/file downloads may return 403 for permission issues, not session expiry.
      if (!_isProtectedFilePath(path)) {
        _sessionExpiredHandler.handleUnauthorized(
          statusCode: statusCode,
          path: path,
        );
      }
    }
    super.onError(err, handler);
  }
}

bool _isProtectedFilePath(String path) {
  return path.contains('/attachments/download') || path.contains('/uploads/');
}

class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.token;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
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
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint('┌──────────────── API RESPONSE ───────────────');
    debugPrint(
      '│ ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    debugPrint('│ Status: ${response.statusCode}');
    debugPrint('│ Data: ${_formatLogValue(response.data)}');
    debugPrint('└────────────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌──────────────── API ERROR ──────────────────');
    debugPrint('│ ${err.requestOptions.method} ${err.requestOptions.uri}');
    debugPrint('│ Status: ${err.response?.statusCode}');
    debugPrint('│ Message: ${err.message}');
    debugPrint('│ Data: ${_formatLogValue(err.response?.data)}');
    debugPrint('└────────────────────────────────────────────');
    super.onError(err, handler);
  }

  String _formatBody(dynamic data) {
    if (data == null) return 'null';
    if (data is FormData) {
      final fields = data.fields
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
      final files = data.files
          .map((entry) => '${entry.key}: ${entry.value.filename}')
          .join(', ');
      return 'FormData(fields: {$fields}, files: [$files])';
    }
    return _formatLogValue(data);
  }

  String _formatLogValue(dynamic value) {
    if (!kIsWeb) return value.toString();
    if (value is Map) {
      final keys = value.keys.take(8).join(', ');
      return 'Map(${value.length}){$keys${value.length > 8 ? ', ...' : ''}}';
    }
    if (value is List) {
      return 'List(${value.length})';
    }
    return value.toString();
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
