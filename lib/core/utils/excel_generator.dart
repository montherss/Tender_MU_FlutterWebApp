import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../../features/tenders/domain/tender_domain.dart';
import 'app_utils.dart';

/// Builds Excel workbooks that mirror the PDF reports in [TenderPdfGenerator].
///
/// Used as a fallback when a report is too large for the `pdf` package to
/// paginate (see [TooManyPagesException]) — the same data is still delivered
/// to the user, just as a spreadsheet instead of a print-ready PDF. Unlike
/// the plain `excel` package, `syncfusion_flutter_xlsio` supports print page
/// setup (landscape + fit-to-one-page-wide) and embedding the university
/// logo, matching the PDF reports' print layout.
class TenderExcelGenerator {
  const TenderExcelGenerator._();

  static Future<List<int>> itemsExcel(TenderDetails tender) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    final styles = _ExcelStyles(workbook);
    sheet.isRightToLeft = true;
    final logoBytes = await _loadLogoBytes();

    const headers = ['#', 'رقم المادة', 'الوصف', 'الكمية', 'الوحدة'];
    var row = await _writeReportHeader(
      sheet,
      styles,
      title: 'كشف مواد وتفاصيل العطاء',
      subtitle: _tenderInfoLine(tender),
      columnCount: headers.length,
      logoBytes: logoBytes,
    );
    row = _writeHeaderRow(sheet, styles, headers, row);

    final sortedItems = _sortedTenderItems(tender.items);
    for (final entry in sortedItems.asMap().entries) {
      final item = entry.value;
      _writeRow(sheet, styles, row, [
        _text('${entry.key + 1}'),
        _text(item.itemNo ?? '-'),
        _text(item.description ?? '-'),
        _num(item.quantity),
        _text(item.unit ?? '-'),
      ]);
      row++;
      await _maybeYield(entry.key);
    }

    row++;
    _writeRow(sheet, styles, row, [
      _text('عدد المواد: ${tender.items.length}', style: styles.bold),
    ]);

    _finishSheet(sheet, headers.length);
    return _save(workbook);
  }

  /// Each material gets its own worksheet (so it always starts on a fresh
  /// printed page — a material whose offers overflow one page simply
  /// continues onto the next, but the *next* material always begins on a
  /// brand-new page rather than sharing a page with the previous one).
  static Future<List<int>> supplierItemOffersExcel(
    TenderDetails tender,
    List<SupplierItemOffer> offers,
  ) async {
    final workbook = Workbook(0);
    final styles = _ExcelStyles(workbook);
    final logoBytes = await _loadLogoBytes();

    const headers = [
      '#',
      'المورد',
      'الوصف',
      'بلد المنشأ',
      'نوع العرض',
      'الوحدة',
      'الكمية',
      'سعر الوحدة',
      'السعر الإجمالي',
      'ملاحظة',
    ];

    final offersByItem = <int, List<SupplierItemOffer>>{};
    for (final offer in offers) {
      offersByItem.putIfAbsent(offer.itemId, () => []).add(offer);
    }

    final sortedItems = _sortedTenderItems(tender.items);
    final validItems = sortedItems.where((item) => item.id != null).toList();
    final validItemIds = validItems.map((item) => item.id!).toSet();
    final orphanEntries =
        offersByItem.entries
            .where((entry) => !validItemIds.contains(entry.key))
            .toList()
          ..sort((a, b) {
            final aNo = num.tryParse(a.value.first.itemNo?.trim() ?? '');
            final bNo = num.tryParse(b.value.first.itemNo?.trim() ?? '');
            if (aNo != null && bNo != null) return aNo.compareTo(bNo);
            return 0;
          });
    final pageTotal = validItems.length + orphanEntries.length;

    var itemIndex = 0;

    for (final item in validItems) {
      itemIndex++;
      await _writeItemSheet(
        workbook,
        styles,
        logoBytes: logoBytes,
        tender: tender,
        headers: headers,
        itemIndex: itemIndex,
        pageIndex: itemIndex,
        pageTotal: pageTotal,
        itemNo: item.itemNo,
        description: item.description,
        quantity: item.quantity,
        unit: item.unit,
        offers: offersByItem[item.id] ?? const [],
      );
      await _maybeYield(itemIndex);
    }

    for (final entry in orphanEntries) {
      itemIndex++;
      final sample = entry.value.first;
      await _writeItemSheet(
        workbook,
        styles,
        logoBytes: logoBytes,
        tender: tender,
        headers: headers,
        itemIndex: itemIndex,
        pageIndex: itemIndex,
        pageTotal: pageTotal,
        itemNo: sample.itemNo,
        description: sample.description,
        quantity: sample.quantity,
        unit: sample.unit,
        offers: entry.value,
      );
      await _maybeYield(itemIndex);
    }

    final itemIds = tender.items
        .map((item) => item.id)
        .whereType<int>()
        .toSet();
    for (final offer in offers) {
      itemIds.add(offer.itemId);
    }
    final supplierIds = offers.map((offer) => offer.supplierId).toSet();

    final summarySheet = workbook.worksheets.addWithName('ملخص');
    summarySheet.isRightToLeft = true;
    var summaryRow = await _writeReportHeader(
      summarySheet,
      styles,
      title: 'كشف عروض الأسعار',
      subtitle: _tenderInfoLine(tender),
      columnCount: headers.length,
      logoBytes: logoBytes,
      pageLabel: 'صفحة ${pageTotal + 1} من ${pageTotal + 1} — الملخص',
    );
    _writeRow(summarySheet, styles, summaryRow, [
      _text(
        'عدد المواد: ${itemIds.length} | عدد الموردين: ${supplierIds.length} | عدد العروض: ${offers.length}',
        style: styles.bold,
      ),
    ]);
    _finishSheet(summarySheet, headers.length);

    return _save(workbook);
  }

  static Future<void> _writeItemSheet(
    Workbook workbook,
    _ExcelStyles styles, {
    required List<int>? logoBytes,
    required TenderDetails tender,
    required List<String> headers,
    required int itemIndex,
    required int pageIndex,
    required int pageTotal,
    required String? itemNo,
    required String? description,
    required num? quantity,
    required String? unit,
    required List<SupplierItemOffer> offers,
  }) async {
    final sheet = workbook.worksheets.addWithName(
      _itemSheetName(itemIndex, itemNo),
    );
    sheet.isRightToLeft = true;

    var row = await _writeReportHeader(
      sheet,
      styles,
      title: 'كشف عروض الأسعار',
      subtitle: _tenderInfoLine(tender),
      columnCount: headers.length,
      logoBytes: logoBytes,
      pageLabel: 'صفحة $pageIndex من $pageTotal',
    );

    _writeMergedRow(
      sheet,
      row,
      'مادة $itemIndex — رقم ${itemNo ?? '-'} — ${description ?? '-'} — الكمية ${quantity ?? '-'} ${unit ?? ''}',
      columnCount: headers.length,
      style: styles.section,
    );
    row++;
    row = _writeHeaderRow(sheet, styles, headers, row);

    final supplierGroups = _groupOffersBySupplier(offers);
    if (supplierGroups.isEmpty) {
      _writeMergedRow(
        sheet,
        row,
        'لا توجد عروض مسجلة لهذه المادة.',
        columnCount: headers.length,
        style: styles.normal,
      );
      _finishSheet(sheet, headers.length);
      return;
    }

    final primaryOffers = supplierGroups.map(_primaryOffer).toList();
    final lowestPriceOfferId = _lowestPriceOfferId(primaryOffers);

    for (final entry in supplierGroups.asMap().entries) {
      final groupOffers = entry.value;
      final primary = _primaryOffer(groupOffers);
      final alternatives = groupOffers
          .where((offer) => offer.id != primary.id && offer.hasAlternative)
          .toList();
      final extraPrimaries = groupOffers
          .where((offer) => offer.id != primary.id && !offer.hasAlternative)
          .toList();
      final orderedOffers = [primary, ...extraPrimaries, ...alternatives];

      for (final offerEntry in orderedOffers.asMap().entries) {
        final offer = offerEntry.value;
        final isLowest = offer.id == lowestPriceOfferId;
        final totalPrice = offer.price ?? _calculatedTotalPrice(offer);
        final unitPrice = offer.unitPrice ?? _calculatedUnitPrice(offer);
        _writeRow(sheet, styles, row, [
          _text('${entry.key + 1}.${offerEntry.key + 1}'),
          _text(offer.supplierName ?? primary.supplierName ?? '-'),
          _text(
            offer.hasAlternative
                ? offer.alternativeDescription ?? offer.description ?? '-'
                : offer.description ?? '-',
          ),
          _text(offer.origin ?? '-'),
          _text(
            offer.id == primary.id
                ? 'أساسي'
                : offer.hasAlternative
                ? 'بديل'
                : 'إضافي',
          ),
          _text(offer.unit ?? '-'),
          _num(offer.quantity),
          _num(unitPrice),
          _num(totalPrice, style: isLowest ? styles.lowestPrice : null),
          _text(offer.note ?? '-'),
        ]);
        row++;
      }
    }

    _finishSheet(sheet, headers.length);
  }

  static Future<List<int>> itemAssignmentsExcel(
    TenderDetails tender,
    List<Supplier> suppliers,
    List<ItemAssignment> assignments,
  ) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    final styles = _ExcelStyles(workbook);
    sheet.isRightToLeft = true;

    const headers = [
      '#',
      'المورد',
      'المادة المحالة',
      'تفاصيل الإحالة',
      'بلد المنشأ',
      'الوحدة',
      'الكمية',
      'سعر الوحدة',
      'السعر الحالي',
    ];

    final logoBytes = await _loadLogoBytes();
    var row = await _writeReportHeader(
      sheet,
      styles,
      title: 'كشف إحالة العطاء',
      subtitle: _tenderInfoLine(tender),
      columnCount: headers.length,
      logoBytes: logoBytes,
    );
    row = _writeHeaderRow(sheet, styles, headers, row);

    final supplierNames = <String>[];
    for (final supplier in suppliers) {
      if (!supplierNames.contains(supplier.displayName)) {
        supplierNames.add(supplier.displayName);
      }
    }
    for (final assignment in assignments) {
      final name = assignment.supplierName?.trim();
      if (name != null && name.isNotEmpty && !supplierNames.contains(name)) {
        supplierNames.add(name);
      }
    }

    if (supplierNames.isEmpty) {
      _writeMergedRow(
        sheet,
        row,
        'لا يوجد موردون مرتبطون بهذا العطاء.',
        columnCount: headers.length,
        style: styles.normal,
      );
      row++;
    }

    for (final entry in supplierNames.asMap().entries) {
      final supplierName = entry.value;
      final supplierAssignments = assignments
          .where((assignment) => assignment.supplierName == supplierName)
          .toList();

      if (supplierAssignments.isEmpty) {
        _writeRow(sheet, styles, row, [
          _text('${entry.key + 1}'),
          _text(supplierName),
          _text('لم يتم إحالة مواد عليه'),
          _text('-'),
          _text('-'),
          _text('-'),
          _text('-'),
          _text('-'),
          _text('-'),
        ]);
        row++;
        continue;
      }

      for (final assignmentEntry in supplierAssignments.asMap().entries) {
        final assignment = assignmentEntry.value;
        final item = _tenderItemFor(tender, assignment.tenderItemId);
        final itemIndex = tender.items.indexWhere(
          (tenderItem) => tenderItem.id == assignment.tenderItemId,
        );
        final quantity = assignment.quantity ?? item?.quantity;
        final unit = assignment.unit?.trim().isNotEmpty ?? false
            ? assignment.unit
            : item?.unit;
        final unitPrice =
            assignment.unitPrice ??
            (assignment.price != null && quantity != null && quantity != 0
                ? assignment.price! / quantity
                : null);
        final type = assignment.isTechnical ? 'فنية' : 'رئيسية';
        final details = <String>['إحالة $type'];
        if (assignment.assignmentNote?.trim().isNotEmpty ?? false) {
          details.add('ملاحظة: ${assignment.assignmentNote!.trim()}');
        }
        if (assignment.offerNote?.trim().isNotEmpty ?? false) {
          details.add('عرض: ${assignment.offerNote!.trim()}');
        }
        if (assignment.hasAlternative) {
          details.add('بديل: ${assignment.alternativeDescription ?? '-'}');
        }

        _writeRow(sheet, styles, row, [
          _text('${entry.key + 1}.${assignmentEntry.key + 1}'),
          _text(supplierName),
          _text(
            'مادة ${itemIndex == -1 ? '-' : itemIndex + 1} | رقم ${item?.itemNo ?? assignment.tenderItemId} | ${item?.description ?? '-'}',
          ),
          _text(details.join(' | ')),
          _text(assignment.origin ?? '-'),
          _text(unit ?? '-'),
          _num(quantity),
          _num(unitPrice),
          _num(assignment.price),
        ]);
        row++;
        await _maybeYield(row);
      }
    }

    _finishSheet(sheet, headers.length);
    return _save(workbook);
  }

  static Future<List<int>> companiesAssignmentExcel(
    TenderDetails tender,
    List<Supplier> suppliers,
    List<ItemAssignment> assignments,
  ) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    final styles = _ExcelStyles(workbook);
    sheet.isRightToLeft = true;

    const headers = [
      '#',
      'اسم الشركة',
      'رقم المادة',
      'الوصف',
      'الكمية',
      'الإجمالي للمادة',
      'عدد مواد الشركة',
      'إجمالي قيمة الشركة',
    ];

    final logoBytes = await _loadLogoBytes();
    var row = await _writeReportHeader(
      sheet,
      styles,
      title: 'كشف إحالة الشركات',
      subtitle: _tenderInfoLine(tender),
      columnCount: headers.length,
      logoBytes: logoBytes,
    );
    row = _writeHeaderRow(sheet, styles, headers, row);

    final supplierNames = <String>[];
    for (final supplier in suppliers) {
      if (!supplierNames.contains(supplier.displayName)) {
        supplierNames.add(supplier.displayName);
      }
    }
    for (final assignment in assignments) {
      final name = assignment.supplierName?.trim();
      if (name != null && name.isNotEmpty && !supplierNames.contains(name)) {
        supplierNames.add(name);
      }
    }
    final activeSupplierNames = supplierNames
        .where(
          (name) =>
              assignments.any((assignment) => assignment.supplierName == name),
        )
        .toList();

    if (activeSupplierNames.isEmpty) {
      _writeMergedRow(
        sheet,
        row,
        'لا توجد مواد محالة على أي شركة بعد.',
        columnCount: headers.length,
        style: styles.normal,
      );
      row++;
    }

    num grandTotal = 0;
    var grandTotalHasValue = false;
    var grandItemCount = 0;

    for (final entry in activeSupplierNames.asMap().entries) {
      final supplierName = entry.value;
      final supplierAssignments = assignments
          .where((assignment) => assignment.supplierName == supplierName)
          .toList();

      num companyTotal = 0;
      var companyHasValue = false;
      for (final assignment in supplierAssignments) {
        if (assignment.price != null) {
          companyTotal += assignment.price!;
          companyHasValue = true;
        }
      }
      if (companyHasValue) {
        grandTotal += companyTotal;
        grandTotalHasValue = true;
      }
      grandItemCount += supplierAssignments.length;

      for (final assignmentEntry in supplierAssignments.asMap().entries) {
        final assignment = assignmentEntry.value;
        final item = _tenderItemFor(tender, assignment.tenderItemId);
        final itemNo = item?.itemNo ?? assignment.tenderItemId.toString();

        _writeRow(sheet, styles, row, [
          _text('${entry.key + 1}.${assignmentEntry.key + 1}'),
          _text(supplierName),
          _text(itemNo),
          _text(item?.description ?? '-'),
          _num(assignment.quantity ?? item?.quantity),
          _num(assignment.price),
          _num(supplierAssignments.length),
          _num(companyHasValue ? companyTotal : null),
        ]);
        row++;
        await _maybeYield(row);
      }
    }

    row++;
    _writeRow(sheet, styles, row, [
      _text('الإجمالي الكلي لجميع الشركات', style: styles.bold),
      _text(''),
      _text(''),
      _text(''),
      _text(''),
      _text(''),
      _num(grandItemCount, style: styles.bold),
      _num(grandTotalHasValue ? grandTotal : null, style: styles.bold),
    ]);

    _finishSheet(sheet, headers.length);
    return _save(workbook);
  }

  static TenderItem? _tenderItemFor(TenderDetails tender, int tenderItemId) {
    final index = tender.items.indexWhere((item) => item.id == tenderItemId);
    return index == -1 ? null : tender.items[index];
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

  static SupplierItemOffer _primaryOffer(List<SupplierItemOffer> offers) {
    return offers.firstWhere(
      (offer) => !offer.hasAlternative,
      orElse: () => offers.first,
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

  static String _tenderInfoLine(TenderDetails tender) {
    final subject = tender.subject ?? 'موضوع العطاء غير محدد';
    return 'رقم العطاء: ${tender.tenderNo ?? tender.id} | $subject | تاريخ الطباعة: ${AppDateFormatter.dateTime(DateTime.now())}';
  }

  /// Periodically hands control back to the event loop so building a very
  /// large workbook doesn't block the UI thread (and the browser tab) for
  /// one long uninterrupted stretch.
  static Future<void> _maybeYield(int index, {int every = 25}) async {
    if (index % every != 0) return;
    await Future<void>.delayed(Duration.zero);
  }

  /// Writes the university banner (with logo), report title and tender
  /// subtitle, and returns the row index the caller should continue from.
  static Future<int> _writeReportHeader(
    Worksheet sheet,
    _ExcelStyles styles, {
    required String title,
    required String subtitle,
    required int columnCount,
    required List<int>? logoBytes,
    String? pageLabel,
  }) async {
    _insertLogo(sheet, logoBytes);

    var row = 1;
    _writeMergedRow(
      sheet,
      row,
      pageLabel == null
          ? 'جامعة مؤتة - وحدة اللوازم'
          : 'جامعة مؤتة - وحدة اللوازم — $pageLabel',
      columnCount: columnCount,
      style: styles.banner,
    );
    sheet.getRangeByIndex(row, 1).rowHeight = 34;
    row++;

    _writeMergedRow(
      sheet,
      row,
      title,
      columnCount: columnCount,
      style: styles.title,
    );
    row++;

    _writeMergedRow(
      sheet,
      row,
      subtitle,
      columnCount: columnCount,
      style: styles.subtitle,
    );
    row += 2;
    return row;
  }

  /// Loads the university logo once so it can be embedded into every sheet
  /// without re-reading the asset from disk each time. Returns `null` if the
  /// asset can't be loaded — the logo is optional.
  static Future<List<int>?> _loadLogoBytes() async {
    try {
      final data = await rootBundle.load('assets/image/mu_logo.jpg');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static void _insertLogo(Worksheet sheet, List<int>? logoBytes) {
    if (logoBytes == null || logoBytes.isEmpty) return;
    final picture = sheet.pictures.addStream(1, 1, logoBytes);
    picture.height = 46;
    picture.width = 46;
  }

  /// Sorts a copy of [items] numerically by item number, since the source
  /// list order doesn't reliably match ascending item numbers.
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

  /// Builds a valid, unique Excel worksheet name (max 31 chars, no
  /// `: \ / ? * [ ]`) for a material's sheet.
  static String _itemSheetName(int index, String? itemNo) {
    final label = itemNo != null && itemNo.trim().isNotEmpty
        ? 'مادة $index - ${itemNo.trim()}'
        : 'مادة $index';
    final sanitized = label.replaceAll(RegExp(r'[:\\/?*\[\]]'), '-');
    return sanitized.length > 31 ? sanitized.substring(0, 31) : sanitized;
  }

  static void _writeMergedRow(
    Worksheet sheet,
    int row,
    String text, {
    required int columnCount,
    required Style style,
  }) {
    sheet.getRangeByIndex(row, 1).text = text;
    final fullRange = sheet.getRangeByIndex(row, 1, row, columnCount);
    fullRange.cellStyle = style;
    fullRange.merge();
  }

  static int _writeHeaderRow(
    Worksheet sheet,
    _ExcelStyles styles,
    List<String> headers,
    int row,
  ) {
    _writeRow(
      sheet,
      styles,
      row,
      headers.map((header) => _text(header, style: styles.header)).toList(),
    );
    return row + 1;
  }

  static void _writeRow(
    Worksheet sheet,
    _ExcelStyles styles,
    int row,
    List<_ExcelCell> cells,
  ) {
    for (final entry in cells.asMap().entries) {
      final range = sheet.getRangeByIndex(row, entry.key + 1);
      final cell = entry.value;
      if (cell.numberValue != null) {
        range.number = cell.numberValue;
      } else {
        range.text = cell.textValue ?? '-';
      }
      range.cellStyle = cell.style ?? styles.normal;
    }
  }

  static _ExcelCell _text(String value, {Style? style}) {
    return _ExcelCell(textValue: value, style: style);
  }

  static _ExcelCell _num(num? value, {Style? style}) {
    if (value == null) return _ExcelCell(textValue: '-', style: style);
    return _ExcelCell(numberValue: value.toDouble(), style: style);
  }

  static void _finishSheet(Worksheet sheet, int columnCount) {
    sheet.pageSetup
      ..orientation = ExcelPageOrientation.portrait
      ..isFitToPage = true
      ..fitToPagesWide = 1
      ..fitToPagesTall = 0
      ..paperSize = ExcelPaperSize.paperA4;
    for (var i = 1; i <= columnCount; i++) {
      sheet.autoFitColumn(i);
    }
  }

  static List<int> _save(Workbook workbook) {
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }
}

class _ExcelCell {
  const _ExcelCell({this.textValue, this.numberValue, this.style});

  final String? textValue;
  final double? numberValue;
  final Style? style;
}

class _ExcelStyles {
  factory _ExcelStyles(Workbook workbook) {
    return _ExcelStyles._(
      normal: _build(workbook, 'normal', (s) {
        s.hAlign = HAlignType.right;
        s.vAlign = VAlignType.center;
        s.wrapText = true;
        s.borders.all.lineStyle = LineStyle.thin;
      }),
      header: _build(workbook, 'header', (s) {
        s.bold = true;
        s.hAlign = HAlignType.center;
        s.vAlign = VAlignType.center;
        s.wrapText = true;
        s.backColor = '#E0E0E0';
        s.borders.all.lineStyle = LineStyle.thin;
      }),
      banner: _build(workbook, 'banner', (s) {
        s.bold = true;
        s.fontSize = 13;
        s.hAlign = HAlignType.center;
        s.vAlign = VAlignType.center;
        s.borders.bottom.lineStyle = LineStyle.medium;
      }),
      title: _build(workbook, 'title', (s) {
        s.bold = true;
        s.fontSize = 14;
        s.hAlign = HAlignType.center;
        s.vAlign = VAlignType.center;
        s.backColor = '#37474F';
        s.fontColor = '#FFFFFF';
      }),
      subtitle: _build(workbook, 'subtitle', (s) {
        s.bold = true;
        s.hAlign = HAlignType.center;
        s.vAlign = VAlignType.center;
        s.backColor = '#F5F5F5';
      }),
      section: _build(workbook, 'section', (s) {
        s.bold = true;
        s.hAlign = HAlignType.right;
        s.vAlign = VAlignType.center;
        s.wrapText = true;
        s.backColor = '#FFECB3';
        s.borders.all.lineStyle = LineStyle.thin;
      }),
      bold: _build(workbook, 'bold', (s) {
        s.bold = true;
        s.hAlign = HAlignType.right;
        s.vAlign = VAlignType.center;
      }),
      lowestPrice: _build(workbook, 'lowestPrice', (s) {
        s.bold = true;
        s.hAlign = HAlignType.center;
        s.vAlign = VAlignType.center;
        s.backColor = '#000000';
        s.fontColor = '#FFFFFF';
        s.borders.all.lineStyle = LineStyle.thin;
      }),
    );
  }

  const _ExcelStyles._({
    required this.normal,
    required this.header,
    required this.banner,
    required this.title,
    required this.subtitle,
    required this.section,
    required this.bold,
    required this.lowestPrice,
  });

  final Style normal;
  final Style header;
  final Style banner;
  final Style title;
  final Style subtitle;
  final Style section;
  final Style bold;
  final Style lowestPrice;

  static Style _build(
    Workbook workbook,
    String name,
    void Function(Style style) configure,
  ) {
    final style = workbook.styles.add(name);
    configure(style);
    return style;
  }
}
