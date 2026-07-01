import '../../../../core/network/api_client.dart';
import '../../domain/admin_domain.dart';
import '../datasource/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<void> createUser({
    required String userName,
    required String password,
    required String role,
  }) async {
    try {
      await _remoteDataSource.createUser(
        userName: userName.trim(),
        password: password,
        role: role,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> addSupplier({
    required String externalSupplierId,
    required String name,
    required String type,
    required String contactInfo,
    required int isManual,
  }) async {
    try {
      await _remoteDataSource.addSupplier(
        externalSupplierId: externalSupplierId.trim(),
        name: name.trim(),
        type: type,
        contactInfo: contactInfo.trim(),
        isManual: isManual,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapDioException(error);
    }
  }
}
