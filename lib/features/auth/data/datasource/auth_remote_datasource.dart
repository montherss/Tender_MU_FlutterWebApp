import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/auth_domain.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String userName,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'userName': userName, 'password': password},
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    // Role can be at top level or nested inside a user/data object.
    final nested = data['user'] ?? data['data'] ?? data['userInfo'];
    final nestedMap = nested is Map ? nested : null;
    final role = (data['role'] ?? nestedMap?['role'])?.toString();
    return AuthSession(
      token: data['token']?.toString() ?? '',
      message: data['message']?.toString() ?? 'تم تسجيل الدخول',
      success: data['success'] == true,
      role: role,
      userName: userName,
    );
  }

  Future<void> logout() async {
    await _dio.post(
      '/auth/logout',
      options: Options(contentType: Headers.jsonContentType),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const AppException('استجابة الخادم غير صالحة');
}
