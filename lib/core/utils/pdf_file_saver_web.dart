import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

Future<void> savePdfBytes(Uint8List bytes, String name) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = name
    ..click();
  html.Url.revokeObjectUrl(url);
}
