import 'package:intl/intl.dart';

import '../../../documents/models/document_format.dart';
import '../../../maintenance/services/task_format.dart';
import '../../appliance_copy.dart';
import '../../models/appliance.dart';
import '../../models/appliance_dates.dart';
import '../../models/appliance_specs.dart';
import '../../models/item_document.dart';
import '../../models/item_service_entry.dart';
import '../shared/item_document_row.dart';
import '../shared/item_key_value.dart';
import '../shared/item_timeline_row.dart';

/// Turns an appliance and its related records into the rows the detail cards
/// show. Pure Dart, so the wording and the sums are tested directly.
abstract final class ApplianceDetailMapper {
  /// The PURCHASE card: price, retailer, purchase date and warranty. Only
  /// what is known.
  static List<ItemKeyValue> purchase(Appliance a) {
    final bought = a.purchasedOn;
    final ends = a.warrantyEndsOn;
    final provider = a.warrantyProvider?.trim();
    final hasProvider = provider != null && provider.isNotEmpty;
    final warranty = [
      if (hasProvider) provider,
      if (ends != null) 'ends ${DateFormat.yMMMd().format(ends)}',
    ].join(' · ');
    final retailer = a.retailer?.trim();
    return [
      if (a.purchasePrice != null)
        ItemKeyValue(
          label: ApplianceCopy.priceLabel,
          value: TaskFormat.money(a.purchasePrice!),
        ),
      if (retailer != null && retailer.isNotEmpty)
        ItemKeyValue(label: ApplianceCopy.fromLabel, value: retailer),
      if (bought != null)
        ItemKeyValue(
          label: ApplianceCopy.boughtLabel,
          value: DateFormat.yMMMd().format(bought),
        ),
      if (warranty.isNotEmpty)
        ItemKeyValue(label: ApplianceCopy.warrantyLabel, value: warranty),
    ];
  }

  /// The IDENTIFICATION card: brand, model, serial (with copy) and color.
  static List<ItemKeyValue> identification(Appliance a) {
    ItemKeyValue? row(String label, String? value, {bool copy = false}) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return null;
      return ItemKeyValue(label: label, value: v, copyable: copy);
    }

    return [
      ?row(ApplianceCopy.brand, a.brand),
      ?row(ApplianceCopy.model, a.modelNumber),
      ?row(ApplianceCopy.serialLabel, a.serialNumber, copy: true),
      ?row(ApplianceCopy.color, a.color),
    ];
  }

  /// The SPECIFICATIONS card.
  static List<ItemKeyValue> specifications(Appliance a) => [
    for (final e in ApplianceSpecs.fromJson(a.specifications).entries)
      ItemKeyValue(label: e.label, value: e.value),
  ];

  /// The HISTORY timeline, newest first: the service log plus a "Bought" row
  /// from the purchase date (unless the log already has one).
  static List<ItemTimelineRow> history(
    Appliance a,
    List<ItemServiceEntry> log,
  ) {
    final rows = <({DateTime date, ItemTimelineRow row})>[
      for (final e in log)
        (
          date: e.serviceDate,
          row: ItemTimelineRow(
            dateLabel: _month(e.serviceDate),
            title: e.title,
            subtitle: _subtitle(e),
            costLabel: e.cost == null ? null : TaskFormat.money(e.cost!),
            hollow:
                e.kind == ServiceKind.installed ||
                e.kind == ServiceKind.purchased,
          ),
        ),
    ];
    final bought = a.purchasedOn;
    final hasPurchased = log.any((e) => e.kind == ServiceKind.purchased);
    if (bought != null && !hasPurchased) {
      final retailer = a.retailer?.trim();
      rows.add((
        date: bought,
        row: ItemTimelineRow(
          dateLabel: _month(bought),
          title: ApplianceCopy.boughtEntry,
          subtitle: retailer == null || retailer.isEmpty ? null : retailer,
          costLabel: a.purchasePrice == null
              ? null
              : TaskFormat.money(a.purchasePrice!),
          hollow: true,
        ),
      ));
    }
    rows.sort((x, y) => y.date.compareTo(x.date));
    return [for (final r in rows) r.row];
  }

  /// "$883 SINCE 2023": every cost in the history, and the year of its first
  /// entry. Null when nothing cost anything.
  static String? historyTotal(Appliance a, List<ItemServiceEntry> log) {
    var total = 0.0;
    int? since;
    void note(DateTime d, double? cost) {
      since = since == null || d.year < since! ? d.year : since;
      total += cost ?? 0;
    }

    for (final e in log) {
      note(e.serviceDate, e.cost);
    }
    final bought = a.purchasedOn;
    if (bought != null && !log.any((e) => e.kind == ServiceKind.purchased)) {
      note(bought, a.purchasePrice);
    }
    if (total <= 0 || since == null) return null;
    return ApplianceCopy.historySince(total, since!);
  }

  static String _month(DateTime d) => DateFormat.yMMM().format(d).toUpperCase();

  static String? _subtitle(ItemServiceEntry e) {
    final parts = [
      if ((e.provider ?? '').trim().isNotEmpty) e.provider!.trim(),
      if (e.underWarranty) 'under warranty',
      if ((e.note ?? '').trim().isNotEmpty) e.note!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The DOCUMENTS card rows: "WARRANTY · PDF · 3 PAGES · ENDS DEC 9".
  static List<ItemDocumentRow> documents(List<ItemDocument> docs) => [
    for (final d in docs)
      ItemDocumentRow(id: d.id, title: d.name, meta: _docMeta(d)),
  ];

  static String _docMeta(ItemDocument d) {
    final pages = d.pageCount;
    final ends = d.expirationDate;
    return [
      if ((d.typeName ?? '').isNotEmpty) d.typeName!,
      DocumentFormat.extension(d.mimeType),
      if (pages != null) '$pages ${pages == 1 ? 'page' : 'pages'}',
      if (ends != null) 'ends ${DateFormat.MMMd().format(ends)}',
    ].where((s) => s.isNotEmpty).join(' · ').toUpperCase();
  }
}
