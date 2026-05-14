import '../../../../core/utils/app_utils.dart';
import '../../domain/tender_domain.dart';

class TenderSummaryModel extends TenderSummary {
  const TenderSummaryModel({
    required super.id,
    super.purchaseRequestNo,
    super.createdAt,
    super.financialCommitmentNo,
    super.status,
  });

  factory TenderSummaryModel.fromJson(Map<String, dynamic> json) {
    return TenderSummaryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      purchaseRequestNo: json['purchaseRequestNo']?.toString(),
      createdAt: parseDate(json['createdAt']),
      financialCommitmentNo: json['financialCommitmentNo']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class TenderDetailsModel extends TenderDetails {
  const TenderDetailsModel({
    required super.id,
    super.purchaseRequestNo,
    super.createdAt,
    super.financialCommitmentNo,
    super.status,
    super.tenderNo,
    super.subject,
    super.documentSourceType,
    super.supplierCategory,
    super.submissionLocation,
    super.submissionMethod,
    super.bidBondAmount,
    super.openingDate,
    super.startDate,
    super.closeDate,
    super.documentSaleDeadline,
    super.category,
    super.type,
    super.items,
    super.attachments,
  });

  factory TenderDetailsModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = _asList(
      json['tenderItemResponseDTOS'] ??
          json['items'] ??
          json['tenderItems'] ??
          json['tendersItems'],
    );
    final attachmentsJson = _asList(
      json['attachmentResponseDTO'] ?? json['attachments'] ?? json['files'],
    );
    final categoryAndTypeJson = _asMap(
      json['tenderCategoryAndType'] ??
          json['tenderCategoryAndTypeResponseDTO'] ??
          json['categoryAndType'] ??
          json['categoryType'],
    );
    return TenderDetailsModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      purchaseRequestNo: json['purchaseRequestNo']?.toString(),
      createdAt: parseDate(json['createdAt']),
      financialCommitmentNo: json['financialCommitmentNo']?.toString(),
      status: json['status']?.toString(),
      tenderNo: json['tenderNo']?.toString(),
      subject: json['subject']?.toString(),
      documentSourceType: json['documentSourceType']?.toString(),
      supplierCategory: json['supplierCategory']?.toString(),
      submissionLocation: json['submissionLocation']?.toString(),
      submissionMethod: json['submissionMethod']?.toString(),
      bidBondAmount: parseNum(json['bidBondAmount']),
      openingDate: parseDate(json['openingDate']),
      startDate: parseDate(json['startDate']),
      closeDate: parseDate(json['closeDate']),
      documentSaleDeadline: parseDate(json['documentSaleDeadline']),
      category:
          _firstString(json, ['category', 'tenderCategory']) ??
          _firstString(categoryAndTypeJson, ['category', 'tenderCategory']),
      type:
          _firstString(json, ['type', 'tenderType']) ??
          _firstString(categoryAndTypeJson, ['type', 'tenderType']),
      items: itemsJson.map((e) => TenderItemModel.fromJson(_asMap(e))).toList(),
      attachments: attachmentsJson
          .map((e) => TenderAttachmentModel.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class TenderItemModel extends TenderItem {
  const TenderItemModel({
    super.id,
    super.itemNo,
    super.description,
    super.quantity,
    super.price,
    super.unit,
    super.technicalAssignment,
    super.mainAssignment,
  });

  factory TenderItemModel.fromJson(Map<String, dynamic> json) {
    return TenderItemModel(
      id: _firstInt(json, [
        'id',
        'itemId',
        'itemID',
        'itemsId',
        'tenderItemId',
        'tenderItemsId',
        'tendersItemId',
      ]),
      itemNo: json['itemNo']?.toString(),
      description: json['description']?.toString(),
      quantity: parseNum(json['quantity']),
      price: parseNum(json['price']),
      unit: json['unit']?.toString(),
      technicalAssignment: _firstInt(json, ['technicalAssignment']),
      mainAssignment: _firstInt(json, ['mainAssignment']),
    );
  }

  static Map<String, dynamic> toJson(TenderItem item) => {
    'itemNo': item.itemNo?.trim(),
    'description': item.description?.trim(),
    'quantity': item.quantity?.toString(),
    'unit': item.unit?.trim(),
  };
}

class TenderAttachmentModel extends TenderAttachment {
  const TenderAttachmentModel({
    super.id,
    super.name,
    super.type,
    super.uploadDate,
    super.url,
  });

  factory TenderAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TenderAttachmentModel(
      id: (json['id'] as num?)?.toInt(),
      name:
          json['name']?.toString() ??
          json['fileName']?.toString() ??
          json['originalFilename']?.toString(),
      type:
          json['type']?.toString() ??
          json['fileType']?.toString() ??
          json['contentType']?.toString(),
      uploadDate: parseDate(
        json['uploadedAt'] ?? json['uploadDate'] ?? json['createdAt'],
      ),
      url:
          json['url']?.toString() ??
          json['fileUrl']?.toString() ??
          json['downloadUrl']?.toString(),
    );
  }
}

class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    super.name,
    super.contactInfo,
    super.externalSupplierId,
    super.isManual,
    super.type,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString(),
      contactInfo: json['contactInfo']?.toString(),
      externalSupplierId: json['externalSupplierId']?.toString(),
      isManual: _firstInt(json, ['isManual']),
      type: json['type']?.toString(),
    );
  }
}

class SupplierItemOfferModel extends SupplierItemOffer {
  const SupplierItemOfferModel({
    required super.id,
    required super.supplierId,
    required super.itemId,
    super.supplierName,
    super.itemNo,
    super.description,
    super.quantity,
    super.unit,
    super.price,
    super.note,
    super.isAlternative,
    super.alternativeDescription,
  });

  factory SupplierItemOfferModel.fromJson(Map<String, dynamic> json) {
    return SupplierItemOfferModel(
      id: _firstInt(json, ['id']) ?? 0,
      supplierId: _firstInt(json, ['SupplierId', 'supplierId']) ?? 0,
      itemId: _firstInt(json, ['itemId', 'tenderItemId']) ?? 0,
      supplierName: json['supplierName']?.toString(),
      itemNo: json['itemNo']?.toString(),
      description: json['description']?.toString(),
      quantity: parseNum(json['quantity']),
      unit: json['unit']?.toString(),
      price: parseNum(json['price']),
      note: json['note']?.toString(),
      isAlternative: _firstInt(json, ['isAlternative']),
      alternativeDescription: json['alternativeDescription']?.toString(),
    );
  }
}

class ItemAssignmentModel extends ItemAssignment {
  const ItemAssignmentModel({
    required super.assignmentId,
    required super.tenderId,
    required super.supplierItemOfferId,
    required super.tenderItemId,
    super.supplierName,
    super.supplierTenderId,
    super.assignedPrice,
    super.assignmentNote,
    super.assignmentType,
    super.createdAt,
    super.price,
    super.offerNote,
    super.isAlternative,
    super.alternativeDescription,
  });

  factory ItemAssignmentModel.fromJson(Map<String, dynamic> json) {
    return ItemAssignmentModel(
      assignmentId: _firstInt(json, ['assignmentId', 'id']) ?? 0,
      tenderId: _firstInt(json, ['tenderId']) ?? 0,
      supplierItemOfferId:
          _firstInt(json, ['supplierItemOfferId', 'supplierItemOfferIdRef']) ??
          0,
      tenderItemId: _firstInt(json, ['tenderItemId', 'itemId']) ?? 0,
      supplierName: json['supplierName']?.toString(),
      supplierTenderId: _firstInt(json, ['supplierTenderId']),
      assignedPrice: parseNum(json['assignedPrice']),
      assignmentNote: json['assignmentNote']?.toString(),
      assignmentType: json['assignmentType']?.toString(),
      createdAt: parseDate(json['createdAt']),
      price: parseNum(json['price']),
      offerNote: json['offerNote']?.toString(),
      isAlternative: _firstInt(json, ['isAlternative']),
      alternativeDescription: json['alternativeDescription']?.toString(),
    );
  }
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

int? _firstInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  final normalizedJson = json.map(
    (key, value) => MapEntry(key.toLowerCase(), value),
  );
  for (final key in keys) {
    final value = normalizedJson[key.toLowerCase()];
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}
