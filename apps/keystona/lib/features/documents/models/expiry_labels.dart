/// Words for a day count: the chip on a card and the "time left" line.
///
/// Urgency itself (the tone) comes from `DocsExpiry`; this only phrases it.
abstract final class ExpiryLabels {
  /// Reminder lead time shown on the detail screen and the Expiring footer.
  static const int reminderLeadDays = 30;

  /// Day counts below this read as "N DAYS"; above it as months.
  static const int _daysBeforeMonths = 60;

  /// Days per month and per year when turning a count into larger units.
  static const int _daysPerMonth = 30;
  static const int _daysPerYear = 365;

  /// Uppercase chip text: "TODAY", "8 DAYS", "2 MONTHS", "3 YEARS",
  /// "EXPIRED".
  static String chip(int days) {
    if (days < 0) return 'EXPIRED';
    if (days == 0) return 'TODAY';
    if (days < _daysBeforeMonths) return days == 1 ? '1 DAY' : '$days DAYS';
    if (days < _daysPerYear) return '${(days / _daysPerMonth).round()} MONTHS';
    final years = (days / _daysPerYear).round();
    return years == 1 ? '1 YEAR' : '$years YEARS';
  }

  /// "4 YRS 5 MOS LEFT", "45 DAYS LEFT", "EXPIRES TODAY", "EXPIRED".
  static String remaining(int days) {
    if (days < 0) return 'EXPIRED';
    if (days == 0) return 'EXPIRES TODAY';
    if (days < _daysPerYear) return days == 1 ? '1 DAY LEFT' : '$days DAYS LEFT';
    final years = days ~/ _daysPerYear;
    final months = (days % _daysPerYear) ~/ _daysPerMonth;
    final y = '$years ${years == 1 ? 'YR' : 'YRS'}';
    if (months == 0) return '$y LEFT';
    return '$y $months ${months == 1 ? 'MO' : 'MOS'} LEFT';
  }
}
