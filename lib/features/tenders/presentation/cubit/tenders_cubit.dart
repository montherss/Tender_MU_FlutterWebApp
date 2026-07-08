import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/tender_domain.dart';

enum ViewStatus { initial, loading, success, failure }

enum AssignmentFilter { all, approved, rejected }

class TendersState extends Equatable {
  const TendersState({
    this.status = ViewStatus.initial,
    this.tenders = const [],
    this.search = '',
    this.statusFilter,
    this.errorMessage,
    this.isCreating = false,
  });

  final ViewStatus status;
  final List<TenderSummary> tenders;
  final String search;
  final String? statusFilter;
  final String? errorMessage;
  final bool isCreating;

  List<TenderSummary> get filteredTenders {
    final query = search.trim().toLowerCase();
    return tenders.where((tender) {
      final matchesSearch =
          query.isEmpty ||
          [
            tender.id.toString(),
            tender.purchaseRequestNo,
            tender.financialCommitmentNo,
            tender.status,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(query),
          );
      final matchesStatus =
          statusFilter == null || tender.status == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  List<String> get statuses =>
      tenders.map((e) => e.status).whereType<String>().toSet().toList();

  TendersState copyWith({
    ViewStatus? status,
    List<TenderSummary>? tenders,
    String? search,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? errorMessage,
    bool? isCreating,
  }) {
    return TendersState(
      status: status ?? this.status,
      tenders: tenders ?? this.tenders,
      search: search ?? this.search,
      statusFilter: clearStatusFilter
          ? null
          : statusFilter ?? this.statusFilter,
      errorMessage: errorMessage,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tenders,
    search,
    statusFilter,
    errorMessage,
    isCreating,
  ];
}

class TendersCubit extends Cubit<TendersState> {
  TendersCubit(this._repository) : super(const TendersState());

  final TenderRepository _repository;

  Future<void> loadTenders() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final tenders = await _repository.getTenders();
      emit(state.copyWith(status: ViewStatus.success, tenders: tenders));
    } on AppException catch (error) {
      emit(
        state.copyWith(status: ViewStatus.failure, errorMessage: error.message),
      );
    }
  }

  void search(String value) => emit(state.copyWith(search: value));

  void setStatusFilter(String? value) => emit(
    state.copyWith(statusFilter: value, clearStatusFilter: value == null),
  );

  Future<void> createTender(CreateTenderRequest request) async {
    emit(state.copyWith(isCreating: true));
    try {
      await _repository.createTender(request);
      final tenders = await _repository.getTenders();
      emit(
        state.copyWith(
          status: ViewStatus.success,
          tenders: tenders,
          isCreating: false,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(isCreating: false, errorMessage: error.message));
    }
  }
}

class TenderDetailsState extends Equatable {
  const TenderDetailsState({
    this.status = ViewStatus.initial,
    this.tender,
    this.errorMessage,
    this.actionLoading = false,
    this.uploadProgress,
    this.assignmentFilter = AssignmentFilter.all,
    this.loadingAssignments = const {},
    this.tenderSuppliers = const [],
    this.suppliersLoading = false,
    this.addingSupplier = false,
    this.supplierSearchResults = const [],
    this.supplierSearchLoading = false,
    this.supplierSearchError,
    this.supplierItemOffers = const [],
    this.supplierItemOffersLoading = false,
    this.addingSupplierItemOffer = false,
    this.itemAssignments = const [],
    this.itemAssignmentsLoading = false,
    this.loadingItemAssignments = const {},
    this.deletingAttachmentIds = const {},
  });

  final ViewStatus status;
  final TenderDetails? tender;
  final String? errorMessage;
  final bool actionLoading;
  final double? uploadProgress;
  final AssignmentFilter assignmentFilter;
  final Set<String> loadingAssignments;
  final List<Supplier> tenderSuppliers;
  final bool suppliersLoading;
  final bool addingSupplier;
  final List<Supplier> supplierSearchResults;
  final bool supplierSearchLoading;
  final String? supplierSearchError;
  final List<SupplierItemOffer> supplierItemOffers;
  final bool supplierItemOffersLoading;
  final bool addingSupplierItemOffer;
  final List<ItemAssignment> itemAssignments;
  final bool itemAssignmentsLoading;
  final Set<int> loadingItemAssignments;
  final Set<int> deletingAttachmentIds;

  List<TenderItem> get filteredItems {
    final all = tender?.items ?? const [];
    return switch (assignmentFilter) {
      AssignmentFilter.all => all,
      AssignmentFilter.approved =>
        all
            .where(
              (item) =>
                  item.technicalAssignment == 1 || item.mainAssignment == 1,
            )
            .toList(),
      AssignmentFilter.rejected =>
        all
            .where(
              (item) =>
                  item.technicalAssignment == 0 || item.mainAssignment == 0,
            )
            .toList(),
    };
  }

  TenderDetailsState copyWith({
    ViewStatus? status,
    TenderDetails? tender,
    String? errorMessage,
    bool? actionLoading,
    double? uploadProgress,
    bool clearUploadProgress = false,
    AssignmentFilter? assignmentFilter,
    Set<String>? loadingAssignments,
    List<Supplier>? tenderSuppliers,
    bool? suppliersLoading,
    bool? addingSupplier,
    List<Supplier>? supplierSearchResults,
    bool? supplierSearchLoading,
    String? supplierSearchError,
    List<SupplierItemOffer>? supplierItemOffers,
    bool? supplierItemOffersLoading,
    bool? addingSupplierItemOffer,
    List<ItemAssignment>? itemAssignments,
    bool? itemAssignmentsLoading,
    Set<int>? loadingItemAssignments,
    Set<int>? deletingAttachmentIds,
  }) {
    return TenderDetailsState(
      status: status ?? this.status,
      tender: tender ?? this.tender,
      errorMessage: errorMessage,
      actionLoading: actionLoading ?? this.actionLoading,
      uploadProgress: clearUploadProgress
          ? null
          : uploadProgress ?? this.uploadProgress,
      assignmentFilter: assignmentFilter ?? this.assignmentFilter,
      loadingAssignments: loadingAssignments ?? this.loadingAssignments,
      tenderSuppliers: tenderSuppliers ?? this.tenderSuppliers,
      suppliersLoading: suppliersLoading ?? this.suppliersLoading,
      addingSupplier: addingSupplier ?? this.addingSupplier,
      supplierSearchResults:
          supplierSearchResults ?? this.supplierSearchResults,
      supplierSearchLoading:
          supplierSearchLoading ?? this.supplierSearchLoading,
      supplierSearchError: supplierSearchError,
      supplierItemOffers: supplierItemOffers ?? this.supplierItemOffers,
      supplierItemOffersLoading:
          supplierItemOffersLoading ?? this.supplierItemOffersLoading,
      addingSupplierItemOffer:
          addingSupplierItemOffer ?? this.addingSupplierItemOffer,
      itemAssignments: itemAssignments ?? this.itemAssignments,
      itemAssignmentsLoading:
          itemAssignmentsLoading ?? this.itemAssignmentsLoading,
      loadingItemAssignments:
          loadingItemAssignments ?? this.loadingItemAssignments,
      deletingAttachmentIds:
          deletingAttachmentIds ?? this.deletingAttachmentIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tender,
    errorMessage,
    actionLoading,
    uploadProgress,
    assignmentFilter,
    loadingAssignments,
    tenderSuppliers,
    suppliersLoading,
    addingSupplier,
    supplierSearchResults,
    supplierSearchLoading,
    supplierSearchError,
    supplierItemOffers,
    supplierItemOffersLoading,
    addingSupplierItemOffer,
    itemAssignments,
    itemAssignmentsLoading,
    loadingItemAssignments,
    deletingAttachmentIds,
  ];
}

class TenderDetailsCubit extends Cubit<TenderDetailsState> {
  TenderDetailsCubit(this._repository) : super(const TenderDetailsState());

  final TenderRepository _repository;

  Future<void> loadTender(int id) async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final tender = await _repository.getTender(id);
      emit(state.copyWith(status: ViewStatus.success, tender: tender));
      await loadSuppliersData(tender.id);
    } on AppException catch (error) {
      emit(
        state.copyWith(status: ViewStatus.failure, errorMessage: error.message),
      );
    }
  }

  Future<void> refreshTender() async {
    final tender = state.tender;
    if (tender == null) return;
    try {
      final refreshedTender = await _repository.getTender(tender.id);
      emit(
        state.copyWith(
          status: ViewStatus.success,
          tender: refreshedTender,
          actionLoading: false,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(actionLoading: false, errorMessage: error.message));
    }
  }

  Future<void> addFinancialCommitment(String value) async {
    final tender = state.tender;
    if (tender == null) return;
    emit(state.copyWith(actionLoading: true));
    try {
      await _repository.addFinancialCommitmentNo(tender.id, value);
      await refreshTender();
    } on AppException catch (error) {
      emit(state.copyWith(actionLoading: false, errorMessage: error.message));
    }
  }

  Future<void> saveItems(List<TenderItem> items) async {
    final tender = state.tender;
    if (tender == null) return;
    emit(state.copyWith(actionLoading: true));
    try {
      await _repository.addTenderItems(tender.id, items);
      await refreshTender();
    } on AppException catch (error) {
      emit(state.copyWith(actionLoading: false, errorMessage: error.message));
    }
  }

  Future<void> uploadFiles(List<PlatformFile> files) async {
    final tender = state.tender;
    if (tender == null || files.isEmpty) return;
    emit(state.copyWith(actionLoading: true, uploadProgress: 0));
    try {
      await _repository.uploadAttachments(
        tenderId: tender.id,
        files: files,
        onProgress: (sent, total) {
          if (total > 0) emit(state.copyWith(uploadProgress: sent / total));
        },
      );
      await refreshTender();
      emit(state.copyWith(clearUploadProgress: true));
    } on AppException catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          clearUploadProgress: true,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<bool> deleteAttachment(int attachmentId) async {
    final tender = state.tender;
    if (tender == null) return false;

    final deleting = {...state.deletingAttachmentIds, attachmentId};
    emit(state.copyWith(deletingAttachmentIds: deleting, errorMessage: null));

    try {
      await _repository.deleteAttachment(attachmentId);
      await refreshTender();
      final clearedDeleting = Set<int>.from(state.deletingAttachmentIds)
        ..remove(attachmentId);
      emit(state.copyWith(deletingAttachmentIds: clearedDeleting));
      return true;
    } on AppException catch (error) {
      final clearedDeleting = Set<int>.from(state.deletingAttachmentIds)
        ..remove(attachmentId);
      emit(
        state.copyWith(
          deletingAttachmentIds: clearedDeleting,
          errorMessage: error.message,
        ),
      );
      return false;
    }
  }

  Future<void> saveCategory(String category, String? type) async {
    final tender = state.tender;
    if (tender == null) return;
    final cleanedCategory = category.trim();
    final cleanedType = type?.trim();
    emit(state.copyWith(actionLoading: true));
    try {
      await _repository.addTenderCategoryAndType(
        tender.id,
        cleanedCategory,
        cleanedType,
      );
      emit(
        state.copyWith(
          tender: tender.copyWith(category: cleanedCategory, type: cleanedType),
        ),
      );
      await refreshTender();
    } on AppException catch (error) {
      emit(state.copyWith(actionLoading: false, errorMessage: error.message));
    }
  }

  Future<void> saveBasicInfo(BasicInfoRequest request) async {
    final tender = state.tender;
    if (tender == null) return;
    emit(state.copyWith(actionLoading: true));
    try {
      await _repository.updateBasicInfo(tender.id, request);
      await refreshTender();
    } on AppException catch (error) {
      emit(state.copyWith(actionLoading: false, errorMessage: error.message));
    }
  }

  void setAssignmentFilter(AssignmentFilter value) =>
      emit(state.copyWith(assignmentFilter: value));

  Future<void> changeAssignment({
    required TenderItem item,
    required bool technical,
    required int value,
  }) async {
    final itemId = item.id;
    if (itemId == null || state.tender == null) return;
    final key = '${technical ? 't' : 'm'}-$itemId';
    final loading = {...state.loadingAssignments, key};
    final previousTender = state.tender!;
    final updatedItems = previousTender.items.map((current) {
      if (current.id != itemId) return current;
      return technical
          ? current.copyWith(technicalAssignment: value)
          : current.copyWith(mainAssignment: value);
    }).toList();
    emit(
      state.copyWith(
        tender: previousTender.copyWith(items: updatedItems),
        loadingAssignments: loading,
      ),
    );
    try {
      if (technical) {
        await _repository.changeTechnicalAssignment(itemId, value);
      } else {
        await _repository.changeMainAssignment(itemId, value);
      }
      await refreshTender();
      emit(
        state.copyWith(
          loadingAssignments: {...state.loadingAssignments}..remove(key),
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          tender: previousTender,
          loadingAssignments: {...state.loadingAssignments}..remove(key),
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<void> loadSuppliersData(int tenderId) async {
    emit(state.copyWith(suppliersLoading: true));
    try {
      final tenderSuppliers = await _repository.getSuppliersByTenderId(
        tenderId,
      );
      emit(
        state.copyWith(
          tenderSuppliers: tenderSuppliers,
          suppliersLoading: false,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(suppliersLoading: false, errorMessage: error.message),
      );
    }
  }

  Future<void> searchSuppliers(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      clearSupplierSearch();
      return;
    }
    emit(
      state.copyWith(supplierSearchLoading: true, supplierSearchError: null),
    );
    try {
      final results = await _repository.searchSuppliers(trimmed);
      emit(
        state.copyWith(
          supplierSearchResults: results,
          supplierSearchLoading: false,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          supplierSearchResults: const [],
          supplierSearchLoading: false,
          supplierSearchError: error.message,
        ),
      );
    }
  }

  void clearSupplierSearch() {
    emit(
      state.copyWith(
        supplierSearchResults: const [],
        supplierSearchLoading: false,
        supplierSearchError: null,
      ),
    );
  }

  Future<bool> addSupplierToTender(int supplierId) async {
    final tender = state.tender;
    if (tender == null) return false;
    emit(state.copyWith(addingSupplier: true));
    try {
      await _repository.addSupplierToTender(
        tenderId: tender.id,
        supplierId: supplierId,
      );
      final tenderSuppliers = await _repository.getSuppliersByTenderId(
        tender.id,
      );
      emit(
        state.copyWith(
          tenderSuppliers: tenderSuppliers,
          addingSupplier: false,
          supplierSearchResults: const [],
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(addingSupplier: false, errorMessage: error.message));
      return false;
    }
  }

  Future<void> loadSupplierItemOffers() async {
    final tender = state.tender;
    if (tender == null) return;
    emit(state.copyWith(supplierItemOffersLoading: true));
    try {
      final offers = await _repository.getSupplierItemOffersByTenderId(
        tender.id,
      );
      emit(
        state.copyWith(
          supplierItemOffers: offers,
          supplierItemOffersLoading: false,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          supplierItemOffersLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<bool> addSupplierItemOffer({
    required int supplierId,
    required int tenderItemId,
    required num price,
    String? origin,
    required num unitPrice,
    String? note,
    required bool isAlternative,
    String? alternativeDescription,
  }) async {
    final tender = state.tender;
    if (tender == null) return false;
    emit(state.copyWith(addingSupplierItemOffer: true));
    try {
      await _repository.addSupplierItemOffer(
        SupplierItemOfferRequest(
          tenderId: tender.id,
          supplierId: supplierId,
          tenderItemId: tenderItemId,
          price: price,
          origin: origin,
          unitPrice: unitPrice,
          note: note,
          isAlternative: isAlternative ? 1 : 0,
          alternativeDescription: isAlternative ? alternativeDescription : null,
        ),
      );
      final offers = await _repository.getSupplierItemOffersByTenderId(
        tender.id,
      );
      emit(
        state.copyWith(
          supplierItemOffers: offers,
          addingSupplierItemOffer: false,
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          addingSupplierItemOffer: false,
          errorMessage: error.message,
        ),
      );
      return false;
    }
  }

  Future<void> loadItemAssignments() async {
    final tender = state.tender;
    if (tender == null) return;
    emit(state.copyWith(itemAssignmentsLoading: true));
    try {
      final assignments = await _repository.getItemAssignmentsByTenderId(
        tender.id,
      );
      emit(
        state.copyWith(
          itemAssignments: assignments,
          itemAssignmentsLoading: false,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          itemAssignmentsLoading: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  Future<bool> addItemAssignment({
    required int supplierItemOfferId,
    required String assignmentType,
    required num assignedPrice,
    String? note,
  }) async {
    final tender = state.tender;
    if (tender == null) return false;
    emit(
      state.copyWith(
        loadingItemAssignments: {
          ...state.loadingItemAssignments,
          supplierItemOfferId,
        },
      ),
    );
    try {
      await _repository.addItemAssignment(
        ItemAssignmentRequest(
          tenderId: tender.id,
          supplierItemOfferId: supplierItemOfferId,
          assignmentType: assignmentType,
          assignedPrice: assignedPrice,
          note: note,
        ),
      );
      final assignments = await _repository.getItemAssignmentsByTenderId(
        tender.id,
      );
      emit(
        state.copyWith(
          itemAssignments: assignments,
          loadingItemAssignments: {...state.loadingItemAssignments}
            ..remove(supplierItemOfferId),
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          loadingItemAssignments: {...state.loadingItemAssignments}
            ..remove(supplierItemOfferId),
          errorMessage: error.message,
        ),
      );
      return false;
    }
  }
}
