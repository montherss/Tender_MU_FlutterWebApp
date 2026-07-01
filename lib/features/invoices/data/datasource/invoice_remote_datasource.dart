import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/invoice_domain.dart';
import '../models/invoice_models.dart';

class InvoiceRemoteDataSource {
  const InvoiceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ExtractedInvoice> extractInvoice({
    required PlatformFile file,
    required void Function(int sent, int total) onProgress,
  }) async {
    final formData = FormData.fromMap({'file': _multipartFile(file)});
    final response = await _dio.post(
      '/invoice/extract',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 5),
      ),
      onSendProgress: onProgress,
    );
    return ExtractedInvoiceModel.fromJson(_responseMap(response.data));
  }

  MultipartFile _multipartFile(PlatformFile file) {
    if (file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    }
    final path = file.path;
    if (path == null) {
      throw const AppException('تعذر قراءة الملف المحدد');
    }
    return MultipartFile.fromFileSync(path, filename: file.name);
  }
}

Map<String, dynamic> _responseMap(dynamic value) {
  final data = value is Map && value['data'] != null ? value['data'] : value;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const AppException('استجابة الخادم غير صالحة');
}
