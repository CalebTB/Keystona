import 'task_dates.dart';

/// Parsing and masking for the Log screen's text fields. Pure Dart.
abstract final class TaskLogInput {
  static final RegExp _dateRe = RegExp(
    r'^(\d{2})\s*/\s*(\d{2})\s*/\s*(\d{4})$',
  );
  static final RegExp _hoursRe = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)\b',
  );
  static final RegExp _minsRe = RegExp(
    r'(\d+)\s*(?:m|min|mins|minute|minutes)\b',
  );
  static final RegExp _plainRe = RegExp(r'^\d+$');

  static const int _minutesPerHour = 60;

  /// The largest value a SMALLINT minutes column holds.
  static const int maxMinutes = 32767;

  /// "10 / 02 / 2026" for [d].
  static String formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$m / $day / ${d.year.toString().padLeft(4, '0')}';
  }

  /// The date in "MM / DD / YYYY" text, or null when it is not a real date.
  static DateTime? parseDate(String text) {
    final m = _dateRe.firstMatch(text.trim());
    if (m == null) return null;
    final month = int.parse(m.group(1)!);
    final day = int.parse(m.group(2)!);
    final year = int.parse(m.group(3)!);
    final d = DateTime(year, month, day);
    // DateTime rolls 02/30 over to 03/02; reject anything that moved.
    if (d.year != year || d.month != month || d.day != day) return null;
    return d;
  }

  static const int _maxDateDigits = 8;

  /// [text] reshaped as the user types digits: "1002" is "10 / 02".
  static String maskDate(String text) {
    var digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxDateDigits) {
      digits = digits.substring(0, _maxDateDigits);
    }
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write(' / ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// True when [d] is after today.
  static bool isFuture(DateTime d, DateTime today) =>
      TaskDates.daysBetween(today, d) > 0;

  /// Minutes from "1 hr 10 min", "90", "45 min" or "1.5 hr". Null when empty
  /// or not understood.
  static int? parseMinutes(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return null;
    int? total;
    if (_plainRe.hasMatch(t)) {
      total = int.parse(t);
    } else {
      final h = _hoursRe.firstMatch(t);
      final m = _minsRe.firstMatch(t);
      if (h == null && m == null) return null;
      final hours = h == null ? 0.0 : double.parse(h.group(1)!);
      final mins = m == null ? 0 : int.parse(m.group(1)!);
      total = (hours * _minutesPerHour).round() + mins;
    }
    return total > maxMinutes ? null : total;
  }

  /// Dollars from "$129", "129.50" or "". Never negative; 0 when empty.
  static double parseMoney(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
