/// How urgent a document's expiration date is.
enum DocsExpiryTone {
  /// Expired, or 30 days or fewer remain (coral).
  urgent,

  /// 31 to 90 days remain (amber).
  soon,

  /// More than 90 days remain (neutral).
  far,
}

/// Pure expiry maths shared by the Docs tab, [ExpirationBadge] and the cards.
class DocsExpiry {
  const DocsExpiry._(this.days, this.tone, this.date);

  /// Days at or under which a document counts as urgent.
  static const int urgentDays = 30;

  /// Days at or under which a document counts as expiring soon.
  static const int soonDays = 90;

  /// Whole calendar days from today to [date]; negative once expired.
  final int days;
  final DocsExpiryTone tone;
  final DateTime date;

  /// Classifies [date] against [now] (defaults to the current time). Only the
  /// calendar date counts, so a document is not "0 days" all afternoon.
  factory DocsExpiry.of(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final days = _dateOnly(date).difference(today).inDays;
    final tone = days <= urgentDays
        ? DocsExpiryTone.urgent
        : days <= soonDays
        ? DocsExpiryTone.soon
        : DocsExpiryTone.far;
    return DocsExpiry._(days, tone, date);
  }

  bool get expired => days < 0;
  bool get isToday => days == 0;

  /// True when it belongs in the "expiring soon" list.
  bool get isSoon => tone != DocsExpiryTone.far;

  /// Midnight UTC of [d]'s calendar date, so a daylight-saving change between
  /// two dates never turns 45 days into 44.
  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
