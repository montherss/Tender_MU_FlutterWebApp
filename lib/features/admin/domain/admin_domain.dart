abstract class AdminRepository {
  Future<void> createUser({
    required String userName,
    required String password,
    required String role,
  });

  Future<void> addSupplier({
    required String externalSupplierId,
    required String name,
    required String type,
    required String contactInfo,
    required int isManual,
  });
}
