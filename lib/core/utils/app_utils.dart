import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static final _date = DateFormat('yyyy/MM/dd', 'ar');
  static final _dateTime = DateFormat('yyyy/MM/dd - HH:mm', 'ar');

  static String date(DateTime? value) => value == null ? '-' : _date.format(value);
  static String dateTime(DateTime? value) => value == null ? '-' : _dateTime.format(value);
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

num? parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? AppColors.danger : AppColors.deepBlue,
    ),
  );
}
