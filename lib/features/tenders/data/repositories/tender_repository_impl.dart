import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/tender_domain.dart';
import '../datasource/tender_remote_datasource.dart';

class TenderRepositoryImpl implements TenderRepository {
  const TenderRepositoryImpl(this._remoteDataSource);

  final TenderRemoteDataSource _remoteDataSource;

  @override
  Future<List<TenderSummary>> getTenders() =>
      _guard(_remoteDataSource.getTenders);

  @override
  Future<TenderDetails> getTender(int id) =>
      _guard(() => _remoteDataSource.getTender(id));

  @override
  Future<void> createTender(CreateTenderRequest request) =>
      _guard(() => _remoteDataSource.createTender(request));

  @override
  Future<void> addFinancialCommitmentNo(int tenderId, String value) {
    return _guard(
      () => _remoteDataSource.addFinancialCommitmentNo(tenderId, value),
    );
  }

  @override
  Future<void> addTenderItems(int tenderId, List<TenderItem> items) {
    return _guard(() => _remoteDataSource.addTenderItems(tenderId, items));
  }

  @override
  Future<void> uploadAttachments({
    required int tenderId,
    required List<PlatformFile> files,
    required void Function(int sent, int total) onProgress,
  }) {
    return _guard(
      () => _remoteDataSource.uploadAttachments(
        tenderId: tenderId,
        files: files,
        onProgress: onProgress,
      ),
    );
  }

  @override
  Future<void> addTenderCategoryAndType(
    int tenderId,
    String category,
    String? type,
  ) {
    return _guard(
      () =>
          _remoteDataSource.addTenderCategoryAndType(tenderId, category, type),
    );
  }

  @override
  Future<void> updateBasicInfo(int tenderId, BasicInfoRequest request) {
    return _guard(() => _remoteDataSource.updateBasicInfo(tenderId, request));
  }

  @override
  Future<void> changeTechnicalAssignment(int itemId, int value) {
    return _guard(
      () => _remoteDataSource.changeTechnicalAssignment(itemId, value),
    );
  }

  @override
  Future<void> changeMainAssignment(int itemId, int value) {
    return _guard(() => _remoteDataSource.changeMainAssignment(itemId, value));
  }

  @override
  Future<List<Supplier>> getSuppliers({int page = 0, int size = 5}) {
    return _guard(() => _remoteDataSource.getSuppliers(page: page, size: size));
  }

  @override
  Future<List<Supplier>> getSuppliersByTenderId(int tenderId) {
    return _guard(() => _remoteDataSource.getSuppliersByTenderId(tenderId));
  }

  @override
  Future<void> addSupplierToTender({
    required int tenderId,
    required int supplierId,
  }) {
    return _guard(
      () => _remoteDataSource.addSupplierToTender(
        tenderId: tenderId,
        supplierId: supplierId,
      ),
    );
  }

  @override
  Future<List<SupplierItemOffer>> getSupplierItemOffersByTenderId(
    int tenderId,
  ) {
    return _guard(
      () => _remoteDataSource.getSupplierItemOffersByTenderId(tenderId),
    );
  }

  @override
  Future<List<SupplierItemOffer>> addSupplierItemOffer(
    SupplierItemOfferRequest request,
  ) {
    return _guard(() => _remoteDataSource.addSupplierItemOffer(request));
  }

  @override
  Future<void> addItemAssignment(ItemAssignmentRequest request) {
    return _guard(() => _remoteDataSource.addItemAssignment(request));
  }

  @override
  Future<List<ItemAssignment>> getItemAssignmentsByTenderId(int tenderId) {
    return _guard(
      () => _remoteDataSource.getItemAssignmentsByTenderId(tenderId),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapDioException(error);
    }
  }
}
