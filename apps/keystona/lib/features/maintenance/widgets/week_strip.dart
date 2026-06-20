import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/maintenance_task.dart';

/// Horizontal 7-day week strip with dot indicators per day.
///
/// Displays Mon–Sun for the given [weekStart]. Each day shows task dots
/// grouped by urgency: overdue (accent), due soon (sand), scheduled (slate).
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.tasks,
    required this.weekStart,
    required this.selectedDate,
    required this.onDaySelected,
  });

  final List<MaintenanceTask> tasks;
  final DateTime weekStart;
  final DateTime selectedDate;
  final void Function(DateTime) onDaySelected;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final date = weekStart.add(Duration(days: i));
        return Expanded(
          child: _DayCol(
            date: date,
            dayName: _dayNames[i],
            tasks: tasks,
            isSelected: _sameDay(date, selectedDate),
            isToday: _sameDay(date, DateTime.now()),
            onTap: () => onDaySelected(date),
          ),
        );
      }),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Day column ────────────────────────────────────────────────────────────────

class _DayCol extends StatelessWidget {
  const _DayCol({
    required this.date,
    required this.dayName,
    required this.tasks,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String dayName;
  final List<MaintenanceTask> tasks;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    if (isToday) {
      bg = AppColors.deepNavy;
      textColor = AppColors.textInverse;
    } else if (isSelected) {
      bg = AppColors.accent;
      textColor = AppColors.textInverse;
    } else {
      bg = Colors.transparent;
      textColor = AppColors.textPrimary;
    }

    final dots = _dotsForDate(date, tasks);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: (isToday || isSelected)
                    ? AppColors.textInverse.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            _DotsRow(dots: dots),
          ],
        ),
      ),
    );
  }

  /// Groups tasks due on [date] into (overdue, dueSoon, scheduled) counts.
  static _DayDots _dotsForDate(DateTime date, List<MaintenanceTask> tasks) {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final dateMidnight = DateTime(date.year, date.month, date.day);

    var overdue = 0;
    var dueSoon = 0;
    var scheduled = 0;

    for (final task in tasks) {
      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.skipped) {
        continue;
      }
      final due = task.dueDate.toLocal();
      final dueMidnight = DateTime(due.year, due.month, due.day);
      if (dueMidnight != dateMidnight) continue;

      if (task.status == TaskStatus.overdue ||
          dueMidnight.isBefore(todayMidnight)) {
        overdue++;
      } else if (dueMidnight == todayMidnight) {
        dueSoon++;
      } else {
        scheduled++;
      }
    }

    return _DayDots(overdue: overdue, dueSoon: dueSoon, scheduled: scheduled);
  }
}

// ── Dot types record ──────────────────────────────────────────────────────────

class _DayDots {
  const _DayDots({
    required this.overdue,
    required this.dueSoon,
    required this.scheduled,
  });
  final int overdue;
  final int dueSoon;
  final int scheduled;
}

// ── Dots row ──────────────────────────────────────────────────────────────────

class _DotsRow extends StatelessWidget {
  const _DotsRow({required this.dots});

  final _DayDots dots;

  static const double _dotSize = 4;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    void addDots(int count, Color color) {
      for (var i = 0; i < count.clamp(0, 2); i++) {
        if (items.isNotEmpty) items.add(const SizedBox(width: 2));
        items.add(_Dot(color: color));
      }
    }

    addDots(dots.overdue, AppColors.accent);
    addDots(dots.dueSoon, AppColors.sand);
    addDots(dots.scheduled, AppColors.slate);

    if (items.isEmpty) {
      return const SizedBox(height: _dotSize);
    }

    return SizedBox(
      height: _dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
