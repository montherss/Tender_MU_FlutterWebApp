import '../../domain/invoice_domain.dart';

class ExtractedInvoiceModel extends ExtractedInvoice {
  const ExtractedInvoiceModel({
    required super.customer,
    required super.items,
    super.date,
    super.total,
  });

  factory ExtractedInvoiceModel.fromJson(Map<String, dynamic> json) {
    return ExtractedInvoiceModel(
      customer: InvoiceCustomerModel.fromJson(_asMap(json['customer'])),
      date: json['date']?.toString(),
      items: _asList(
        json['items'],
      ).map((item) => InvoiceItemModel.fromJson(_asMap(item))).toList(),
      total: _parseNum(json['total']),
    );
  }
}

class InvoiceCustomerModel extends InvoiceCustomer {
  const InvoiceCustomerModel({super.name, super.phone});

  factory InvoiceCustomerModel.fromJson(Map<String, dynamic> json) {
    return InvoiceCustomerModel(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class InvoiceItemModel extends InvoiceItem {
  const InvoiceItemModel({
    super.serial,
    super.name,
    super.quantity,
    super.price,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      serial: _parseInt(json['serial']),
      name: json['name']?.toString(),
      quantity: _parseNum(json['quantity']),
      price: _parseNum(json['price']),
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

int? _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

num? _parseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}
