import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

class ExtractedInvoice extends Equatable {
  const ExtractedInvoice({
    required this.customer,
    required this.items,
    this.date,
    this.total,
  });

  final InvoiceCustomer customer;
  final String? date;
  final List<InvoiceItem> items;
  final num? total;

  @override
  List<Object?> get props => [customer, date, items, total];
}

class InvoiceCustomer extends Equatable {
  const InvoiceCustomer({this.name, this.phone});

  final String? name;
  final String? phone;

  @override
  List<Object?> get props => [name, phone];
}

class InvoiceItem extends Equatable {
  const InvoiceItem({this.serial, this.name, this.quantity, this.price});

  final int? serial;
  final String? name;
  final num? quantity;
  final num? price;

  num get lineTotal => (quantity ?? 0) * (price ?? 0);

  @override
  List<Object?> get props => [serial, name, quantity, price];
}

abstract class InvoiceRepository {
  Future<ExtractedInvoice> extractInvoice({
    required PlatformFile file,
    required void Function(int sent, int total) onProgress,
  });
}
