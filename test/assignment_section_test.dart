import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tender_mu_system/core/theme/app_theme.dart';
import 'package:tender_mu_system/features/tenders/domain/tender_domain.dart';
import 'package:tender_mu_system/features/tenders/presentation/cubit/tenders_cubit.dart';
import 'package:tender_mu_system/features/tenders/presentation/widgets/tender_sections.dart';

class _PendingRepository implements TenderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Completer<Never>().future;
}

SupplierItemOffer _offer(
  int id,
  int supplierId,
  int itemId,
  num price, {
  int alt = 0,
}) => SupplierItemOffer(
  id: id,
  supplierId: supplierId,
  itemId: itemId,
  supplierName: 'شركة $supplierId',
  itemNo: '$itemId',
  description: 'مادة $itemId',
  price: price,
  unitPrice: price / 2,
  origin: 'الأردن',
  note: 'ملاحظة على العرض',
  isAlternative: alt,
  alternativeDescription: alt == 1 ? 'بديل' : null,
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  bool bySupplier = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = TenderDetailsState(
    tender: const TenderDetails(
      id: 1,
      items: [
        TenderItem(
          id: 10,
          itemNo: '10',
          description: 'مادة عشرة',
          quantity: 5,
          unit: 'قطعة',
        ),
        TenderItem(
          id: 2,
          itemNo: '2',
          description: 'مادة اثنان',
          quantity: 3,
          unit: 'علبة',
        ),
        TenderItem(
          id: 1,
          itemNo: '1',
          description: 'مادة واحد',
          quantity: 1,
          unit: 'قطعة',
        ),
      ],
    ),
    supplierItemOffers: [
      _offer(1, 100, 1, 50),
      _offer(2, 200, 1, 40),
      _offer(3, 200, 1, 35, alt: 1),
      _offer(4, 100, 2, 70),
      _offer(5, 300, 10, 90),
    ],
    itemAssignments: const [
      ItemAssignment(
        assignmentId: 1,
        tenderId: 1,
        supplierItemOfferId: 2,
        tenderItemId: 1,
        supplierName: 'شركة 200',
        assignedPrice: 40,
        assignmentType: 'MAIN',
        assignmentNote: 'ملاحظة',
      ),
    ],
  );
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(1440, 1024),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider(
            create: (_) => TenderDetailsCubit(_PendingRepository()),
            child: Scaffold(
              body: SingleChildScrollView(
                child: TenderItemAssignmentSection(state: state),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (bySupplier) {
    await tester.tap(find.text('حسب الشركة'));
    await tester.pump();
  }
}

void main() {
  for (final size in [const Size(1400, 900), const Size(500, 900)]) {
    testWidgets('renders by item at $size', (tester) async {
      await _pump(tester, size);
      expect(tester.takeException(), isNull);
    });
    testWidgets('renders by supplier at $size', (tester) async {
      await _pump(tester, size, bySupplier: true);
      expect(tester.takeException(), isNull);
    });
  }
}
