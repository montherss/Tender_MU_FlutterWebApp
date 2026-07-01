import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/admin_domain.dart';

enum AdminActionType { none, createUser, addSupplier }

enum AdminStatus { initial, loading, success, failure }

class AdminState extends Equatable {
  const AdminState({
    this.status = AdminStatus.initial,
    this.action = AdminActionType.none,
    this.errorMessage,
    this.successMessage,
  });

  final AdminStatus status;
  final AdminActionType action;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoadingUser =>
      status == AdminStatus.loading && action == AdminActionType.createUser;
  bool get isLoadingSupplier =>
      status == AdminStatus.loading && action == AdminActionType.addSupplier;

  AdminState copyWith({
    AdminStatus? status,
    AdminActionType? action,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminState(
      status: status ?? this.status,
      action: action ?? this.action,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, action, errorMessage, successMessage];
}

class AdminCubit extends Cubit<AdminState> {
  AdminCubit(this._repository) : super(const AdminState());

  final AdminRepository _repository;

  Future<void> createUser({
    required String userName,
    required String password,
    required String role,
  }) async {
    emit(
      state.copyWith(
        status: AdminStatus.loading,
        action: AdminActionType.createUser,
      ),
    );
    try {
      await _repository.createUser(
        userName: userName,
        password: password,
        role: role,
      );
      emit(
        state.copyWith(
          status: AdminStatus.success,
          action: AdminActionType.createUser,
          successMessage: 'تم إنشاء المستخدم "$userName" بنجاح',
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          action: AdminActionType.createUser,
          errorMessage: error.message,
        ),
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
    emit(
      state.copyWith(
        status: AdminStatus.loading,
        action: AdminActionType.addSupplier,
      ),
    );
    try {
      await _repository.addSupplier(
        externalSupplierId: externalSupplierId,
        name: name,
        type: type,
        contactInfo: contactInfo,
        isManual: isManual,
      );
      emit(
        state.copyWith(
          status: AdminStatus.success,
          action: AdminActionType.addSupplier,
          successMessage: 'تمت إضافة المورد "$name" بنجاح',
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: AdminStatus.failure,
          action: AdminActionType.addSupplier,
          errorMessage: error.message,
        ),
      );
    }
  }

  void reset() => emit(const AdminState());
}
