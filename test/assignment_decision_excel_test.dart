import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tender_mu_system/core/utils/arabic_amount_words.dart';
import 'package:tender_mu_system/core/utils/excel_generator.dart';
import 'package:tender_mu_system/features/tenders/domain/tender_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('spells dinar amounts in Arabic', () {
    expect(
      arabicDinarAmountInWords(2973.7),
      'ألفان وتسعمائة وثلاثة وسبعون دينار و 700 فلس',
    );
    expect(arabicDinarAmountInWords(15), 'خمسة عشر دينار');
    expect(arabicDinarAmountInWords(0.25), '250 فلس');
    expect(arabicNumberInWords(13500), 'ثلاثة عشر ألف وخمسمائة');
    expect(arabicNumberInWords(3001), 'ثلاثة آلاف وواحد');
  });

  test('builds the decision workbook with every description filled', () async {
    const itemNos = ['34', '1', '17', '9/1', '2', '33', '3', '8', '18/1',
        '19/1', '20/1', '28', '31'];
    final items = [
      for (var i = 0; i < itemNos.length; i++)
        TenderItem(
          id: i + 1,
          itemNo: itemNos[i],
          // Item "2" has a blank description and "8" the literal "null".
          description: switch (itemNos[i]) {
            '2' => '  ',
            '8' => 'null',
            _ => 'Item ${itemNos[i]} description',
          },
          quantity: 1,
          unit: 'ea',
        ),
    ];
    final tender = TenderDetails(
      id: 1,
      tenderNo: '70 / ل ف / 2024',
      subject: 'توريد وتركيب وتشغيل أجهزة ومواد مخبرية/ كلية العلوم',
      items: items,
    );
    final offers = [
      for (final item in items)
        SupplierItemOffer(
          id: item.id!,
          supplierId: 7,
          itemId: item.id!,
          itemNo: item.itemNo,
          description: 'Offer ${item.itemNo} description',
          price: 100,
        ),
      // Offer for an item that isn't in the tender's item list.
      const SupplierItemOffer(
        id: 500,
        supplierId: 8,
        itemId: 500,
        itemNo: '40',
        description: 'Orphan offer description',
        price: 55.5,
      ),
    ];
    final assignments = [
      for (final item in items)
        ItemAssignment(
          assignmentId: item.id!,
          tenderId: 1,
          supplierItemOfferId: item.id!,
          tenderItemId: item.id!,
          supplierName: 'شركة الوراثة للتكنولوجيا الحيوية',
          price: 100,
          assignedPrice: 100,
          unitPrice: 100,
          origin: 'USA',
          // Item "3" is an alternative with an empty alternative description.
          isAlternative: item.itemNo == '3' ? 1 : 0,
          alternativeDescription: item.itemNo == '3' ? '' : null,
        ),
      const ItemAssignment(
        assignmentId: 99,
        tenderId: 1,
        supplierItemOfferId: 500,
        tenderItemId: 0,
        supplierName: 'شركة ثانية',
        price: 55.5,
      ),
    ];
    final bytes = await TenderExcelGenerator.assignmentDecisionExcel(
      tender,
      const [],
      assignments,
      decisionNo: '5',
      decisionYear: '2025',
      deliveryPeriod: '7 - 90 يوم',
      offers: offers,
    );
    expect(bytes, isNotEmpty);
    final out = Platform.environment['DECISION_XLSX_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
