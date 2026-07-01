import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/invoice_domain.dart';

enum InvoiceExtractionStatus { initial, loading, success, failure }

class InvoiceState extends Equatable {
  const InvoiceState({
    this.status = InvoiceExtractionStatus.initial,
    this.invoice,
    this.selectedFileName,
    this.uploadProgress,
    this.errorMessage,
  });

  final InvoiceExtractionStatus status;
  final ExtractedInvoice? invoice;
  final String? selectedFileName;
  final double? uploadProgress;
  final String? errorMessage;

  InvoiceState copyWith({
    InvoiceExtractionStatus? status,
    ExtractedInvoice? invoice,
    String? selectedFileName,
    double? uploadProgress,
    String? errorMessage,
    bool clearInvoice = false,
    bool clearProgress = false,
    bool clearError = false,
  }) {
    return InvoiceState(
      status: status ?? this.status,
      invoice: clearInvoice ? null : invoice ?? this.invoice,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      uploadProgress: clearProgress
          ? null
          : uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    invoice,
    selectedFileName,
    uploadProgress,
    errorMessage,
  ];
}

class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit(this._repository) : super(const InvoiceState());

  final InvoiceRepository _repository;

  Future<void> extractInvoice(PlatformFile file) async {
    if (!_isAllowedFile(file.name)) {
      emit(
        state.copyWith(
          status: InvoiceExtractionStatus.failure,
          selectedFileName: file.name,
          errorMessage: 'الملف يجب أن يكون PDF أو JPG أو PNG',
          clearInvoice: true,
          clearProgress: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: InvoiceExtractionStatus.loading,
        selectedFileName: file.name,
        uploadProgress: 0,
        clearInvoice: true,
        clearError: true,
      ),
    );

    try {
      final invoice = await _repository.extractInvoice(
        file: file,
        onProgress: (sent, total) {
          if (total > 0) emit(state.copyWith(uploadProgress: sent / total));
        },
      );
      emit(
        state.copyWith(
          status: InvoiceExtractionStatus.success,
          invoice: invoice,
          clearProgress: true,
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: InvoiceExtractionStatus.failure,
          errorMessage: error.message,
          clearInvoice: true,
          clearProgress: true,
        ),
      );
    }
  }

  void clear() {
    emit(const InvoiceState());
  }

  bool _isAllowedFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return {'pdf', 'jpg', 'jpeg', 'png'}.contains(extension);
  }
}
