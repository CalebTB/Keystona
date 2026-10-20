import 'package:intl/intl.dart';

import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/models/task_schedule.dart';
import '../lifespan/lifespan_reading.dart';
import '../systems_copy.dart';
import '../models/item_service_entry.dart';
import '../models/system.dart';
import '../models/system_document.dart';
import '../models/system_reading.dart';
import '../widgets/shared/item_document_row.dart';
import '../widgets/shared/item_key_value.dart';
import '../widgets/shared/item_next_up_entry.dart';
import '../widgets/shared/item_timeline_row.dart';

/// The words and colors family of the status chip beside the category.
enum SystemChipTone { healthy, soon, overdue, muted }

/// The chip's text and tone.
class SystemChip {
  const SystemChip(this.label, this.tone);

  final String label;
  final SystemChipTone tone;
}

/// Pure presentation logic for the System detail screen: what each card shows
/// for a system, its tasks, history and documents.
abstract final class SystemDetailView {
  /// "HEALTHY", or what is wrong: status first, then lifespan band.
  static SystemChip chip(HomeSystem s, LifespanReading reading) {
    switch (s.status) {
      case ItemStatus.needsRepair:
        return const SystemChip(
          SystemsCopy.chipNeedsRepair,
          SystemChipTone.overdue,
        );
      case ItemStatus.replaced:
        return const SystemChip(SystemsCopy.chipReplaced, SystemChipTone.muted);
      case ItemStatus.removed:
        return const SystemChip(SystemsCopy.chipRemoved, SystemChipTone.muted);
      case ItemStatus.active:
        break;
    }
    return switch (reading.band) {
      LifespanBand.aging => const SystemChip(
        SystemsCopy.chipAging,
        SystemChipTone.soon,
      ),
      LifespanBand.endOfLife => const SystemChip(
        SystemsCopy.chipEndOfLife,
        SystemChipTone.soon,
      ),
      LifespanBand.past => const SystemChip(
        SystemsCopy.chipPast,
        SystemChipTone.overdue,
      ),
      _ => const SystemChip(SystemsCopy.chipHealthy, SystemChipTone.healthy),
    };
  }

  /// Photo tag on the hero: LABEL for a label shot, otherwise UNIT.
  static String photoTag(String? photoType) =>
      photoType == 'label' || photoType == 'model_label'
      ? SystemsCopy.photoTagLabel
      : SystemsCopy.photoTagUnit;

  // ── Identification ────────────────────────────────────────────────────────

  static const List<String> _knownSpecs = ['fuel', 'output', 'filter'];

  /// BRAND, MODEL, SERIAL (copyable), then FUEL, OUTPUT, FILTER and any other
  /// specification. Empty values are left out.
  static List<ItemKeyValue> identification(HomeSystem s) {
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final specs = s.specifications ?? const <String, dynamic>{};
    String? spec(String key) => clean(specs[key]?.toString());
    final rows = <ItemKeyValue>[
      if (clean(s.brand) != null)
        ItemKeyValue(label: SystemsCopy.specBrand, value: clean(s.brand)!),
      if (clean(s.modelNumber) != null)
        ItemKeyValue(label: SystemsCopy.specModel, value: clean(s.modelNumber)!),
      if (clean(s.serialNumber) != null)
        ItemKeyValue(
          label: SystemsCopy.specSerial,
          value: clean(s.serialNumber)!,
          copyable: true,
        ),
      if (spec('fuel') != null)
        ItemKeyValue(label: SystemsCopy.specFuel, value: spec('fuel')!),
      if (spec('output') != null)
        ItemKeyValue(label: SystemsCopy.specOutput, value: spec('output')!),
      if (spec('filter') != null)
        ItemKeyValue(label: SystemsCopy.specFilter, value: spec('filter')!),
    ];
    for (final e in specs.entries) {
      final value = clean(e.value?.toString());
      if (_knownSpecs.contains(e.key) || value == null) continue;
      rows.add(
        ItemKeyValue(
          label: e.key.replaceAll('_', ' ').toUpperCase(),
          value: value,
        ),
      );
    }
    return rows;
  }

  // ── History ───────────────────────────────────────────────────────────────

  /// The timeline rows, newest first. The install row comes from the install
  /// date and price when no logged "installed" entry exists.
  static List<ItemTimelineRow> history(
    HomeSystem s,
    List<ItemServiceEntry> entries,
  ) {
    final rows = <({DateTime date, ItemTimelineRow row})>[];
    for (final e in entries) {
      rows.add((
        date: e.serviceDate,
        row: ItemTimelineRow(
          dateLabel: _monthYear(e.serviceDate),
          title: e.title,
          subtitle: _entrySubtitle(e),
          costLabel: e.cost == null ? null : SystemsCopy.money(e.cost!),
          hollow:
              e.kind == ServiceKind.installed ||
              e.kind == ServiceKind.purchased,
        ),
      ));
    }
    final installed = s.installedOn;
    final hasInstallEntry = entries.any((e) => e.kind == ServiceKind.installed);
    if (installed != null && !hasInstallEntry) {
      rows.add((
        date: installed,
        row: ItemTimelineRow(
          dateLabel: _monthYear(installed),
          title: SystemsCopy.historyInstalled,
          subtitle: (s.installer ?? '').trim().isEmpty ? null : s.installer,
          costLabel: s.purchasePrice == null
              ? null
              : SystemsCopy.money(s.purchasePrice!),
          hollow: true,
        ),
      ));
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return [for (final r in rows) r.row];
  }

  /// Everything spent on it and the year of the earliest entry, null with no
  /// costs.
  static ({double total, int sinceYear})? historyTotal(
    HomeSystem s,
    List<ItemServiceEntry> entries,
  ) {
    var total = 0.0;
    var any = false;
    DateTime? earliest;
    void take(DateTime date, double? cost) {
      if (cost == null) return;
      any = true;
      total += cost;
      if (earliest == null || date.isBefore(earliest!)) earliest = date;
    }

    for (final e in entries) {
      take(e.serviceDate, e.cost);
    }
    final installed = s.installedOn;
    if (installed != null &&
        !entries.any((e) => e.kind == ServiceKind.installed)) {
      take(installed, s.purchasePrice);
    }
    return any ? (total: total, sinceYear: earliest!.year) : null;
  }

  static String _monthYear(DateTime d) =>
      DateFormat.yMMM().format(d).toUpperCase();

  static String? _entrySubtitle(ItemServiceEntry e) {
    final parts = [
      if ((e.provider ?? '').trim().isNotEmpty) e.provider!.trim(),
      if (e.underWarranty) SystemsCopy.underWarranty,
      if (e.documentId != null) SystemsCopy.receiptSaved,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  /// Open, switched-on tasks linked to [systemId], soonest first.
  static List<MaintenanceTask> openTasks(
    Iterable<MaintenanceTask> tasks,
    String systemId,
  ) =>
      [
        for (final t in tasks)
          if (t.linkedSystemId == systemId &&
              t.notificationsEnabled &&
              TaskSchedule.isOpen(t))
            t,
      ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  /// A task as a "Next up" row: "HVAC · 15 MIN · $25", "OCT 7".
  static ItemNextUpEntry nextUp(MaintenanceTask t, DateTime today) =>
      ItemNextUpEntry(
        id: t.id,
        name: t.name,
        metaLine: [
          t.category.toUpperCase(),
          if (t.estimatedMinutes != null) _minutes(t.estimatedMinutes!),
          if (t.estimatedCost != null) SystemsCopy.money(t.estimatedCost!),
        ].join(' · '),
        dateLabel: DateFormat.MMMd().format(t.dueDate).toUpperCase(),
        soon: TaskSchedule.isSoon(t, today),
        overdue: TaskSchedule.isOverdue(t, today),
        isPro: t.diyOrPro == DiyOrPro.professional,
      );

  /// Minutes under an hour, then "1 HR" / "1½ HR" style.
  static String _minutes(int m) {
    const minutesPerHour = 60;
    if (m < minutesPerHour) return '$m MIN';
    final hours = m / minutesPerHour;
    final whole = hours.floor();
    final half = (hours - whole) >= 0.5 ? '½' : '';
    return '$whole$half HR';
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  /// A document as a row: "WARRANTY · PDF · UNTIL MAR 2031".
  static ItemDocumentRow document(SystemDocument d) {
    final ext = (d.mimeType ?? '').split('/').last.toUpperCase();
    final date = d.expirationDate != null
        ? 'UNTIL ${_monthYear(d.expirationDate!)}'
        : _monthYear(d.createdAt);
    return ItemDocumentRow(
      id: d.id,
      title: d.name,
      meta: [
        if ((d.categoryName ?? '').isNotEmpty) d.categoryName!.toUpperCase(),
        if (ext.isNotEmpty && ext.length <= 4) ext,
        date,
      ].join(' · '),
    );
  }
}
