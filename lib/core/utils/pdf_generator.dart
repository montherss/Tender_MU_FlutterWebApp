import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/tenders/domain/tender_domain.dart';
import 'app_utils.dart';
import 'pdf_file_saver.dart';

class TenderPdfGenerator {
  const TenderPdfGenerator._();

  static Future<Uint8List> itemsPdf(TenderDetails tender) async {
    final theme = await _arabicPdfTheme();
    final logo = await _pdfLogo();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        maxPages: 200,
        header: (_) => _compactUniversityHeader(logo),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 7),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: .5)),
          ),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          // _itemsPdfHeader(tender),
          // pw.SizedBox(height: 12),
          // _itemsTenderDetails(tender),
          // pw.SizedBox(height: 14),
          _sectionTitle('المواد المطلوبة'),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['الوحدة', 'الكمية', 'الوصف', 'رقم المادة', '#'],
            data: tender.items.asMap().entries.map((entry) {
              final item = entry.value;
              return [
                item.unit ?? '-',
                (item.quantity ?? 0).toString(),
                item.description ?? '-',
                item.itemNo ?? '-',
                '${entry.key + 1}',
              ];
            }).toList(),
            border: pw.TableBorder.all(width: .6),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.center,
            cellAlignments: const {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 7,
            ),
            columnWidths: const {
              0: pw.FixedColumnWidth(70),
              1: pw.FixedColumnWidth(70),
              2: pw.FlexColumnWidth(4),
              3: pw.FixedColumnWidth(90),
              4: pw.FixedColumnWidth(40),
            },
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'عدد المواد: ${tender.items.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'تاريخ الطباعة: ${AppDateFormatter.dateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> supplierItemOffersPdf(
    TenderDetails tender,
    List<SupplierItemOffer> offers, {
    TenderAnalysis? analysis,
    bool compactAnalysis = false,
  }) async {
    final theme = await _arabicPdfTheme();
    final logo = await _pdfLogo();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        maxPages: 200,
        header: (_) => _compactUniversityHeader(logo),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 7),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: .5)),
          ),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          _sectionTitle('كشف عروض الأسعار'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'رقم العطاء: ${tender.tenderNo ?? tender.id}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                tender.subject ?? 'موضوع العطاء غير محدد',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'تاريخ الطباعة: ${AppDateFormatter.dateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ..._buildOffersByItemSections(tender, offers),
          pw.SizedBox(height: 12),
          pw.Text(
            _offersSummaryText(tender, offers),
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          if (analysis != null) ...[
            pw.SizedBox(height: 12),
            ...compactAnalysis
                ? _compactAiAnalysisReport(analysis)
                : _aiAnalysisReport(analysis),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> itemAssignmentsPdf(
    TenderDetails tender,
    List<Supplier> suppliers,
    List<ItemAssignment> assignments,
  ) async {
    final theme = await _arabicPdfTheme();
    final logo = await _pdfLogo();
    final doc = pw.Document();
    final supplierNames = _assignmentSupplierNames(suppliers, assignments);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        header: (_) => _universityHeader(logo),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 7),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: .5)),
          ),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          _sectionTitle('كشف إحالة العطاء'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'رقم العطاء: ${tender.tenderNo ?? tender.id}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                tender.subject ?? 'موضوع العطاء غير محدد',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'تاريخ الطباعة: ${AppDateFormatter.dateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _itemAssignmentsSummaryTable(tender, supplierNames, assignments),
          pw.NewPage(),
          _committeeRecommendation(),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> companiesAssignmentPdf(
    TenderDetails tender,
    List<Supplier> suppliers,
    List<ItemAssignment> assignments,
  ) async {
    final theme = await _arabicPdfTheme();
    final logo = await _pdfLogo();
    final doc = pw.Document();
    final supplierNames = _assignmentSupplierNames(suppliers, assignments)
        .where(
          (name) =>
              assignments.any((assignment) => assignment.supplierName == name),
        )
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        maxPages: 200,
        header: (_) => _compactUniversityHeader(logo),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 7),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: .5)),
          ),
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          _sectionTitle('كشف إحالة الشركات'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'رقم العطاء: ${tender.tenderNo ?? tender.id}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                tender.subject ?? 'موضوع العطاء غير محدد',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'تاريخ الطباعة: ${AppDateFormatter.dateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          _companiesAssignmentTable(tender, supplierNames, assignments),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _companiesAssignmentTable(
    TenderDetails tender,
    List<String> supplierNames,
    List<ItemAssignment> assignments,
  ) {
    if (supplierNames.isEmpty) {
      return _emptySupplierAssignmentBlock(
        'لا توجد مواد محالة على أي شركة بعد.',
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(width: .6),
      columnWidths: _companyAssignmentColumnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _pdfHeaderCell('الكمية'),
            _pdfHeaderCell('الوصف'),
            _pdfHeaderCell('رقم المادة'),
            _pdfHeaderCell('الإجمالي للمادة'),
            _pdfHeaderCell('إجمالي القيمة'),
            _pdfHeaderCell('عدد المواد'),
            _pdfHeaderCell('اسم الشركة'),
            _pdfHeaderCell('#'),
          ],
        ),
        ...supplierNames.asMap().entries.map((entry) {
          final supplierName = entry.value;
          final supplierAssignments = assignments
              .where((assignment) => assignment.supplierName == supplierName)
              .toList();
          return pw.TableRow(
            children: [
              _pdfWidgetCell(
                _companyAssignmentColumn(
                  supplierAssignments,
                  (assignment) =>
                      _companyAssignmentQuantityLine(tender, assignment),
                ),
              ),
              _pdfWidgetCell(
                _companyAssignmentColumn(
                  supplierAssignments,
                  (assignment) =>
                      _companyAssignmentDescriptionLine(tender, assignment),
                ),
              ),
              _pdfWidgetCell(
                _companyAssignmentColumn(
                  supplierAssignments,
                  (assignment) => _companyAssignmentItemNo(tender, assignment),
                ),
              ),
              _pdfWidgetCell(
                _companyAssignmentColumn(
                  supplierAssignments,
                  (assignment) => _formatPdfNumber(assignment.price),
                ),
              ),
              _pdfTextCell(_companyAssignmentsTotal(supplierAssignments)),
              _pdfTextCell('${supplierAssignments.length}'),
              _pdfTextCell(supplierName),
              _pdfTextCell('${entry.key + 1}'),
            ],
          );
        }),
        _companiesGrandTotalRow(supplierNames, assignments),
      ],
    );
  }

  static pw.TableRow _companiesGrandTotalRow(
    List<String> supplierNames,
    List<ItemAssignment> assignments,
  ) {
    num total = 0;
    var hasValue = false;
    var itemCount = 0;
    for (final supplierName in supplierNames) {
      final supplierAssignments = assignments
          .where((assignment) => assignment.supplierName == supplierName)
          .toList();
      itemCount += supplierAssignments.length;
      for (final assignment in supplierAssignments) {
        if (assignment.price != null) {
          total += assignment.price!;
          hasValue = true;
        }
      }
    }

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _pdfHeaderCell(''),
        _pdfHeaderCell('الإجمالي الكلي لجميع الشركات'),
        _pdfHeaderCell(''),
        _pdfHeaderCell(''),
        _pdfHeaderCell(hasValue ? _formatPdfNumber(total) : '-'),
        _pdfHeaderCell('$itemCount'),
        _pdfHeaderCell(''),
        _pdfHeaderCell(''),
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> get _companyAssignmentColumnWidths =>
      const {
        0: pw.FixedColumnWidth(66),
        1: pw.FlexColumnWidth(5),
        2: pw.FixedColumnWidth(58),
        3: pw.FixedColumnWidth(64),
        4: pw.FixedColumnWidth(72),
        5: pw.FixedColumnWidth(55),
        6: pw.FixedColumnWidth(100),
        7: pw.FixedColumnWidth(26),
      };

  static String _companyAssignmentsTotal(List<ItemAssignment> assignments) {
    if (assignments.isEmpty) return '-';
    num total = 0;
    var hasValue = false;
    for (final assignment in assignments) {
      if (assignment.price != null) {
        total += assignment.price!;
        hasValue = true;
      }
    }
    return hasValue ? _formatPdfNumber(total) : '-';
  }

  static pw.Widget _companyAssignmentColumn(
    List<ItemAssignment> assignments,
    String Function(ItemAssignment assignment) lineBuilder,
  ) {
    if (assignments.isEmpty) {
      return pw.Text('-', style: const pw.TextStyle(fontSize: 9));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: assignments.asMap().entries.map((entry) {
        final line = lineBuilder(entry.value);
        final isLast = entry.key == assignments.length - 1;
        return pw.Padding(
          padding: pw.EdgeInsets.only(bottom: isLast ? 0 : 4),
          child: pw.Text(
            line,
            textAlign: pw.TextAlign.right,
            style: _pdfCellTextStyle(line),
          ),
        );
      }).toList(),
    );
  }

  static String _companyAssignmentItemNo(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final itemIndex = tender.items.indexWhere(
      (item) => item.id == assignment.tenderItemId,
    );
    final item = itemIndex == -1 ? null : tender.items[itemIndex];
    final itemNo = item?.itemNo ?? assignment.tenderItemId.toString();
    return _normalizePdfText(itemNo);
  }

  static String _companyAssignmentDescriptionLine(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final itemIndex = tender.items.indexWhere(
      (item) => item.id == assignment.tenderItemId,
    );
    final item = itemIndex == -1 ? null : tender.items[itemIndex];
    final description = item?.description?.trim();
    return _normalizePdfText(
      description == null || description.isEmpty ? '-' : description,
    );
  }

  static String _companyAssignmentQuantityLine(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final itemIndex = tender.items.indexWhere(
      (item) => item.id == assignment.tenderItemId,
    );
    final item = itemIndex == -1 ? null : tender.items[itemIndex];
    final quantity = assignment.quantity ?? item?.quantity;
    final unit = _assignmentUnit(tender, assignment);
    return _normalizePdfText('الكمية: ${_formatPdfNumber(quantity)} $unit');
  }

  static String _formatPdfNumber(num? value) {
    if (value == null) return '-';
    final rounded = double.parse(value.toStringAsFixed(3));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    var text = rounded.toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  static pw.Widget _pdfWidgetCell(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: child,
    );
  }

  static List<String> _assignmentSupplierNames(
    List<Supplier> suppliers,
    List<ItemAssignment> assignments,
  ) {
    final names = <String>[];
    for (final supplier in suppliers) {
      if (!names.contains(supplier.displayName)) {
        names.add(supplier.displayName);
      }
    }
    for (final assignment in assignments) {
      final name = assignment.supplierName?.trim();
      if (name != null && name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }
    return names;
  }

  static pw.Widget _itemAssignmentsSummaryTable(
    TenderDetails tender,
    List<String> supplierNames,
    List<ItemAssignment> assignments,
  ) {
    if (supplierNames.isEmpty) {
      return _emptySupplierAssignmentBlock(
        'لا يوجد موردون مرتبطون بهذا العطاء.',
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Table(
          border: pw.TableBorder.all(width: .6),
          columnWidths: _assignmentTableColumnWidths,
          children: [
            pw.TableRow(
              children: [
                _pdfHeaderCell('السعر الحالي'),
                _pdfHeaderCell('سعر الوحدة'),
                _pdfHeaderCell('الكمية'),
                _pdfHeaderCell('الوحدة'),
                _pdfHeaderCell('بلد المنشأ'),
                _pdfHeaderCell('المادة المحالة'),
                _pdfHeaderCell('المورد'),
                _pdfHeaderCell('#'),
              ],
            ),
          ],
        ),
        ...supplierNames.asMap().entries.expand((entry) {
          final supplierName = entry.value;
          final supplierAssignments = assignments
              .where((assignment) => assignment.supplierName == supplierName)
              .toList();

          if (supplierAssignments.isEmpty) {
            return [
              pw.Table(
                border: pw.TableBorder.all(width: .6),
                columnWidths: _assignmentTableColumnWidths,
                children: [
                  pw.TableRow(
                    children: [
                      _pdfTextCell('-'),
                      _pdfTextCell('-'),
                      _pdfTextCell('-'),
                      _pdfTextCell('-'),
                      _pdfTextCell('-'),
                      _pdfTextCell('لم يتم إحالة مواد عليه'),
                      _pdfTextCell(supplierName),
                      _pdfTextCell('${entry.key + 1}'),
                    ],
                  ),
                ],
              ),
            ];
          }

          return supplierAssignments.asMap().entries.expand((assignmentEntry) {
            final rowLabel = '${entry.key + 1}.${assignmentEntry.key + 1}';
            return _assignmentTableBlock(
              tender: tender,
              assignment: assignmentEntry.value,
              supplierName: supplierName,
              rowLabel: rowLabel,
            );
          });
        }),
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> get _assignmentTableColumnWidths =>
      const {
        0: pw.FixedColumnWidth(78),
        1: pw.FixedColumnWidth(78),
        2: pw.FixedColumnWidth(48),
        3: pw.FixedColumnWidth(48),
        4: pw.FixedColumnWidth(72),
        5: pw.FlexColumnWidth(3),
        6: pw.FlexColumnWidth(1.8),
        7: pw.FixedColumnWidth(36),
      };

  static List<pw.Widget> _assignmentTableBlock({
    required TenderDetails tender,
    required ItemAssignment assignment,
    required String supplierName,
    required String rowLabel,
  }) {
    return [
      pw.Table(
        border: pw.TableBorder.all(width: .6),
        columnWidths: _assignmentTableColumnWidths,
        children: [
          pw.TableRow(
            children: [
              _pdfTextCell(assignment.price?.toString() ?? '-'),
              _pdfTextCell(
                assignment.unitPrice?.toString() ??
                    _assignmentUnitPrice(tender, assignment),
              ),
              _pdfTextCell(_assignmentQuantity(tender, assignment)),
              _pdfTextCell(_assignmentUnit(tender, assignment)),
              _pdfTextCell(assignment.origin ?? '-'),
              _pdfTextCell(_assignmentMaterialLine(tender, assignment)),
              _pdfTextCell(supplierName),
              _pdfTextCell(rowLabel),
            ],
          ),
        ],
      ),
      ..._assignmentDetailsRows(assignment),
    ];
  }

  static pw.Widget _emptySupplierAssignmentBlock(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: .6)),
      child: pw.Text(
        message,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static String _assignmentMaterialLine(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final itemIndex = tender.items.indexWhere(
      (item) => item.id == assignment.tenderItemId,
    );
    final item = itemIndex == -1 ? null : tender.items[itemIndex];
    final orderText = itemIndex == -1 ? '-' : '${itemIndex + 1}';
    final itemNo = item?.itemNo ?? assignment.tenderItemId.toString();
    final description = item?.description;
    final base = 'مادة $orderText | رقم $itemNo';
    if (description == null || description.trim().isEmpty) return base;
    return '$base | $description';
  }

  static String _assignmentQuantity(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    if (assignment.quantity != null) return assignment.quantity.toString();
    final item = _assignmentTenderItem(tender, assignment);
    return item?.quantity?.toString() ?? '-';
  }

  static String _assignmentUnit(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final unit = assignment.unit?.trim();
    if (unit != null && unit.isNotEmpty) return unit;
    return _assignmentTenderItem(tender, assignment)?.unit ?? '-';
  }

  static String _assignmentUnitPrice(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final quantity =
        assignment.quantity ??
        _assignmentTenderItem(tender, assignment)?.quantity;
    final price = assignment.price;
    if (price == null || quantity == null || quantity == 0) return '-';
    return (price / quantity).toString();
  }

  static TenderItem? _assignmentTenderItem(
    TenderDetails tender,
    ItemAssignment assignment,
  ) {
    final itemIndex = tender.items.indexWhere(
      (item) => item.id == assignment.tenderItemId,
    );
    return itemIndex == -1 ? null : tender.items[itemIndex];
  }

  static List<pw.Widget> _assignmentDetailsRows(ItemAssignment assignment) {
    final details = _assignmentDetailsLine(assignment);
    if (details.trim().isEmpty || details == '-') return const [];
    final chunks = _splitTableCellText(details, chunkSize: 260);
    return chunks.map((chunk) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border(
            left: const pw.BorderSide(width: .6),
            right: const pw.BorderSide(width: .6),
            bottom: const pw.BorderSide(width: .6),
          ),
        ),
        child: pw.Text(
          chunk,
          textAlign: pw.TextAlign.right,
          style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.35),
        ),
      );
    }).toList();
  }

  static String _assignmentDetailsLine(ItemAssignment assignment) {
    final type = assignment.isTechnical ? 'فنية' : 'رئيسية';
    final lines = <String>['إحالة $type'];
    if (assignment.assignmentNote?.trim().isNotEmpty ?? false) {
      lines.add('ملاحظة: ${assignment.assignmentNote!.trim()}');
    }
    if (assignment.offerNote?.trim().isNotEmpty ?? false) {
      lines.add('عرض: ${assignment.offerNote!.trim()}');
    }
    if (assignment.hasAlternative) {
      lines.add('بديل: ${assignment.alternativeDescription ?? '-'}');
    }
    return lines.join(' | ');
  }

  static pw.Widget _committeeRecommendation() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('توصية اللجنة'),
        pw.SizedBox(height: 12),
        pw.Container(
          height: 120,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: .6)),
        ),
        pw.SizedBox(height: 28),
        pw.Table(
          border: pw.TableBorder.all(width: .6),
          children: [
            pw.TableRow(
              children: [
                _signatureCell('عضو'),
                _signatureCell('عضو'),
                _signatureCell('عضو'),
                _signatureCell('عضو'),
                _signatureCell('رئيس اللجنة'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _signatureCell(String label) {
    return pw.Container(
      height: 88,
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(height: .6, width: 90, color: PdfColors.black),
          pw.Text('التوقيع', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildOffersByItemSections(
    TenderDetails tender,
    List<SupplierItemOffer> offers,
  ) {
    final offersByItem = <int, List<SupplierItemOffer>>{};
    for (final offer in offers) {
      offersByItem.putIfAbsent(offer.itemId, () => []).add(offer);
    }

    final sortedItems = _sortedTenderItems(tender.items);
    final sections = <pw.Widget>[];
    final processedItemIds = <int>{};
    var sectionIndex = 0;

    for (var index = 0; index < sortedItems.length; index++) {
      final item = sortedItems[index];
      final itemId = item.id;
      if (itemId == null) continue;

      processedItemIds.add(itemId);
      sectionIndex++;
      if (sections.isNotEmpty) {
        sections.add(pw.NewPage(freeSpace: 160));
      }
      sections.add(
        _itemOffersSection(
          itemIndex: sectionIndex,
          item: item,
          offers: offersByItem[itemId] ?? const [],
        ),
      );
      sections.add(pw.SizedBox(height: 14));
    }

    for (final entry in offersByItem.entries) {
      if (processedItemIds.contains(entry.key)) continue;
      final sample = entry.value.first;
      sectionIndex++;
      if (sections.isNotEmpty) {
        sections.add(pw.NewPage(freeSpace: 160));
      }
      sections.add(
        _itemOffersSection(
          itemIndex: sectionIndex,
          item: null,
          offers: entry.value,
          fallbackItemNo: sample.itemNo,
          fallbackDescription: sample.description,
          fallbackQuantity: sample.quantity,
          fallbackUnit: sample.unit,
        ),
      );
      sections.add(pw.SizedBox(height: 14));
    }

    if (sections.isNotEmpty) {
      sections.removeLast();
    }

    if (sections.isEmpty) {
      sections.add(
        _emptySupplierAssignmentBlock('لا توجد عروض أسعار مسجلة لهذا العطاء.'),
      );
    }

    return sections;
  }

  static List<TenderItem> _sortedTenderItems(List<TenderItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final aNo = num.tryParse(a.itemNo?.trim() ?? '');
      final bNo = num.tryParse(b.itemNo?.trim() ?? '');
      if (aNo != null && bNo != null) return aNo.compareTo(bNo);
      if (aNo != null) return -1;
      if (bNo != null) return 1;
      return (a.itemNo ?? '').compareTo(b.itemNo ?? '');
    });
    return sorted;
  }

  static String _offersSummaryText(
    TenderDetails tender,
    List<SupplierItemOffer> offers,
  ) {
    final itemIds = tender.items
        .map((item) => item.id)
        .whereType<int>()
        .toSet();
    for (final offer in offers) {
      itemIds.add(offer.itemId);
    }
    final supplierIds = offers.map((offer) => offer.supplierId).toSet();
    return 'عدد المواد: ${itemIds.length} | عدد الموردين: ${supplierIds.length} | عدد العروض: ${offers.length}';
  }

  static List<pw.Widget> _aiAnalysisReport(TenderAnalysis analysis) {
    return [
      _aiAnalysisHero(analysis),
      pw.SizedBox(height: 12),
      _aiAnalysisMetrics(analysis),
      pw.SizedBox(height: 12),
      _aiConceptsGuide(),
      pw.SizedBox(height: 12),
      _aiAwardsTable(analysis.awards),
      pw.SizedBox(height: 12),
      ...analysis.awards.map(_aiAwardReasonCard),
    ];
  }

  static List<pw.Widget> _compactAiAnalysisReport(TenderAnalysis analysis) {
    return [
      _aiAnalysisHero(analysis),
      pw.SizedBox(height: 12),
      _aiAnalysisMetrics(analysis),
      pw.SizedBox(height: 12),
      _compactAiAwardsSummary(analysis.awards),
      pw.SizedBox(height: 8),
      pw.Text(
        'ملاحظة: تم توليد نسخة مختصرة من التحليل لضمان إنشاء ملف PDF بنجاح.',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    ];
  }

  static pw.Widget _compactAiAwardsSummary(List<AnalysisAward> awards) {
    if (awards.isEmpty) {
      return _emptySupplierAssignmentBlock('لا توجد نتائج تحليل متاحة.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: awards.take(30).map((award) {
        final reason = award.awardReason?.trim();
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300, width: .5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                _pdfSafeText(
                  '${award.itemNo ?? '-'} - ${award.description ?? '-'}',
                  maxChars: 140,
                ),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _pdfSafeText(
                  'المورد الموصى به: ${award.recommendedSupplierName ?? '-'}',
                  maxChars: 120,
                ),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'الفني: ${_scoreText(award.technicalScore)} | المالي: ${_scoreText(award.financialScore)} | النهائي: ${_scoreText(award.finalScore)} | الثقة: ${_scoreText(award.confidenceScore)}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              if (reason != null && reason.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  _pdfSafeText(reason, maxChars: 300),
                  style: _pdfCellTextStyle(reason),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _aiAnalysisHero(TenderAnalysis analysis) {
    final summary = analysis.executiveSummary.summary?.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'تحليل الذكاء الاصطناعي لعروض الأسعار',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'AI Analysis',
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    color: PdfColors.blueGrey900,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            summary == null || summary.isEmpty
                ? 'تم تحليل العروض فنياً ومالياً واقتراح أفضل الإحالات لكل مادة.'
                : _pdfSafeText(summary, maxChars: 500),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: _pdfCellFontSize(summary ?? ''),
              lineSpacing: 1.1,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  static pw.Widget _aiAnalysisMetrics(TenderAnalysis analysis) {
    return pw.Row(
      children: [
        _aiMetricCard(
          'إجمالي المواد',
          _analysisValue(analysis.executiveSummary.totalItems),
          PdfColors.blue50,
        ),
        pw.SizedBox(width: 8),
        _aiMetricCard(
          'مواد موصى بها',
          _analysisValue(analysis.executiveSummary.awardedItems),
          PdfColors.green50,
        ),
        pw.SizedBox(width: 8),
        _aiMetricCard(
          'الوزن الفني',
          _percentText(analysis.committeeDecision.technicalWeight),
          PdfColors.amber50,
        ),
        pw.SizedBox(width: 8),
        _aiMetricCard(
          'الوزن المالي',
          _percentText(analysis.committeeDecision.financialWeight),
          PdfColors.red50,
        ),
      ],
    );
  }

  static pw.Widget _aiMetricCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300, width: .4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _aiConceptsGuide() {
    const concepts = [
      (
        'الوزن الفني',
        'معيار يقيس جودة المنتج أو الخدمة من الناحية الفنية، ويشمل المواصفات والجودة وبلد المنشأ والمتانة والسلامة. كلما ارتفع زادت أهمية الجودة في الاختيار النهائي.',
      ),
      (
        'الوزن المالي',
        'معيار يقيس أهمية السعر في التقييم، حيث تتم مقارنة الأسعار بين الموردين لتحديد أفضل قيمة مقابل السعر.',
      ),
      (
        'الدرجة الفنية',
        'تقييم جودة العرض بناءً على المواصفات الفنية مقارنة بالعروض الأخرى.',
      ),
      ('الدرجة المالية', 'تقييم يعتمد على سعر العرض مقارنة بأقل سعر مقدم.'),
      (
        'الدرجة النهائية',
        'مجموع الدرجة الفنية والدرجة المالية بعد تطبيق الأوزان المعتمدة.',
      ),
      (
        'درجة الثقة',
        'مؤشر يوضح مدى دقة توصية النظام، وترتفع عند وضوح الفروقات بين العروض وتنخفض عند تقاربها أو نقص البيانات.',
      ),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300, width: .5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 22,
                height: 22,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.amber100,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'i',
                    textDirection: pw.TextDirection.ltr,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'شرح مفاهيم تقييم العطاءات',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: concepts
                .map(
                  (concept) => pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                        color: PdfColors.grey300,
                        width: .4,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Text(
                          concept.$1,
                          style: pw.TextStyle(
                            fontSize: 9.2,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          concept.$2,
                          textAlign: pw.TextAlign.justify,
                          style: const pw.TextStyle(
                            fontSize: 7.8,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(7),
              border: pw.Border.all(color: PdfColors.amber200, width: .4),
            ),
            child: pw.Text(
              'ملاحظة: هذه النتائج تم إنشاؤها بناءً على تحليل بيانات العطاءات وليست قراراً نهائياً ملزماً.',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _aiAwardsTable(List<AnalysisAward> awards) {
    if (awards.isEmpty) {
      return _emptySupplierAssignmentBlock('لا توجد نتائج تحليل متاحة.');
    }

    return pw.Table(
      border: pw.TableBorder.all(width: .5, color: PdfColors.grey500),
      columnWidths: const {
        0: pw.FixedColumnWidth(58),
        1: pw.FixedColumnWidth(58),
        2: pw.FixedColumnWidth(58),
        3: pw.FixedColumnWidth(58),
        4: pw.FlexColumnWidth(2),
        5: pw.FixedColumnWidth(55),
        6: pw.FlexColumnWidth(2.3),
        7: pw.FixedColumnWidth(42),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _pdfHeaderCell('الثقة'),
            _pdfHeaderCell('النهائي'),
            _pdfHeaderCell('المالي'),
            _pdfHeaderCell('الفني'),
            _pdfHeaderCell('المورد الموصى به'),
            _pdfHeaderCell('نوع العرض'),
            _pdfHeaderCell('المادة'),
            _pdfHeaderCell('#'),
          ],
        ),
        ...awards.asMap().entries.map((entry) {
          final award = entry.value;
          return pw.TableRow(
            children: [
              _pdfTextCell(_scoreText(award.confidenceScore)),
              _pdfTextCell(_scoreText(award.finalScore)),
              _pdfTextCell(_scoreText(award.financialScore)),
              _pdfTextCell(_scoreText(award.technicalScore)),
              _pdfTextCell(award.recommendedSupplierName ?? '-', maxChars: 70),
              _pdfTextCell(award.hasAlternative ? 'بديل' : 'أساسي'),
              _pdfTextCell(
                '${award.itemNo ?? '-'} - ${award.description ?? '-'}',
                maxChars: 90,
              ),
              _pdfTextCell('${entry.key + 1}'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _aiAwardReasonCard(AnalysisAward award) {
    final reason = award.awardReason?.trim();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: .5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _pdfSafeText(
                    '${award.itemNo ?? '-'} - ${award.description ?? '-'}',
                    maxChars: 120,
                  ),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  _pdfSafeText(
                    'التوصية: ${award.recommendedSupplierName ?? '-'}',
                    maxChars: 100,
                  ),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            reason == null || reason.isEmpty
                ? 'لا يوجد سبب توصية مرفق.'
                : _pdfSafeText(reason, maxChars: 450),
            textAlign: pw.TextAlign.justify,
            style: _pdfCellTextStyle(reason ?? ''),
          ),
        ],
      ),
    );
  }

  static String _analysisValue(Object? value) => value?.toString() ?? '-';

  static String _percentText(num? value) => value == null ? '-' : '$value%';

  static String _scoreText(num? value) => value?.toString() ?? '-';

  static pw.Widget _itemOffersSection({
    required int itemIndex,
    required TenderItem? item,
    required List<SupplierItemOffer> offers,
    String? fallbackItemNo,
    String? fallbackDescription,
    num? fallbackQuantity,
    String? fallbackUnit,
  }) {
    final supplierGroups = _groupOffersBySupplier(offers);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _materialInfoHeader(
          itemIndex: itemIndex,
          item: item,
          fallbackItemNo: fallbackItemNo,
          fallbackDescription: fallbackDescription,
          fallbackQuantity: fallbackQuantity ?? offers.firstOrNull?.quantity,
          fallbackUnit: fallbackUnit ?? offers.firstOrNull?.unit,
        ),
        pw.SizedBox(height: 6),
        supplierGroups.isEmpty
            ? _emptySupplierAssignmentBlock('لا توجد عروض مسجلة لهذه المادة.')
            : _itemSupplierOffersTable(supplierGroups),
      ],
    );
  }

  static pw.Widget _materialInfoHeader({
    required int itemIndex,
    required TenderItem? item,
    String? fallbackItemNo,
    String? fallbackDescription,
    num? fallbackQuantity,
    String? fallbackUnit,
  }) {
    final itemNo = item?.itemNo ?? fallbackItemNo ?? '-';
    final description = _pdfSafeText(
      item?.description ?? fallbackDescription ?? '-',
      maxChars: 180,
    );
    final quantity = item?.quantity ?? fallbackQuantity;
    final unit = item?.unit ?? fallbackUnit ?? '-';
    final quantityText = quantity?.toString() ?? '-';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: .6),
        color: PdfColors.grey100,
      ),
      child: pw.Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          pw.Text(
            'مادة $itemIndex',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'رقم المادة: $itemNo',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'الوصف: $description',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'الكمية: $quantityText',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text('الوحدة: $unit', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static List<List<SupplierItemOffer>> _groupOffersBySupplier(
    List<SupplierItemOffer> offers,
  ) {
    final grouped = <int, List<SupplierItemOffer>>{};
    for (final offer in offers) {
      grouped.putIfAbsent(offer.supplierId, () => []).add(offer);
    }
    return grouped.values.toList();
  }

  static pw.Widget _itemSupplierOffersTable(
    List<List<SupplierItemOffer>> supplierGroups,
  ) {
    final primaryOffers = supplierGroups.map(_primaryOffer).toList();
    final lowestPriceOfferId = _lowestPriceOfferId(primaryOffers);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Table(
          border: pw.TableBorder.all(width: .6),
          columnWidths: _offerTableColumnWidths,
          children: [
            pw.TableRow(
              children: [
                _pdfHeaderCell('السعر الإجمالي'),
                _pdfHeaderCell('سعر الوحدة'),
                _pdfHeaderCell('الكمية'),
                _pdfHeaderCell('الوحدة'),
                _pdfHeaderCell('وصف المادة'),
                _pdfHeaderCell('بلد المنشأ'),
                _pdfHeaderCell('الوصف'),
                _pdfHeaderCell('المورد'),
                _pdfHeaderCell('#'),
              ],
            ),
          ],
        ),
        ...supplierGroups.asMap().entries.expand((groupEntry) {
          final offers = groupEntry.value;
          final primary = _primaryOffer(offers);
          final alternatives = offers
              .where((offer) => offer.id != primary.id && offer.hasAlternative)
              .toList();
          final extraPrimaries = offers
              .where((offer) => offer.id != primary.id && !offer.hasAlternative)
              .toList();
          final orderedOffers = [primary, ...extraPrimaries, ...alternatives];

          return orderedOffers.asMap().entries.expand((offerEntry) {
            return _offerTableBlock(
              offer: offerEntry.value,
              primary: primary,
              rowLabel: '${groupEntry.key + 1}.${offerEntry.key + 1}',
              isLowestPrice: offerEntry.value.id == lowestPriceOfferId,
            );
          });
        }),
      ],
    );
  }

  static int? _lowestPriceOfferId(List<SupplierItemOffer> primaryOffers) {
    SupplierItemOffer? lowest;
    num? lowestPrice;
    for (final offer in primaryOffers) {
      final price = offer.price ?? _calculatedTotalPrice(offer);
      if (price == null) continue;
      if (lowestPrice == null || price < lowestPrice) {
        lowestPrice = price;
        lowest = offer;
      }
    }
    return lowest?.id;
  }

  static Map<int, pw.TableColumnWidth> get _offerTableColumnWidths => const {
    0: pw.FixedColumnWidth(76),
    1: pw.FixedColumnWidth(76),
    2: pw.FixedColumnWidth(48),
    3: pw.FixedColumnWidth(48),
    4: pw.FixedColumnWidth(58),
    5: pw.FixedColumnWidth(58),
    6: pw.FlexColumnWidth(2.8),
    7: pw.FlexColumnWidth(1.7),
    8: pw.FixedColumnWidth(32),
  };

  static List<pw.Widget> _offerTableBlock({
    required SupplierItemOffer offer,
    required SupplierItemOffer primary,
    required String rowLabel,
    bool isLowestPrice = false,
  }) {
    final originParts = _splitTableCellText(
      _truncateForPdf(_offerOriginLine(offer), 320),
      chunkSize: 80,
    );
    final descriptionParts = _splitTableCellText(
      _truncateForPdf(_offerDescriptionLine(offer, primary), 1200),
      chunkSize: 210,
    );
    final supplierParts = _splitTableCellText(
      _truncateForPdf(offer.supplierName ?? primary.supplierName ?? '-', 360),
      chunkSize: 90,
    );
    final rowCount = [
      originParts.length,
      descriptionParts.length,
      supplierParts.length,
    ].reduce((value, element) => value > element ? value : element);

    final rows = List.generate(rowCount, (index) {
      final isFirst = index == 0;
      return pw.TableRow(
        children: [
          isFirst && isLowestPrice
              ? _pdfHighlightedTextCell(_offerTotalPriceLine(offer))
              : _pdfTextCell(
                  isFirst ? _offerTotalPriceLine(offer) : '',
                  blankWhenEmpty: true,
                ),
          _pdfTextCell(
            isFirst ? _offerUnitPriceLine(offer) : '',
            blankWhenEmpty: true,
          ),
          _pdfTextCell(
            isFirst ? _offerQuantityLine(offer) : '',
            blankWhenEmpty: true,
          ),
          _pdfTextCell(
            isFirst ? _offerUnitLine(offer) : '',
            blankWhenEmpty: true,
          ),
          _pdfTextCell(
            isFirst ? _offerMaterialTypeLine(offer, primary) : '',
            blankWhenEmpty: true,
          ),
          _pdfTextCell(_cellChunk(originParts, index), blankWhenEmpty: true),
          _pdfTextCell(
            _cellChunk(descriptionParts, index),
            blankWhenEmpty: true,
          ),
          _pdfTextCell(_cellChunk(supplierParts, index), blankWhenEmpty: true),
          _pdfTextCell(isFirst ? rowLabel : '', blankWhenEmpty: true),
        ],
      );
    });

    return [
      pw.Table(
        border: pw.TableBorder.all(width: .6),
        columnWidths: _offerTableColumnWidths,
        children: rows,
      ),
      ..._offerNoteRows(offer),
    ];
  }

  static List<pw.Widget> _offerNoteRows(SupplierItemOffer offer) {
    final note = _normalizePdfText(offer.note);
    if (note == '-') return const [];

    final supplier = offer.supplierName ?? 'مورد #${offer.supplierId}';
    final type = offer.hasAlternative ? 'بديل' : 'أساسي';
    final chunks = _splitTableCellText(
      _truncateForPdf('ملاحظة $supplier - $type: $note', 900),
      chunkSize: 230,
    );

    return chunks.map((chunk) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border(
            left: const pw.BorderSide(width: .6),
            right: const pw.BorderSide(width: .6),
            bottom: const pw.BorderSide(width: .6),
          ),
        ),
        child: pw.Text(
          chunk,
          textAlign: pw.TextAlign.right,
          style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.35),
        ),
      );
    }).toList();
  }

  static pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _pdfTextCell(
    String text, {
    int maxChars = 90,
    bool blankWhenEmpty = false,
  }) {
    if (blankWhenEmpty && text.trim().isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.SizedBox(height: 8),
      );
    }
    final normalizedText = maxChars < 0 ? '-' : _normalizePdfText(text);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: _pdfCellText(normalizedText),
    );
  }

  static pw.Widget _pdfHighlightedTextCell(String text) {
    final normalizedText = _normalizePdfText(text);
    return pw.Container(
      width: double.infinity,
      color: PdfColors.black,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        normalizedText,
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: _pdfCellFontSize(normalizedText),
          lineSpacing: 1.3,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _pdfCellText(String text, {bool center = false}) {
    final normalized = _normalizePdfText(text);
    final textAlign = center ? pw.TextAlign.center : pw.TextAlign.right;

    return pw.Text(
      normalized,
      textAlign: textAlign,
      style: _pdfCellTextStyle(normalized),
    );
  }

  static pw.TextStyle _pdfCellTextStyle(String text) {
    return pw.TextStyle(fontSize: _pdfCellFontSize(text), lineSpacing: 1.3);
  }

  static double _pdfCellFontSize(String text) {
    final length = text.length;
    return length > 700
        ? 6
        : length > 420
        ? 6.7
        : length > 260
        ? 7.2
        : length > 140
        ? 7.8
        : 8.5;
  }

  static String _pdfSafeText(Object? value, {required int maxChars}) {
    if (maxChars < 0) return '-';
    final normalized = _normalizePdfText(value);
    return normalized;
  }

  static String _truncateForPdf(Object? value, int maxChars) {
    final normalized = _normalizePdfText(value);
    if (normalized == '-' || normalized.length <= maxChars) return normalized;
    return '${normalized.substring(0, maxChars - 1).trimRight()}…';
  }

  static List<String> _splitTableCellText(
    Object? value, {
    required int chunkSize,
  }) {
    final text = _normalizePdfText(value);
    if (text == '-' || text.length <= chunkSize) return [text];

    final chunks = <String>[];
    var remaining = text;
    while (remaining.length > chunkSize) {
      var splitAt = remaining.lastIndexOf(' ', chunkSize);
      if (splitAt < chunkSize * .55) splitAt = chunkSize;
      chunks.add(remaining.substring(0, splitAt).trim());
      remaining = remaining.substring(splitAt).trim();
    }
    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }

  static String _cellChunk(List<String> chunks, int index) {
    if (index >= chunks.length) return '';
    return chunks[index];
  }

  static String _normalizePdfText(Object? value) {
    final normalized = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized == null || normalized.isEmpty ? '-' : normalized;
  }

  static SupplierItemOffer _primaryOffer(List<SupplierItemOffer> offers) {
    return offers.firstWhere(
      (offer) => !offer.hasAlternative,
      orElse: () => offers.first,
    );
  }

  static String _offerDescriptionLine(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    final description = offer.hasAlternative
        ? offer.alternativeDescription ?? offer.description ?? '-'
        : offer.description ?? '-';
    return description;
  }

  static String _offerMaterialTypeLine(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    return _offerLineLabel(offer, primary);
  }

  static String _offerUnitPriceLine(SupplierItemOffer offer) {
    final unitPrice = offer.unitPrice ?? _calculatedUnitPrice(offer);
    return unitPrice?.toString() ?? '-';
  }

  static String _offerTotalPriceLine(SupplierItemOffer offer) {
    final totalPrice = offer.price ?? _calculatedTotalPrice(offer);
    return totalPrice?.toString() ?? '-';
  }

  static num? _calculatedUnitPrice(SupplierItemOffer offer) {
    final price = offer.price;
    final quantity = offer.quantity;
    if (price == null || quantity == null || quantity == 0) return null;
    return price / quantity;
  }

  static num? _calculatedTotalPrice(SupplierItemOffer offer) {
    final unitPrice = offer.unitPrice;
    final quantity = offer.quantity;
    if (unitPrice == null || quantity == null) return null;
    return unitPrice * quantity;
  }

  static String _offerQuantityLine(SupplierItemOffer offer) {
    return offer.quantity?.toString() ?? '-';
  }

  static String _offerUnitLine(SupplierItemOffer offer) {
    return offer.unit ?? '-';
  }

  static String _offerOriginLine(SupplierItemOffer offer) {
    return offer.origin ?? '-';
  }

  static String _offerLineLabel(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    if (offer.id == primary.id) return 'أساسي';
    return offer.hasAlternative ? 'بديل' : 'إضافي';
  }

  static pw.Widget _universityHeader(pw.ImageProvider? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: .8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: logo == null
                  ? pw.SizedBox(width: 58, height: 58)
                  : pw.Image(logo, width: 58, height: 58),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'جامعة مؤتة',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'MUTAH UNIVERSITY',
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'وحدة اللوازم',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _compactUniversityHeader(pw.ImageProvider? logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: .6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          logo == null
              ? pw.SizedBox(width: 34, height: 34)
              : pw.Image(logo, width: 34, height: 34),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'جامعة مؤتة - وحدة اللوازم',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'MUTAH UNIVERSITY',
                  textDirection: pw.TextDirection.ltr,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  static pw.Widget _itemsPdfHeader(TenderDetails tender) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'كشف مواد وتفاصيل العطاء',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            tender.subject ?? 'موضوع العطاء غير محدد',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  static pw.Widget _itemsTenderDetails(TenderDetails tender) {
    final rows = [
      [
        _detailCell('رقم العطاء', tender.tenderNo ?? tender.id.toString()),
        _detailCell('رقم طلب الشراء', tender.purchaseRequestNo ?? '-'),
        _detailCell('رقم الالتزام المالي', tender.financialCommitmentNo ?? '-'),
      ],
      [
        _detailCell('الحالة', tender.status ?? '-'),
        _detailCell('الفئة', tender.category ?? '-'),
        _detailCell('النوع', tender.type ?? '-'),
      ],
      [
        _detailCell('تاريخ الفتح', AppDateFormatter.date(tender.openingDate)),
        _detailCell('تاريخ الإغلاق', AppDateFormatter.date(tender.closeDate)),
        _detailCell(
          'آخر موعد بيع الوثائق',
          AppDateFormatter.date(tender.documentSaleDeadline),
        ),
      ],
      [
        _detailCell('مكان التسليم', tender.submissionLocation ?? '-'),
        _detailCell('طريقة التسليم', tender.submissionMethod ?? '-'),
        _detailCell(
          'قيمة كفالة الدخول',
          tender.bidBondAmount?.toString() ?? '-',
        ),
      ],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('تفاصيل العطاء'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: .6),
          columnWidths: const {
            0: pw.FlexColumnWidth(),
            1: pw.FlexColumnWidth(),
            2: pw.FlexColumnWidth(),
          },
          children: rows
              .map(
                (row) => pw.TableRow(
                  children: row
                      .map(
                        (cell) => pw.Padding(
                          padding: const pw.EdgeInsets.all(7),
                          child: cell,
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static pw.Widget _detailCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(width: 3),
          bottom: pw.BorderSide(width: .6),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static Future<Uint8List> officialTenderPdf(TenderDetails tender) async {
    final theme = await _arabicPdfTheme();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(42),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header('وثيقة العطاء الرسمية', tender),
            pw.SizedBox(height: 32),
            pw.Text(
              'مناقصة رقم ${tender.tenderNo ?? '-'}',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              tender.subject ?? 'موضوع العطاء غير محدد',
              style: const pw.TextStyle(fontSize: 18),
            ),
            pw.SizedBox(height: 26),
            pw.Text('السادة .............................. المحترمين،'),
            pw.SizedBox(height: 16),
            pw.Text(
              'يرجى التكرم بتقديم عروضكم للعطاء أعلاه وفق الشروط والمواصفات المعتمدة. '
              'يتم تسليم العروض في ${tender.submissionLocation ?? '-'} قبل تاريخ ${AppDateFormatter.dateTime(tender.closeDate)}.',
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 16),
            pw.Text('قيمة كفالة الدخول: ${tender.bidBondAmount ?? '-'} دينار.'),
            pw.Spacer(),
            pw.Text('وتفضلوا بقبول فائق الاحترام،'),
            pw.SizedBox(height: 28),
            pw.Text('لجنة العطاءات'),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static Future<void> printPdf(
    Future<Uint8List> bytesBuilder,
    String name,
  ) async {
    final bytes = await bytesBuilder;
    await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
  }

  static Future<void> downloadPdf(
    Future<Uint8List> bytesBuilder,
    String name,
  ) async {
    final bytes = await bytesBuilder;
    await savePdfBytes(bytes, name);
  }

  static pw.Widget _header(String title, TenderDetails tender) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'العطاء: ${tender.tenderNo ?? tender.id} | تاريخ الإنشاء: ${AppDateFormatter.date(tender.createdAt)}',
            style: const pw.TextStyle(color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static Future<pw.ThemeData> _arabicPdfTheme() async {
    final regularData = await rootBundle.load(
      'assets/font/noto/NotoNaskhArabic-Medium.ttf',
    );
    final boldData = await rootBundle.load(
      'assets/font/noto/NotoNaskhArabic-Bold.ttf',
    );
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  static Future<pw.ImageProvider?> _pdfLogo() async {
    try {
      final data = await rootBundle.load('assets/image/mu_logo.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
