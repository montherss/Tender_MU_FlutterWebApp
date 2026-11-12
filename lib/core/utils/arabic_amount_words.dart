/// Spells a Jordanian Dinar amount in Arabic words, e.g. 2973.7 →
/// "ألفان وتسعمائة وثلاثة وسبعون دينار و 700 فلس".
String arabicDinarAmountInWords(num amount) {
  final totalFils = (amount.abs() * 1000).round();
  final dinars = totalFils ~/ 1000;
  final fils = totalFils % 1000;
  if (dinars == 0 && fils == 0) return 'صفر دينار';
  final parts = <String>[];
  if (dinars > 0) parts.add('${arabicNumberInWords(dinars)} دينار');
  if (fils > 0) parts.add('$fils فلس');
  return parts.join(' و ');
}

/// Spells a non-negative integer (up to the billions) in Arabic words.
String arabicNumberInWords(int number) {
  if (number == 0) return 'صفر';
  const scales = [
    (1000000000, 'مليار', 'ملياران', 'مليارات'),
    (1000000, 'مليون', 'مليونان', 'ملايين'),
    (1000, 'ألف', 'ألفان', 'آلاف'),
  ];
  final parts = <String>[];
  var rest = number;
  for (final (value, single, dual, plural) in scales) {
    final count = rest ~/ value;
    rest %= value;
    if (count == 0) continue;
    if (count == 1) {
      parts.add(single);
    } else if (count == 2) {
      parts.add(dual);
    } else if (count <= 10) {
      parts.add('${_belowThousand(count)} $plural');
    } else {
      parts.add('${_belowThousand(count)} $single');
    }
  }
  if (rest > 0) parts.add(_belowThousand(rest));
  return parts.join(' و');
}

const _ones = [
  '',
  'واحد',
  'اثنان',
  'ثلاثة',
  'أربعة',
  'خمسة',
  'ستة',
  'سبعة',
  'ثمانية',
  'تسعة',
];

const _teens = [
  'عشرة',
  'أحد عشر',
  'اثنا عشر',
  'ثلاثة عشر',
  'أربعة عشر',
  'خمسة عشر',
  'ستة عشر',
  'سبعة عشر',
  'ثمانية عشر',
  'تسعة عشر',
];

const _tens = [
  '',
  '',
  'عشرون',
  'ثلاثون',
  'أربعون',
  'خمسون',
  'ستون',
  'سبعون',
  'ثمانون',
  'تسعون',
];

const _hundreds = [
  '',
  'مائة',
  'مئتان',
  'ثلاثمائة',
  'أربعمائة',
  'خمسمائة',
  'ستمائة',
  'سبعمائة',
  'ثمانمائة',
  'تسعمائة',
];

String _belowThousand(int number) {
  final parts = <String>[];
  final hundreds = number ~/ 100;
  final rest = number % 100;
  if (hundreds > 0) parts.add(_hundreds[hundreds]);
  if (rest >= 20) {
    final ones = rest % 10;
    parts.add(
      ones == 0 ? _tens[rest ~/ 10] : '${_ones[ones]} و${_tens[rest ~/ 10]}',
    );
  } else if (rest >= 10) {
    parts.add(_teens[rest - 10]);
  } else if (rest > 0) {
    parts.add(_ones[rest]);
  }
  return parts.join(' و');
}
