import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

class TenderSummary extends Equatable {
  const TenderSummary({
    required this.id,
    this.purchaseRequestNo,
    this.createdAt,
    this.financialCommitmentNo,
    this.status,
  });

  final int id;
  final String? purchaseRequestNo;
  final DateTime? createdAt;
  final String? financialCommitmentNo;
  final String? status;

  bool get needsFinancialCommitment =>
      financialCommitmentNo == null || financialCommitmentNo!.trim().isEmpty;

  @override
  List<Object?> get props => [
    id,
    purchaseRequestNo,
    createdAt,
    financialCommitmentNo,
    status,
  ];
}

class TenderDetails extends TenderSummary {
  const TenderDetails({
    required super.id,
    super.purchaseRequestNo,
    super.createdAt,
    super.financialCommitmentNo,
    super.status,
    this.tenderNo,
    this.subject,
    this.documentSourceType,
    this.supplierCategory,
    this.submissionLocation,
    this.submissionMethod,
    this.bidBondAmount,
    this.openingDate,
    this.startDate,
    this.closeDate,
    this.documentSaleDeadline,
    this.category,
    this.type,
    this.items = const [],
    this.attachments = const [],
  });

  final String? tenderNo;
  final String? subject;
  final String? documentSourceType;
  final String? supplierCategory;
  final String? submissionLocation;
  final String? submissionMethod;
  final num? bidBondAmount;
  final DateTime? openingDate;
  final DateTime? startDate;
  final DateTime? closeDate;
  final DateTime? documentSaleDeadline;
  final String? category;
  final String? type;
  final List<TenderItem> items;
  final List<TenderAttachment> attachments;

  TenderDetails copyWith({
    String? financialCommitmentNo,
    String? category,
    String? type,
    List<TenderItem>? items,
    List<TenderAttachment>? attachments,
  }) {
    return TenderDetails(
      id: id,
      purchaseRequestNo: purchaseRequestNo,
      createdAt: createdAt,
      financialCommitmentNo:
          financialCommitmentNo ?? this.financialCommitmentNo,
      status: status,
      tenderNo: tenderNo,
      subject: subject,
      documentSourceType: documentSourceType,
      supplierCategory: supplierCategory,
      submissionLocation: submissionLocation,
      submissionMethod: submissionMethod,
      bidBondAmount: bidBondAmount,
      openingDate: openingDate,
      startDate: startDate,
      closeDate: closeDate,
      documentSaleDeadline: documentSaleDeadline,
      category: category ?? this.category,
      type: type ?? this.type,
      items: items ?? this.items,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    tenderNo,
    subject,
    documentSourceType,
    supplierCategory,
    submissionLocation,
    submissionMethod,
    bidBondAmount,
    openingDate,
    startDate,
    closeDate,
    documentSaleDeadline,
    category,
    type,
    items,
    attachments,
  ];
}

class TenderItem extends Equatable {
  const TenderItem({
    this.id,
    this.itemNo,
    this.description,
    this.quantity,
    this.price,
    this.unit,
    this.technicalAssignment,
    this.mainAssignment,
  });

  final int? id;
  final String? itemNo;
  final String? description;
  final num? quantity;
  final num? price;
  final String? unit;
  final int? technicalAssignment;
  final int? mainAssignment;

  num get total => (quantity ?? 0) * (price ?? 0);

  TenderItem copyWith({int? technicalAssignment, int? mainAssignment}) {
    return TenderItem(
      id: id,
      itemNo: itemNo,
      description: description,
      quantity: quantity,
      price: price,
      unit: unit,
      technicalAssignment: technicalAssignment ?? this.technicalAssignment,
      mainAssignment: mainAssignment ?? this.mainAssignment,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemNo,
    description,
    quantity,
    price,
    unit,
    technicalAssignment,
    mainAssignment,
  ];
}

class TenderAttachment extends Equatable {
  const TenderAttachment({
    this.id,
    this.name,
    this.type,
    this.uploadDate,
    this.url,
  });

  final int? id;
  final String? name;
  final String? type;
  final DateTime? uploadDate;
  final String? url;

  @override
  List<Object?> get props => [id, name, type, uploadDate, url];
}

class Supplier extends Equatable {
  const Supplier({
    required this.id,
    this.name,
    this.contactInfo,
    this.externalSupplierId,
    this.isManual,
    this.type,
  });

  final int id;
  final String? name;
  final String? contactInfo;
  final String? externalSupplierId;
  final int? isManual;
  final String? type;

  String get displayName {
    final value = name?.trim();
    return value == null || value.isEmpty ? 'مورد #$id' : value;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    contactInfo,
    externalSupplierId,
    isManual,
    type,
  ];
}

class SupplierItemOffer extends Equatable {
  const SupplierItemOffer({
    required this.id,
    required this.supplierId,
    required this.itemId,
    this.supplierName,
    this.itemNo,
    this.description,
    this.quantity,
    this.unit,
    this.price,
    this.note,
    this.isAlternative,
    this.alternativeDescription,
  });

  final int id;
  final int supplierId;
  final int itemId;
  final String? supplierName;
  final String? itemNo;
  final String? description;
  final num? quantity;
  final String? unit;
  final num? price;
  final String? note;
  final int? isAlternative;
  final String? alternativeDescription;

  bool get hasAlternative => isAlternative == 1;

  @override
  List<Object?> get props => [
    id,
    supplierId,
    itemId,
    supplierName,
    itemNo,
    description,
    quantity,
    unit,
    price,
    note,
    isAlternative,
    alternativeDescription,
  ];
}

class SupplierItemOfferRequest {
  const SupplierItemOfferRequest({
    required this.tenderId,
    required this.supplierId,
    required this.tenderItemId,
    required this.price,
    this.note,
    required this.isAlternative,
    this.alternativeDescription,
  });

  final int tenderId;
  final int supplierId;
  final int tenderItemId;
  final num price;
  final String? note;
  final int isAlternative;
  final String? alternativeDescription;

  Map<String, dynamic> toJson() => {
    'tenderId': tenderId,
    'supplierId': supplierId,
    'tenderItemId': tenderItemId,
    'price': price,
    'note': note?.trim(),
    'isAlternative': isAlternative,
    'alternativeDescription': alternativeDescription?.trim(),
  };
}

class ItemAssignment extends Equatable {
  const ItemAssignment({
    required this.assignmentId,
    required this.tenderId,
    required this.supplierItemOfferId,
    required this.tenderItemId,
    this.supplierName,
    this.supplierTenderId,
    this.assignedPrice,
    this.assignmentNote,
    this.assignmentType,
    this.createdAt,
    this.price,
    this.offerNote,
    this.isAlternative,
    this.alternativeDescription,
  });

  final int assignmentId;
  final int tenderId;
  final int supplierItemOfferId;
  final int tenderItemId;
  final String? supplierName;
  final int? supplierTenderId;
  final num? assignedPrice;
  final String? assignmentNote;
  final String? assignmentType;
  final DateTime? createdAt;
  final num? price;
  final String? offerNote;
  final int? isAlternative;
  final String? alternativeDescription;

  bool get isTechnical => assignmentType == 'TEC';
  bool get hasAlternative => isAlternative == 1;

  @override
  List<Object?> get props => [
    assignmentId,
    tenderId,
    supplierItemOfferId,
    tenderItemId,
    supplierName,
    supplierTenderId,
    assignedPrice,
    assignmentNote,
    assignmentType,
    createdAt,
    price,
    offerNote,
    isAlternative,
    alternativeDescription,
  ];
}

class ItemAssignmentRequest {
  const ItemAssignmentRequest({
    required this.tenderId,
    required this.supplierItemOfferId,
    required this.assignmentType,
    required this.assignedPrice,
    this.note,
  });

  final int tenderId;
  final int supplierItemOfferId;
  final String assignmentType;
  final num assignedPrice;
  final String? note;

  Map<String, dynamic> toJson() => {
    'tenderId': tenderId,
    'supplierItemOfferId': supplierItemOfferId,
    'assignmentType': assignmentType,
    'assignedPrice': assignedPrice,
    'note': note?.trim(),
  };
}

class CreateTenderRequest {
  const CreateTenderRequest({this.purchaseRequestNo});

  final String? purchaseRequestNo;

  Map<String, dynamic> toJson() => {
    if (purchaseRequestNo?.trim().isNotEmpty ?? false)
      'purchaseRequestNo': purchaseRequestNo!.trim(),
  };
}

class BasicInfoRequest {
  const BasicInfoRequest({
    this.tenderNo,
    this.subject,
    this.documentSourceType,
    this.supplierCategory,
    this.submissionLocation,
    this.submissionMethod,
    this.bidBondAmount,
    this.openingDate,
    this.startDate,
    this.closeDate,
    this.documentSaleDeadline,
  });

  final String? tenderNo;
  final String? subject;
  final String? documentSourceType;
  final String? supplierCategory;
  final String? submissionLocation;
  final String? submissionMethod;
  final num? bidBondAmount;
  final DateTime? openingDate;
  final DateTime? startDate;
  final DateTime? closeDate;
  final DateTime? documentSaleDeadline;

  Map<String, dynamic> toJson(int tenderId) => {
    'tenderId': tenderId,
    'tenderNo': tenderNo,
    'subject': subject,
    'documentSourceType': documentSourceType,
    'supplierCategory': supplierCategory,
    'submissionLocation': submissionLocation,
    'submissionMethod': submissionMethod,
    'bidBondAmount': bidBondAmount,
    'openingDate': openingDate?.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'closeDate': closeDate?.toIso8601String(),
    'documentSaleDeadline': documentSaleDeadline?.toIso8601String(),
  };
}

abstract class TenderRepository {
  Future<List<TenderSummary>> getTenders();
  Future<TenderDetails> getTender(int id);
  Future<void> createTender(CreateTenderRequest request);
  Future<void> addFinancialCommitmentNo(int tenderId, String value);
  Future<void> addTenderItems(int tenderId, List<TenderItem> items);
  Future<void> uploadAttachments({
    required int tenderId,
    required List<PlatformFile> files,
    required void Function(int sent, int total) onProgress,
  });
  Future<void> addTenderCategoryAndType(
    int tenderId,
    String category,
    String? type,
  );
  Future<void> updateBasicInfo(int tenderId, BasicInfoRequest request);
  Future<void> changeTechnicalAssignment(int itemId, int value);
  Future<void> changeMainAssignment(int itemId, int value);
  Future<List<Supplier>> getSuppliers({int page = 0, int size = 5});
  Future<List<Supplier>> getSuppliersByTenderId(int tenderId);
  Future<void> addSupplierToTender({
    required int tenderId,
    required int supplierId,
  });
  Future<List<SupplierItemOffer>> getSupplierItemOffersByTenderId(int tenderId);
  Future<List<SupplierItemOffer>> addSupplierItemOffer(
    SupplierItemOfferRequest request,
  );
  Future<void> addItemAssignment(ItemAssignmentRequest request);
  Future<List<ItemAssignment>> getItemAssignmentsByTenderId(int tenderId);
}
