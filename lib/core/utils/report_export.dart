import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'pdf_file_saver.dart';

/// Tries to build and print/download a PDF report. If PDF generation fails
/// (for example the `pdf` package refuses to paginate an oversized report),
/// falls back to building an Excel workbook with the same data instead and
/// saves it to disk.
///
/// Returns `true` when the Excel fallback was used.
Future<bool> exportPdfOrExcel({
  required Future<Uint8List> Function() buildPdf,
  required Future<List<int>> Function() buildExcel,
  required String pdfFileName,
  required String excelFileName,
  required bool download,
}) async {
  try {
    final bytes = await buildPdf();
    if (download) {
      await savePdfBytes(bytes, pdfFileName);
    } else {
      await Printing.layoutPdf(
        name: pdfFileName,
        onLayout: (_) async => bytes,
      );
    }
    return false;
  } catch (error) {
    final excelBytes = Uint8List.fromList(await buildExcel());
    await saveExcelBytes(excelBytes, excelFileName);
    return true;
  }
}
