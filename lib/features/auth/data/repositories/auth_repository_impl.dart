import '../../../../core/auth/auth_token_store.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/auth_domain.dart';
import '../datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._tokenStore);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthTokenStore _tokenStore;

  @override
  bool get isAuthenticated => _tokenStore.hasToken;

  @override
  String? get userRole => _tokenStore.role;

  @override
  String? get currentUserName => _tokenStore.userName;

  @override
  Future<AuthSession> login({
    required String userName,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.login(
        userName: userName.trim(),
        password: password,
      );
      if (!session.success || session.token.isEmpty) {
        throw AppException(session.message);
      }
      await _tokenStore.saveToken(session.token);
      if (session.role != null) await _tokenStore.saveRole(session.role!);
      await _tokenStore.saveUserName(userName.trim());
      return session;
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // تجاهل أخطاء الخادم عند تسجيل الخروج وإكمال العملية محلياً
    } finally {
      await _tokenStore.clearToken();
    }
  }
}
