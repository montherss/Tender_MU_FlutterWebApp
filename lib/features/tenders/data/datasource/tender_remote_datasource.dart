import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/tender_domain.dart';
import '../models/tender_models.dart';

class TenderRemoteDataSource {
  const TenderRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TenderSummary>> getTenders() async {
    final response = await _dio.get('/tenders');
    final list = response.data is List
        ? response.data as List
        : response.data['data'] as List? ?? const [];
    return list.map((e) => TenderSummaryModel.fromJson(_asMap(e))).toList();
  }

  Future<TenderDetails> getTender(int id) async {
    final response = await _dio.get('/tenders/$id');
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return TenderDetailsModel.fromJson(_asMap(data));
  }

  Future<void> createTender(CreateTenderRequest request) async {
    await _dio.post('/tenders/createTender', data: request.toJson());
  }

  Future<void> addFinancialCommitmentNo(int tenderId, String value) async {
    await _dio.post(
      '/tenders/addFinancialCommitmentNo',
      data: {'tenderId': tenderId, 'financialCommitmentNo': value},
    );
  }

  Future<void> addTenderItems(int tenderId, List<TenderItem> items) async {
    await _dio.post(
      '/tenders/addTendersItems',
      data: {
        'tenderId': tenderId,
        'items': items.map(TenderItemModel.toJson).toList(),
      },
    );
  }

  Future<void> uploadAttachments({
    required int tenderId,
    required List<PlatformFile> files,
    required void Function(int sent, int total) onProgress,
  }) async {
    final formData = FormData.fromMap({
      'tenderId': tenderId,
      'files': files.map((file) {
        if (file.bytes != null) {
          return MultipartFile.fromBytes(file.bytes!, filename: file.name);
        }
        return MultipartFile.fromFileSync(file.path!, filename: file.name);
      }).toList(),
    });
    await _dio.post(
      '/attachments/upload',
      data: formData,
      onSendProgress: onProgress,
    );
  }

  Future<void> deleteAttachment(int id) async {
    await _dio.delete(
      '/attachments/deleteAttachment',
      data: FormData.fromMap({'id': id}),
    );
  }

  Future<void> addTenderCategoryAndType(
    int tenderId,
    String category,
    String? type,
  ) async {
    await _dio.post(
      '/tenders/addTenderCategoryAndType',
      data: {
        'tenderCategory': category.trim(),
        'tenderType': type?.trim(),
        'tenderId': tenderId,
      },
    );
  }

  Future<void> updateBasicInfo(int tenderId, BasicInfoRequest request) async {
    await _dio.post('/tenders/sub-data', data: request.toJson(tenderId));
  }

  Future<void> changeTechnicalAssignment(int itemId, int value) async {
    await _dio.post(
      '/tenders/changeTechnicalAssignment',
      data: {'itemId': itemId, 'technicalAssignment': value},
    );
  }

  Future<void> changeMainAssignment(int itemId, int value) async {
    await _dio.post(
      '/tenders/changeMainAssignmentRequest',
      data: {'itemId': itemId, 'mainAssignment': value},
    );
  }

  Future<List<Supplier>> searchSuppliers(String name) async {
    final response = await _dio.get(
      '/Suppliers/search',
      queryParameters: {'name': name},
    );
    final list = _responseList(response.data);
    return list.map((e) => SupplierModel.fromJson(_asMap(e))).toList();
  }

  Future<List<Supplier>> getSuppliersByTenderId(int tenderId) async {
    final response = await _dio.get(
      '/Suppliers/getSuppliersByTenderId/$tenderId',
    );
    final list = _responseList(response.data);
    return list.map((e) => SupplierModel.fromJson(_asMap(e))).toList();
  }

  Future<void> addSupplierToTender({
    required int tenderId,
    required int supplierId,
  }) async {
    await _dio.post(
      '/Suppliers/addSupplierToTender',
      data: {'tenderId': tenderId, 'supplierId': supplierId},
    );
  }

  Future<List<SupplierItemOffer>> getSupplierItemOffersByTenderId(
    int tenderId,
  ) async {
    final response = await _dio.get(
      '/Suppliers/getSupplierItemOffersByTenderId/$tenderId',
    );
    final list = _responseList(response.data);
    return list.map((e) => SupplierItemOfferModel.fromJson(_asMap(e))).toList();
  }

  Future<TenderAnalysis> getAnalysisByTenderId(int tenderId) async {
    final response = await _dio.post(
      '/Suppliers/getAnalysisByTenderId',
      data: FormData.fromMap({'tenderId': tenderId}),
      options: Options(
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 2),
      ),
    );
    return TenderAnalysisModel.fromJson(_asMap(response.data));
  }

  Future<List<SupplierItemOffer>> addSupplierItemOffer(
    SupplierItemOfferRequest request,
  ) async {
    final response = await _dio.post(
      '/Suppliers/addSupplierItemOffer',
      data: request.toJson(),
    );
    final list = _responseList(response.data);
    return list.map((e) => SupplierItemOfferModel.fromJson(_asMap(e))).toList();
  }

  Future<void> addItemAssignment(ItemAssignmentRequest request) async {
    await _dio.post('/tenders/addItemAssignment', data: request.toJson());
  }

  Future<List<ItemAssignment>> getItemAssignmentsByTenderId(
    int tenderId,
  ) async {
    final response = await _dio.get('/tenders/getItemAssignmentById/$tenderId');
    final list = _responseList(response.data);
    return list.map((e) => ItemAssignmentModel.fromJson(_asMap(e))).toList();
  }
}

List<dynamic> _responseList(dynamic value) {
  if (value is List) return value;
  if (value is Map) {
    for (final key in ['data', 'Data', 'result', 'results']) {
      final nested = value[key];
      if (nested is List) return nested;
      if (nested is Map) return [nested];
    }
    if (value.containsKey('id')) return [value];
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const AppException('استجابة الخادم غير صالحة');
}
