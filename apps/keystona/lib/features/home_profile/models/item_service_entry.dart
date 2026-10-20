import 'item_ref.dart';

/// What a history entry records. Matches the `kind` column of
/// `item_service_log`.
enum ServiceKind {
  installed('installed'),
  purchased('purchased'),
  service('service'),
  repair('repair');

  const ServiceKind(this.value);
  final String value;

  /// The kind stored as [value], or [service] for anything unknown.
  static ServiceKind fromValue(String? value) => ServiceKind.values.firstWhere(
    (k) => k.value == value,
    orElse: () => ServiceKind.service,
  );
}

/// The fields the user fills in to log a repair or service. No id yet: the
/// database assigns one.
class ItemServiceDraft {
  const ItemServiceDraft({
    required this.kind,
    required this.serviceDate,
    required this.title,
    this.provider,
    this.cost,
    this.note,
    this.underWarranty = false,
    this.documentId,
  });

  final ServiceKind kind;
  final DateTime serviceDate;
  final String title;

  /// Who did the work ("Summit Heating & Air", "Did it myself").
  final String? provider;

  /// Dollars.
  final double? cost;
  final String? note;
  final bool underWarranty;

  /// A document in Docs (receipt, service report).
  final String? documentId;
}

/// One row of an item's history (`item_service_log`).
class ItemServiceEntry {
  const ItemServiceEntry({
    required this.id,
    required this.item,
    required this.kind,
    required this.serviceDate,
    required this.title,
    this.provider,
    this.cost,
    this.note,
    this.underWarranty = false,
    this.documentId,
    this.createdAt,
  });

  /// Reads a row selected with [ItemServiceColumns.all].
  factory ItemServiceEntry.fromRow(Map<String, dynamic> row) {
    final systemId = row['system_id'] as String?;
    final applianceId = row['appliance_id'] as String?;
    return ItemServiceEntry(
      id: row['id'] as String,
      item: systemId != null
          ? ItemRef.system(systemId)
          : ItemRef.appliance(applianceId!),
      kind: ServiceKind.fromValue(row['kind'] as String?),
      serviceDate: DateTime.parse(row['service_date'] as String),
      title: row['title'] as String,
      provider: row['provider'] as String?,
      cost: (row['cost'] as num?)?.toDouble(),
      note: row['note'] as String?,
      underWarranty: row['under_warranty'] as bool? ?? false,
      documentId: row['document_id'] as String?,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'] as String),
    );
  }

  final String id;
  final ItemRef item;
  final ServiceKind kind;
  final DateTime serviceDate;
  final String title;
  final String? provider;
  final double? cost;
  final String? note;
  final bool underWarranty;
  final String? documentId;
  final DateTime? createdAt;

  /// The entry with the draft's fields, same id and item.
  ItemServiceEntry withDraft(ItemServiceDraft draft) => ItemServiceEntry(
    id: id,
    item: item,
    kind: draft.kind,
    serviceDate: draft.serviceDate,
    title: draft.title,
    provider: draft.provider,
    cost: draft.cost,
    note: draft.note,
    underWarranty: draft.underWarranty,
    documentId: draft.documentId,
    createdAt: createdAt,
  );

  /// Newest service date first; ties break on creation time, newest first.
  static int newestFirst(ItemServiceEntry a, ItemServiceEntry b) {
    final byDate = b.serviceDate.compareTo(a.serviceDate);
    if (byDate != 0) return byDate;
    final ca = a.createdAt;
    final cb = b.createdAt;
    if (ca == null || cb == null) return 0;
    return cb.compareTo(ca);
  }
}

/// Column list of `item_service_log`. Never `SELECT *`.
abstract final class ItemServiceColumns {
  static const String all =
      'id, property_id, user_id, system_id, appliance_id, kind, service_date, '
      'title, provider, cost, note, under_warranty, document_id, created_at, '
      'updated_at';
}
