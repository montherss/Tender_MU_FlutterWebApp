import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<String> sendMessage(String message) async {
    final response = await _dio.post(
      '/chat',
      data: {'message': message},
      options: Options(
        contentType: Headers.jsonContentType,
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 5),
        ),
    );

    final data = response.data;
    if (data is Map && data['data'] != null) {
      return data['data'].toString();
    }
    if (data is String) return data;
    throw const AppException('استجابة الخادم غير صالحة');
  }
}
