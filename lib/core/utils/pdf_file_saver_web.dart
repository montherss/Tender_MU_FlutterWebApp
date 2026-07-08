import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

Future<void> savePdfBytes(Uint8List bytes, String name) {
  return _saveFileBytes(bytes, name, mimeType: 'application/pdf');
}

Future<void> saveExcelBytes(Uint8List bytes, String name) {
  return _saveFileBytes(
    bytes,
    name,
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}

Future<void> _saveFileBytes(
  Uint8List bytes,
  String name, {
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = name
    ..click();
  html.Url.revokeObjectUrl(url);
}
