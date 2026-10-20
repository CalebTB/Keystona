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
    this.replacedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? categoryName;

  /// Key into `CategoryIcons`.
  final String? categoryIcon;
  final DateTime? expirationDate;

  /// When a newer copy replaced this document; null when it has not been.
  final DateTime? replacedAt;

  bool get isReplaced => replacedAt != null;

  /// The end date that still counts: none once the document is replaced.
  DateTime? get activeExpiration => isReplaced ? null : expirationDate;
}

/// Everything the Docs tab shows, loaded in one go.
class DocsTabData {
  const DocsTabData({
    this.totalCount = 0,
    this.recent = const [],
    this.expiring = const [],
    this.emptyCategoryNames = const [],
  });

  /// Documents in the vault (drives "12 OF 25" and "See all 12").
  final int totalCount;

  /// The newest documents, newest first.
  final List<DocsTabItem> recent;

  /// Every document with an expiration date, soonest first. Replaced
  /// documents are included; use [active] for what is still in force.
  final List<DocsTabItem> expiring;

  /// Standard categories with no documents, in display order.
  final List<String> emptyCategoryNames;

  bool get isEmpty => totalCount == 0;

  /// Documents with an expiration date that has not been replaced, soonest
  /// first. Drives every expiring count and list on the tab.
  List<DocsTabItem> get active =>
      expiring.where((d) => !d.isReplaced).toList();

  /// Documents that expire within the soon window, soonest first.
  List<DocsTabItem> soon({DateTime? now}) => active
      .where((d) => DocsExpiry.of(d.expirationDate!, now: now).isSoon)
      .toList();

  /// Documents that need action now (30 days or fewer, or already expired).
  List<DocsTabItem> urgent({DateTime? now}) => active
      .where(
        (d) =>
            DocsExpiry.of(d.expirationDate!, now: now).tone ==
            DocsExpiryTone.urgent,
      )
      .toList();
}
