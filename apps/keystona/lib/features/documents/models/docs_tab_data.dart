import 'docs_expiry.dart';

/// The few fields the Docs tab needs from a document.
class DocsTabItem {
  const DocsTabItem({
    required this.id,
    required this.name,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.expirationDate,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? categoryName;

  /// Key into `CategoryIcons`.
  final String? categoryIcon;
  final DateTime? expirationDate;
}

/// Everything the Docs tab shows, loaded in one go.
class DocsTabData {
  const DocsTabData({
    this.totalCount = 0,
    this.recent = const [],
    this.expiring = const [],
    this.emptyCategoryNames = const [],
  });

  /// Documents in the vault (drives "12 OF 25", the limit gate and "See all
  /// 12").
  final int totalCount;

  /// The newest documents, newest first.
  final List<DocsTabItem> recent;

  /// Every document with an expiration date, soonest first.
  final List<DocsTabItem> expiring;

  /// Standard categories with no documents, in display order.
  final List<String> emptyCategoryNames;

  bool get isEmpty => totalCount == 0;

  /// Documents that expire within the soon window, soonest first.
  List<DocsTabItem> soon({DateTime? now}) => expiring
      .where((d) => DocsExpiry.of(d.expirationDate!, now: now).isSoon)
      .toList();

  /// Documents that need action now (30 days or fewer, or already expired).
  List<DocsTabItem> urgent({DateTime? now}) => expiring
      .where(
        (d) =>
            DocsExpiry.of(d.expirationDate!, now: now).tone ==
            DocsExpiryTone.urgent,
      )
      .toList();
}
