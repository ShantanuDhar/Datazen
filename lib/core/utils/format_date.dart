import 'package:intl/intl.dart';

String formatDateMMYYYY(DateTime date) {
  return DateFormat('d MMMM, yyyy').format(date);
}

String formatDateYYYYMMDD(DateTime date) {
  DateTime yesterday = date.subtract(Duration(days: 1));
  print(DateFormat('yyyy-MM-dd').format(yesterday));
  return DateFormat('yyyy-MM-dd').format(yesterday);
}
