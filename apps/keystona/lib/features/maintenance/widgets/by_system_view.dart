import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../home_profile/models/appliance.dart' hide ItemStatus;
import '../../home_profile/models/system.dart';
import '../../home_profile/providers/appliances_provider.dart';
import '../../home_profile/providers/systems_provider.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';

// ── Category helpers ───────────────────────────────────────────────────────────

IconData _systemIcon(SystemCategory cat) => switch (cat) {
      SystemCategory.hvac => Icons.ac_unit_outlined,
      SystemCategory.plumbing => Icons.water_drop_outlined,
      SystemCategory.electrical => Icons.electrical_services_outlined,
      SystemCategory.roofing => Icons.roofing_outlined,
      SystemCategory.foundation => Icons.foundation_outlined,
      SystemCategory.siding => Icons.home_outlined,
      SystemCategory.windowsDoors => Icons.window_outlined,
      SystemCategory.insulation => Icons.layers_outlined,
      SystemCategory.garage => Icons.garage_outlined,
      SystemCategory.other => Icons.build_outlined,
    };

Color _systemColor(SystemCategory cat) => switch (cat) {
      SystemCategory.hvac => AuroraColors.cobalt,
      SystemCategory.plumbing => AuroraColors.cobalt,
      SystemCategory.electrical => AuroraColors.yellowDeep,
      SystemCategory.roofing => AuroraColors.yellow,
      SystemCategory.foundation => AuroraColors.inkTertiary,
      SystemCategory.siding => AuroraColors.limeDeep,
      SystemCategory.windowsDoors => AuroraColors.cobalt,
      SystemCategory.insulation => AuroraColors.yellow,
      SystemCategory.garage => AuroraColors.inkTertiary,
      SystemCategory.other => AuroraColors.inkTertiary,
    };

Color _healthColor(HomeSystem system) => switch (system.status) {
      ItemStatus.active => AuroraColors.limeDim,
      ItemStatus.needsRepair => AuroraColors.yellow,
      _ => AuroraColors.inkTertiary,
    };

IconData _applianceIcon(ApplianceCategory cat) => switch (cat) {
      ApplianceCategory.kitchen => Icons.kitchen_outlined,
      ApplianceCategory.laundry => Icons.local_laundry_service_outlined,
      ApplianceCategory.climate => Icons.air_outlined,
      ApplianceCategory.cleaning => Icons.cleaning_services_outlined,
      ApplianceCategory.outdoor => Icons.yard_outlined,
      ApplianceCategory.bathroom => Icons.shower_outlined,
      ApplianceCategory.other => Icons.devices_other_outlined,
    };

Color _applianceColor(ApplianceCategory cat) => switch (cat) {
      ApplianceCategory.kitchen => AuroraColors.cobalt,
      ApplianceCategory.laundry => AuroraColors.cobalt,
      ApplianceCategory.climate => AuroraColors.yellowDeep,
      ApplianceCategory.cleaning => AuroraColors.limeDeep,
      ApplianceCategory.outdoor => AuroraColors.yellow,
      ApplianceCategory.bathroom => AuroraColors.yellow,
      ApplianceCategory.other => AuroraColors.inkTertiary,
    };

Color _taskDotColor(MaintenanceTask t) {
  if (t.status == TaskStatus.completed) return AuroraColors.limeDeep;
  if (t.status == TaskStatus.skipped) return AuroraColors.inkBorder;
  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);
  final due = t.dueDate.toLocal();
  final dueMid = DateTime(due.year, due.month, due.day);
  if (t.status == TaskStatus.overdue || dueMid.isBefore(todayMid)) {
    return AuroraColors.coral;
  }
  if (dueMid == todayMid) return AuroraColors.yellowDeep;
  final weekOut = todayMid.add(const Duration(days: 7));
  if (dueMid.isBefore(weekOut)) return AuroraColors.yellow;
  return AuroraColors.cobalt;
}

// ── Context label ──────────────────────────────────────────────────────────────

typedef _Label = ({String text, Color color});

DateTime? _nextDueDate(MaintenanceTask t) {
  final base = t.dueDate.toLocal();
  return switch (t.recurrence) {
    RecurrenceType.none => null,
    RecurrenceType.weekly => base.add(const Duration(days: 7)),
    RecurrenceType.biweekly => base.add(const Duration(days: 14)),
    RecurrenceType.monthly => DateTime(base.year, base.month + 1, base.day),
    RecurrenceType.quarterly => DateTime(base.year, base.month + 3, base.day),
    RecurrenceType.biannual => DateTime(base.year, base.month + 6, base.day),
    RecurrenceType.annual => DateTime(base.year + 1, base.month, base.day),
  };
}

_Label _contextLabel(MaintenanceTask t) {
  if (t.status == TaskStatus.completed) {
    final next = _nextDueDate(t);
    if (next == null) return (text: 'Done', color: AuroraColors.limeDeep);
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final nextMid = DateTime(next.year, next.month, next.day);
    final diff = nextMid.difference(todayMid).inDays;
    if (diff <= 0) return (text: 'Due again', color: AuroraColors.yellowDeep);
    if (diff == 1) return (text: 'Due tomorrow', color: AuroraColors.yellowDeep);
    if (diff <= 7) return (text: 'Good for $diff days', color: AuroraColors.cobalt);
    if (diff <= 60) {
      final weeks = (diff / 7).round();
      return (text: 'Good for $weeks wk', color: AuroraColors.cobalt);
    }
    final months = (diff / 30).round();
    if (months < 12) return (text: 'Good for $months mo', color: AuroraColors.limeDeep);
    return (text: '~1 year', color: AuroraColors.limeDeep);
  }
  if (t.status == TaskStatus.skipped) {
    return (text: 'Skipped', color: AuroraColors.inkTertiary);
  }

  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);
  final due = t.dueDate.toLocal();
  final dueMid = DateTime(due.year, due.month, due.day);
  final diff = dueMid.difference(todayMid).inDays;

  if (t.status == TaskStatus.overdue || dueMid.isBefore(todayMid)) {
    final daysAgo = todayMid.difference(dueMid).inDays;
    if (daysAgo <= 1) return (text: 'Overdue', color: AuroraColors.coral);
    if (daysAgo <= 14) return (text: '${daysAgo}d overdue', color: AuroraColors.coral);
    final weeks = (daysAgo / 7).round();
    if (weeks <= 8) return (text: '${weeks}wk overdue', color: AuroraColors.coral);
    final months = (daysAgo / 30).round();
    return (text: '${months}mo overdue', color: AuroraColors.coral);
  }
  if (diff == 0) return (text: 'Due today', color: AuroraColors.yellowDeep);
  if (diff == 1) return (text: 'Due tomorrow', color: AuroraColors.yellowDeep);
  if (diff <= 7) return (text: 'Due this week', color: AuroraColors.yellowDeep);
  if (diff <= 31) return (text: 'Due this month', color: AuroraColors.yellow);
  if (diff <= 60) {
    final weeks = (diff / 7).round();
    return (text: 'Good for $weeks wk', color: AuroraColors.cobalt);
  }
  final months = (diff / 30).round();
  if (months < 12) return (text: 'Good for $months mo', color: AuroraColors.cobalt);
  return (text: '~1 year', color: AuroraColors.limeDeep);
}

int _taskSortKey(MaintenanceTask t) {
  if (t.status == TaskStatus.skipped) return 5;
  if (t.status == TaskStatus.completed) return 4;
  final dot = _taskDotColor(t);
  if (dot == AuroraColors.coral) return 0;
  if (dot == AuroraColors.yellowDeep) return 1;
  if (dot == AuroraColors.yellow) return 2;
  return 3;
}

String? _installYear(String? date) {
  if (date == null || date.length < 4) return null;
  return date.substring(0, 4);
}

// ── Main sliver widget ─────────────────────────────────────────────────────────

class BySystemView extends ConsumerWidget {
  const BySystemView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    final appliancesAsync = ref.watch(appliancesProvider);
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    if (systemsAsync.isLoading || tasksAsync.isLoading) {
      return _BySystemSkeleton();
    }

    final systems = systemsAsync.value ?? [];
    final appliances = appliancesAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];

    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final thirtyDaysOut = todayMid.add(const Duration(days: 30));

    final Map<String, List<MaintenanceTask>> systemGrouped = {};
    final Map<String, List<MaintenanceTask>> applianceGrouped = {};
    final List<MaintenanceTask> uncategorized = [];

    for (final t in tasks) {
      if (t.status == TaskStatus.completed && t.recurrence == RecurrenceType.none) {
        continue;
      }
      if (t.linkedSystemId != null) {
        systemGrouped.putIfAbsent(t.linkedSystemId!, () => []).add(t);
      } else if (t.linkedApplianceId != null) {
        applianceGrouped.putIfAbsent(t.linkedApplianceId!, () => []).add(t);
      } else {
        uncategorized.add(t);
      }
    }

    bool isAllClear(List<MaintenanceTask> list) {
      for (final t in list) {
        if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) continue;
        final due = t.dueDate.toLocal();
        final dueMid = DateTime(due.year, due.month, due.day);
        if (t.status == TaskStatus.overdue || dueMid.isBefore(thirtyDaysOut)) return false;
      }
      return true;
    }

    int overdueCount(List<MaintenanceTask> list) => list.where((t) {
          final due = t.dueDate.toLocal();
          final dueMid = DateTime(due.year, due.month, due.day);
          return t.status == TaskStatus.overdue || dueMid.isBefore(todayMid);
        }).length;

    final attentionSystems = systems
        .where((s) => systemGrouped.containsKey(s.id) && !isAllClear(systemGrouped[s.id]!))
        .toList()
      ..sort((a, b) => overdueCount(systemGrouped[b.id]!)
          .compareTo(overdueCount(systemGrouped[a.id]!)));

    final attentionAppliances = appliances
        .where((a) => applianceGrouped.containsKey(a.id) && !isAllClear(applianceGrouped[a.id]!))
        .toList()
      ..sort((a, b) => overdueCount(applianceGrouped[b.id]!)
          .compareTo(overdueCount(applianceGrouped[a.id]!)));

    final clearSystems = systems.where((s) =>
        isAllClear(systemGrouped[s.id] ?? [])).toList();
    final clearAppliances = appliances.where((a) =>
        applianceGrouped.containsKey(a.id) &&
        isAllClear(applianceGrouped[a.id]!)).toList();

    final Map<String, List<MaintenanceTask>> clearSystemTasks = {
      for (final s in clearSystems)
        if (systemGrouped.containsKey(s.id)) s.id: systemGrouped[s.id]!,
    };

    if (systems.isEmpty && appliances.isEmpty) {
      return _NoSystemsEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ...attentionSystems.map(
                (system) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SystemCard(
                    system: system,
                    tasks: systemGrouped[system.id]!,
                  ),
                ),
              ),
              ...attentionAppliances.map(
                (appliance) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ApplianceCard(
                    appliance: appliance,
                    tasks: applianceGrouped[appliance.id]!,
                  ),
                ),
              ),
              if (uncategorized.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _UncategorizedCard(tasks: uncategorized),
                ),
            ],
          ),
        ),
        if (clearSystems.isNotEmpty || clearAppliances.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AllClearCard(
              systems: clearSystems,
              tasksBySystem: clearSystemTasks,
              appliances: clearAppliances,
              tasksByAppliance: {
                for (final a in clearAppliances)
                  if (applianceGrouped.containsKey(a.id))
                    a.id: applianceGrouped[a.id]!,
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── System card (has tasks) ────────────────────────────────────────────────────

class _SystemCard extends StatefulWidget {
  const _SystemCard({required this.system, required this.tasks});
  final HomeSystem system;
  final List<MaintenanceTask> tasks;
  @override
  State<_SystemCard> createState() => _SystemCardState();
}

class _SystemCardState extends State<_SystemCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final color = _systemColor(widget.system.category);
    final icon = _systemIcon(widget.system.category);
    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });
    final systemName = widget.system.brand != null
        ? '${widget.system.brand} ${widget.system.name}'
        : widget.system.name;
    final year = _installYear(widget.system.installationDate);
    final location = widget.system.location;
    final count = sorted.length;

    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A071238),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _collapsed = !_collapsed);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/home/systems/${widget.system.id}'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            systemName,
                            style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _healthColor(widget.system),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (location != null && location.isNotEmpty) ...[
                                Text(
                                  location,
                                  style: AuroraType.bodySm.copyWith(
                                    color: AuroraColors.inkSecondary,
                                  ),
                                ),
                                if (year != null)
                                  Text(
                                    '  ·  ',
                                    style: AuroraType.bodySm.copyWith(
                                      color: AuroraColors.inkTertiary,
                                    ),
                                  ),
                              ],
                              if (year != null)
                                Text(
                                  year,
                                  style: AuroraType.bodySm.copyWith(
                                    color: AuroraColors.inkSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AuroraColors.inkBorder, width: 1),
                      ),
                      child: Text(
                        '$count',
                        style: AuroraType.labelSm.copyWith(color: AuroraColors.inkSecondary),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _collapsed ? 0.25 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _collapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: AuroraColors.inkBorder),
                    ...sorted.map((t) => _TaskRow(task: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appliance card ─────────────────────────────────────────────────────────────

class _ApplianceCard extends StatefulWidget {
  const _ApplianceCard({required this.appliance, required this.tasks});
  final Appliance appliance;
  final List<MaintenanceTask> tasks;
  @override
  State<_ApplianceCard> createState() => _ApplianceCardState();
}

class _ApplianceCardState extends State<_ApplianceCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final color = _applianceColor(widget.appliance.category);
    final icon = _applianceIcon(widget.appliance.category);
    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });
    final name = widget.appliance.brand != null
        ? '${widget.appliance.brand} ${widget.appliance.name}'
        : widget.appliance.name;
    final count = sorted.length;

    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0x0A071238), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _collapsed = !_collapsed);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/home/appliances/${widget.appliance.id}'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AuroraType.body.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(
                            widget.appliance.category.label,
                            style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AuroraColors.inkBorder, width: 1),
                      ),
                      child: Text('$count',
                          style: AuroraType.labelSm.copyWith(color: AuroraColors.inkSecondary)),
                    ),
                    AnimatedRotation(
                      turns: _collapsed ? 0.25 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: AuroraColors.inkSecondary),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _collapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: AuroraColors.inkBorder),
                    ...sorted.map((t) => _TaskRow(task: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task row ───────────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final label = _contextLabel(task);
    final isDone = task.status == TaskStatus.skipped ||
        (task.status == TaskStatus.completed && _nextDueDate(task) == null);

    return GestureDetector(
      onTap: () => context.push('/maintenance/${task.id}'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            child: Opacity(
              opacity: isDone ? 0.5 : 1.0,
              child: Row(
                children: [
                  if (isDone && task.status == TaskStatus.completed) ...[
                    Icon(Icons.check_circle_outline, size: 14, color: AuroraColors.limeDeep),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      task.name,
                      style: AuroraType.body.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: AuroraColors.inkSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: label.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label.text,
                      style: AuroraType.labelSm.copyWith(
                        color: label.color,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: AuroraColors.butter, indent: 42),
        ],
      ),
    );
  }
}

// ── Uncategorized card ─────────────────────────────────────────────────────────

class _UncategorizedCard extends StatefulWidget {
  const _UncategorizedCard({required this.tasks});
  final List<MaintenanceTask> tasks;
  @override
  State<_UncategorizedCard> createState() => _UncategorizedCardState();
}

class _UncategorizedCardState extends State<_UncategorizedCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });
    final count = sorted.length;

    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0x0A071238), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _collapsed = !_collapsed);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.checklist_rounded, size: 20, color: AuroraColors.inkTertiary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'General Tasks',
                            style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'No system linked',
                            style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AuroraColors.inkBorder, width: 1),
                      ),
                      child: Text('$count',
                          style: AuroraType.labelSm.copyWith(color: AuroraColors.inkSecondary)),
                    ),
                    AnimatedRotation(
                      turns: _collapsed ? 0.25 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: AuroraColors.inkSecondary),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _collapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: AuroraColors.inkBorder),
                    ...sorted.map((t) => _TaskRow(task: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Clear card ─────────────────────────────────────────────────────────────

class _AllClearCard extends StatelessWidget {
  const _AllClearCard({
    required this.systems,
    required this.tasksBySystem,
    this.appliances = const [],
    this.tasksByAppliance = const {},
  });

  final List<HomeSystem> systems;
  final Map<String, List<MaintenanceTask>> tasksBySystem;
  final List<Appliance> appliances;
  final Map<String, List<MaintenanceTask>> tasksByAppliance;

  @override
  Widget build(BuildContext context) {
    final total = systems.length + appliances.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuroraColors.limeDim,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(
          color: AuroraColors.limeDeep.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AuroraColors.limeDeep.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 18, color: AuroraColors.limeDeep),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total item${total == 1 ? '' : 's'} in good standing',
                    style: AuroraType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AuroraColors.limeDeep,
                    ),
                  ),
                  Text(
                    'All tasks 30+ days out',
                    style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...systems.map((s) {
                final color = _systemColor(s.category);
                final icon = _systemIcon(s.category);
                final sysTasks = tasksBySystem[s.id] ?? [];
                final pending = sysTasks
                    .where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.skipped)
                    .toList()
                  ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                final nextDue = pending.isEmpty ? null : pending.first.dueDate.toLocal();
                return GestureDetector(
                  onTap: () => context.push('/home/systems/${s.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: AuroraColors.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AuroraColors.inkBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.name,
                                style: AuroraType.labelSm.copyWith(
                                    color: AuroraColors.ink, fontSize: 11)),
                            Text(
                              nextDue != null
                                  ? 'Next ${DateFormat('MMM d').format(nextDue)}'
                                  : 'No tasks yet',
                              style: AuroraType.label.copyWith(
                                  color: AuroraColors.inkTertiary, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 13, color: AuroraColors.inkTertiary),
                      ],
                    ),
                  ),
                );
              }),
              ...appliances.map((a) {
                final color = _applianceColor(a.category);
                final icon = _applianceIcon(a.category);
                final appTasks = tasksByAppliance[a.id] ?? [];
                final pending = appTasks
                    .where((t) => t.status != TaskStatus.completed && t.status != TaskStatus.skipped)
                    .toList()
                  ..sort((x, y) => x.dueDate.compareTo(y.dueDate));
                final nextDue = pending.isEmpty ? null : pending.first.dueDate.toLocal();
                return GestureDetector(
                  onTap: () => context.push('/home/appliances/${a.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: AuroraColors.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AuroraColors.inkBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a.name,
                                style: AuroraType.labelSm.copyWith(
                                    color: AuroraColors.ink, fontSize: 11)),
                            Text(
                              nextDue != null
                                  ? 'Next ${DateFormat('MMM d').format(nextDue)}'
                                  : 'No tasks yet',
                              style: AuroraType.label.copyWith(
                                  color: AuroraColors.inkTertiary, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 13, color: AuroraColors.inkTertiary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ── No systems empty state ─────────────────────────────────────────────────────

class _NoSystemsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AuroraColors.paper,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AuroraColors.cobalt.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_repair_service_outlined,
                      size: 26, color: AuroraColors.cobalt),
                ),
                const SizedBox(height: 12),
                Text('No systems added yet',
                    style: AuroraType.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Add your home systems in Home Profile\nto see tasks organized by system.',
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _BySystemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 12),
            _SkeletonSystemCard(),
            SizedBox(height: 8),
            _SkeletonSystemCard(),
            SizedBox(height: 8),
            _SkeletonSystemCard(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSystemCard extends StatelessWidget {
  const _SkeletonSystemCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Column(
        children: [
          Container(height: 72, color: AuroraColors.inkBorder),
          Container(
            color: AuroraColors.paper,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _SkeletonTaskRow(),
                const SizedBox(height: 10),
                _SkeletonTaskRow(),
                const SizedBox(height: 10),
                _SkeletonTaskRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTaskRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: AuroraColors.butter, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 12, color: AuroraColors.butter)),
        const SizedBox(width: 10),
        Container(
          width: 64,
          height: 20,
          decoration: BoxDecoration(
            color: AuroraColors.butter,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
