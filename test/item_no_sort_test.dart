import 'package:flutter_test/flutter_test.dart';
import 'package:tender_mu_system/features/tenders/domain/tender_domain.dart';

void main() {
  test('item numbers sort ascending in natural order', () {
    final input = ['10', '2', '', '1.10', '1.2', '1', 'B3', null, '3a', '3'];
    final sorted = [...input]..sort(compareItemNo);
    expect(sorted, ['1', '1.2', '1.10', '2', '3', '3a', '10', 'B3', '', null]);
  });
}
