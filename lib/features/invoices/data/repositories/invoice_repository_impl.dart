import 'package:file_picker/file_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/invoice_domain.dart';
import '../datasource/invoice_remote_datasource.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  const InvoiceRepositoryImpl(this._remoteDataSource);

  final InvoiceRemoteDataSource _remoteDataSource;

  @override
  Future<ExtractedInvoice> extractInvoice({
    required PlatformFile file,
    required void Function(int sent, int total) onProgress,
  }) {
    return _guard(
      () =>
          _remoteDataSource.extractInvoice(file: file, onProgress: onProgress),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapDioException(error);
    }
  }
}
