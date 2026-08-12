import 'package:intl/intl.dart';

/// Date formatting helpers using intl.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _displayDate = DateFormat.yMMMd();
  static final DateFormat _displayDateTime = DateFormat.yMMMd().add_jm();
  static final DateFormat _shortDate = DateFormat.MMMd();
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _chartDay = DateFormat.E();

  static String formatDate(DateTime date) =>
      _displayDate.format(date.toLocal());

  static String formatDateTime(DateTime date) =>
      _displayDateTime.format(date.toLocal());

  static String formatShortDate(DateTime date) =>
      _shortDate.format(date.toLocal());

  static String formatIsoDate(DateTime date) => _isoDate.format(date.toLocal());

  static String formatChartDay(DateTime date) =>
      _chartDay.format(date.toLocal());

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int ageFromDob(DateTime dateOfBirth, [DateTime? asOf]) {
    final now = asOf ?? DateTime.now();
    var age = now.year - dateOfBirth.year;
    final hadBirthday = now.month > dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    if (!hadBirthday) age--;
    return age;
  }

  static List<DateTime> lastNDays(int n, [DateTime? from]) {
    final end = startOfDay(from ?? DateTime.now());
    return List.generate(n, (i) => end.subtract(Duration(days: n - 1 - i)));
  }
}
