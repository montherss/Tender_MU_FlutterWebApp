import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> savePdfBytes(Uint8List bytes, String name) {
  return _saveFileBytes(
    bytes,
    name,
    dialogTitle: 'حفظ ملف PDF',
    extension: 'pdf',
  );
}

Future<void> saveExcelBytes(Uint8List bytes, String name) {
  return _saveFileBytes(
    bytes,
    name,
    dialogTitle: 'حفظ ملف Excel',
    extension: 'xlsx',
  );
}

Future<void> _saveFileBytes(
  Uint8List bytes,
  String name, {
  required String dialogTitle,
  required String extension,
}) async {
  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: name,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: bytes,
  );
  if (outputPath == null) return;

  final normalizedPath = outputPath.toLowerCase().endsWith('.$extension')
      ? outputPath
      : '$outputPath.$extension';
  await File(normalizedPath).writeAsBytes(bytes, flush: true);
}
