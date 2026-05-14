import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/tenders/domain/tender_domain.dart';
import 'app_utils.dart';

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
    List<SupplierItemOffer> offers,
  ) async {
    final theme = await _arabicPdfTheme();
    final logo = await _pdfLogo();
    final doc = pw.Document();
    final groupedOffers = _groupSupplierItemOffers(offers);

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
          _supplierOffersTable(groupedOffers),
          pw.SizedBox(height: 12),
          pw.Text(
            'عدد العروض: ${offers.length} | عدد المواد/الموردين بعد التجميع: ${groupedOffers.length}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
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

    return pw.Table(
      border: pw.TableBorder.all(width: .6),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4),
        1: pw.FixedColumnWidth(90),
        2: pw.FixedColumnWidth(90),
        3: pw.FlexColumnWidth(3.2),
        4: pw.FlexColumnWidth(1.7),
        5: pw.FixedColumnWidth(36),
      },
      children: [
        pw.TableRow(
          children: [
            _pdfHeaderCell('التفاصيل'),
            _pdfHeaderCell('السعر المحال'),
            _pdfHeaderCell('السعر الحالي'),
            _pdfHeaderCell('المواد المحالة'),
            _pdfHeaderCell('المورد'),
            _pdfHeaderCell('#'),
          ],
        ),
        ...supplierNames.asMap().entries.map((entry) {
          final supplierName = entry.value;
          final supplierAssignments = assignments
              .where((assignment) => assignment.supplierName == supplierName)
              .toList();

          if (supplierAssignments.isEmpty) {
            return pw.TableRow(
              children: [
                _pdfTextCell('-'),
                _pdfTextCell('-'),
                _pdfTextCell('-'),
                _pdfTextCell('لم يتم إحالة مواد عليه'),
                _pdfTextCell(supplierName),
                _pdfTextCell('${entry.key + 1}'),
              ],
            );
          }

          return pw.TableRow(
            children: [
              _pdfAssignmentLinesCell(
                supplierAssignments
                    .map((assignment) => _assignmentDetailsLine(assignment))
                    .toList(),
              ),
              _pdfAssignmentLinesCell(
                supplierAssignments
                    .map(
                      (assignment) =>
                          assignment.assignedPrice?.toString() ?? '-',
                    )
                    .toList(),
                center: true,
              ),
              _pdfAssignmentLinesCell(
                supplierAssignments
                    .map((assignment) => assignment.price?.toString() ?? '-')
                    .toList(),
                center: true,
              ),
              _pdfAssignmentLinesCell(
                supplierAssignments
                    .map(
                      (assignment) =>
                          _assignmentMaterialLine(tender, assignment),
                    )
                    .toList(),
              ),
              _pdfTextCell(supplierName),
              _pdfTextCell('${entry.key + 1}'),
            ],
          );
        }),
      ],
    );
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

  static pw.Widget _pdfAssignmentLinesCell(
    List<String> lines, {
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: center
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.stretch,
        children: lines
            .map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Text(
                  line,
                  textAlign: center ? pw.TextAlign.center : pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
            )
            .toList(),
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
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: .6)),
          child: pw.Text(
            'توصية اللجنة :- تم الإحالة المواد على الموردين أعلاه حسب الملاحظات المبينة فيه.',
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.justify,
          ),
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

  static pw.Widget _supplierOffersTable(List<List<SupplierItemOffer>> groups) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _pdfHeaderCell('الملاحظات'),
          _pdfHeaderCell('السعر'),
          _pdfHeaderCell('الوحدة'),
          _pdfHeaderCell('الكمية'),
          _pdfHeaderCell('المادة والعروض'),
          _pdfHeaderCell('رقم المادة'),
          _pdfHeaderCell('المورد'),
          _pdfHeaderCell('#'),
        ],
      ),
      ...groups.asMap().entries.map((entry) {
        final offers = entry.value;
        final primary = _primaryOffer(offers);
        final alternatives = offers
            .where((offer) => offer.id != primary.id && offer.hasAlternative)
            .toList();
        final extraPrimaries = offers
            .where((offer) => offer.id != primary.id && !offer.hasAlternative)
            .toList();
        final orderedOffers = [primary, ...extraPrimaries, ...alternatives];

        return pw.TableRow(
          children: [
            _pdfOfferLinesCell(
              orderedOffers
                  .map((offer) => _offerNoteLine(offer, primary))
                  .toList(),
            ),
            _pdfOfferLinesCell(
              orderedOffers
                  .map((offer) => _offerPriceLine(offer, primary))
                  .toList(),
            ),
            _pdfOfferLinesCell(
              orderedOffers
                  .map((offer) => _offerUnitLine(offer, primary))
                  .toList(),
              center: true,
            ),
            _pdfOfferLinesCell(
              orderedOffers
                  .map((offer) => _offerQuantityLine(offer, primary))
                  .toList(),
              center: true,
            ),
            _pdfOfferLinesCell(
              orderedOffers
                  .map((offer) => _offerDescriptionLine(offer, primary))
                  .toList(),
            ),
            _pdfTextCell(primary.itemNo ?? primary.itemId.toString()),
            _pdfTextCell(primary.supplierName ?? '-'),
            _pdfTextCell('${entry.key + 1}'),
          ],
        );
      }),
    ];

    return pw.Table(
      border: pw.TableBorder.all(width: .6),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FixedColumnWidth(86),
        2: pw.FixedColumnWidth(62),
        3: pw.FixedColumnWidth(62),
        4: pw.FlexColumnWidth(3),
        5: pw.FixedColumnWidth(72),
        6: pw.FlexColumnWidth(2),
        7: pw.FixedColumnWidth(34),
      },
      children: rows,
    );
  }

  static pw.Widget _pdfOfferLinesCell(
    List<String> lines, {
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: center
            ? pw.CrossAxisAlignment.center
            : pw.CrossAxisAlignment.stretch,
        children: lines
            .map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  line,
                  textAlign: center ? pw.TextAlign.center : pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
            )
            .toList(),
      ),
    );
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

  static pw.Widget _pdfTextCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.right,
        style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 2),
      ),
    );
  }

  static List<List<SupplierItemOffer>> _groupSupplierItemOffers(
    List<SupplierItemOffer> offers,
  ) {
    final grouped = <String, List<SupplierItemOffer>>{};
    for (final offer in offers) {
      final key = '${offer.supplierId}-${offer.itemId}';
      grouped.putIfAbsent(key, () => []).add(offer);
    }
    return grouped.values.toList();
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
    final label = _offerLineLabel(offer, primary);
    final description = offer.hasAlternative
        ? offer.alternativeDescription ?? offer.description ?? '-'
        : offer.description ?? '-';
    return '$label: $description';
  }

  static String _offerPriceLine(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    return '${_offerLineLabel(offer, primary)}: ${offer.price?.toString() ?? '-'}';
  }

  static String _offerQuantityLine(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    return '${_offerLineLabel(offer, primary)}: ${offer.quantity?.toString() ?? '-'}';
  }

  static String _offerUnitLine(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    return '${_offerLineLabel(offer, primary)}: ${offer.unit ?? '-'}';
  }

  static String _offerNoteLine(
    SupplierItemOffer offer,
    SupplierItemOffer primary,
  ) {
    return '${_offerLineLabel(offer, primary)}: ${offer.note ?? '-'}';
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
    await Printing.sharePdf(bytes: bytes, filename: name);
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
      'assets/font/cairo/Cairo-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/font/cairo/Cairo-Bold.ttf');
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
