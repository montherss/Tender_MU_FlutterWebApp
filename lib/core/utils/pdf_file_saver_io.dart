import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> savePdfBytes(Uint8List bytes, String name) async {
  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'حفظ ملف PDF',
    fileName: name,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    bytes: bytes,
  );
  if (outputPath == null) return;

  final normalizedPath = outputPath.toLowerCase().endsWith('.pdf')
      ? outputPath
      : '$outputPath.pdf';
  await File(normalizedPath).writeAsBytes(bytes, flush: true);
}
