import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> createUser({
    required String userName,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post(
      '/auth/createUser',
      data: {'userName': userName, 'password': password, 'role': role},
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    if (data['success'] == false) {
      throw AppException(
        data['message']?.toString() ?? 'تعذر إنشاء المستخدم',
      );
    }
  }

  Future<void> addSupplier({
    required String externalSupplierId,
    required String name,
    required String type,
    required String contactInfo,
    required int isManual,
  }) async {
    final response = await _dio.post(
      '/Suppliers/addSupplier',
      data: {
        'externalSupplierId': externalSupplierId,
        'name': name,
        'type': type,
        'contactInfo': contactInfo,
        'isManual': isManual,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = _asMap(response.data);
    if (data['success'] == false) {
      throw AppException(
        data['message']?.toString() ?? 'تعذر إضافة المورد',
      );
    }
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return {};
}
