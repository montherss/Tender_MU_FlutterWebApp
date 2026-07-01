import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.token,
    required this.message,
    required this.success,
    this.role,
    this.userName,
  });

  final String token;
  final String message;
  final bool success;
  final String? role;
  final String? userName;

  @override
  List<Object?> get props => [token, message, success, role, userName];
}

abstract class AuthRepository {
  Future<AuthSession> login({
    required String userName,
    required String password,
  });

  bool get isAuthenticated;
  String? get userRole;
  String? get currentUserName;

  Future<void> logout();
}
