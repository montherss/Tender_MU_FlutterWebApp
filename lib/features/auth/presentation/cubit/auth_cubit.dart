import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/auth_domain.dart';

enum AuthStatus { initial, loading, authenticated, failure, loggingOut, loggedOut }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.message,
    this.errorMessage,
    this.role,
    this.userName,
  });

  final AuthStatus status;
  final String? message;
  final String? errorMessage;
  final String? role;
  final String? userName;

  bool get isAdmin => role?.toUpperCase() == 'ADMIN';

  AuthState copyWith({
    AuthStatus? status,
    String? message,
    String? errorMessage,
    String? role,
    String? userName,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message,
      errorMessage: errorMessage,
      role: role ?? this.role,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [status, message, errorMessage, role, userName];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  bool get isAuthenticated => _repository.isAuthenticated;

  Future<void> login({
    required String userName,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final session = await _repository.login(
        userName: userName,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          message: session.message,
          role: session.role,
          userName: session.userName,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: error.message),
      );
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loggingOut));
    try {
      await _repository.logout();
      emit(const AuthState(status: AuthStatus.loggedOut));
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }
}
