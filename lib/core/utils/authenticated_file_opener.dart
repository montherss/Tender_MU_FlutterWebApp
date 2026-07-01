import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:universal_html/html.dart' as html;

import '../network/api_client.dart';

/// Downloads attachments via the API and opens them in a new browser tab.
class AuthenticatedFileOpener {
  const AuthenticatedFileOpener._();

  static Future<void> openAttachment(
    Dio dio, {
    required int attachmentId,
    String? fileName,
  }) async {
    try {
      final response = await dio.get<Uint8List>(
        '/attachments/download/$attachmentId',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 120),
          headers: {Headers.acceptHeader: '*/*'},
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const AppException('الملف فارغ أو غير متوفر');
      }

      final resolvedName = fileName ??
          _fileNameFromContentDisposition(
            response.headers.value('content-disposition'),
          ) ??
          'attachment-$attachmentId';

      final mime = _resolveMimeType(
        resolvedName,
        response.headers.value(Headers.contentTypeHeader),
      );
      final blob = html.Blob([data], mime);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(blobUrl, '_blank');

      Future<void>.delayed(const Duration(minutes: 2), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  static String? _fileNameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;

    final utf8Match = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!.trim());
    }

    final match = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    return match?.group(1)?.trim();
  }

  static String _resolveMimeType(String hint, String? headerValue) {
    if (headerValue != null && headerValue.isNotEmpty) {
      return headerValue.split(';').first.trim();
    }

    final lower = hint.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }
}
