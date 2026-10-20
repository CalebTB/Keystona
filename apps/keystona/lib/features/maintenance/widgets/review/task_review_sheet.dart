import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../models/reminder_frequency.dart';
import '../../models/review_row.dart';
import '../../models/suggested_task.dart';
import '../../reminders_copy.dart';
import '../reminders/review_footer_note.dart';
import '../reminders/review_group_section.dart';
import '../reminders/review_summary_card.dart';
import '../reminders/review_top_bar.dart';
import '../reminders/reminders_header.dart';

/// Review your reminders as a sheet (kit: TaskReview), shown after a system
/// or appliance is scanned: the suggested reminders for that item, each with
/// a switch, and "Looks good — keep N" to add the ones left on.
///
/// Pops `true` once [onConfirm] has added them and `false` on Skip.
class TaskReviewSheet extends StatefulWidget {
  const TaskReviewSheet({
    super.key,
    required this.tasks,
    required this.itemName,
    required this.onConfirm,
  });

  final List<SuggestedTask> tasks;

  /// The system or appliance the reminders are for.
  final String itemName;

  /// Adds the reminders left on. Throws when they could not be added.
  final Future<void> Function(List<SuggestedTask> selected) onConfirm;

  @override
  State<TaskReviewSheet> createState() => _TaskReviewSheetState();
}

class _TaskReviewSheetState extends State<TaskReviewSheet> {
  late final List<bool> _on;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _on = List.filled(widget.tasks.length, true);
  }

  List<SuggestedTask> get _selected => [
    for (var i = 0; i < widget.tasks.length; i++)
      if (_on[i]) widget.tasks[i],
  ];

  void _toggle(String key, bool on) => setState(() => _on[int.parse(key)] = on);

  void _turnAllOn() => setState(() => _on.fillRange(0, _on.length, true));

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await widget.onConfirm(_selected);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, RemindersCopy.changeError);
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final selected = _selected;
    final gap = SizedBox(height: a.of(AuroraTasksCSizes.blockGap));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReviewTopBar(
          leading: Align(
            alignment: Alignment.centerLeft,
            child: AuroraPressable(
              onTap: _saving ? null : () => Navigator.of(context).pop(false),
              semanticLabel: RemindersCopy.reviewSkip,
              enforceTouchTarget: true,
              child: Text(
                RemindersCopy.reviewSkip,
                style: AuroraType.cancel.copyWith(color: AuroraColors.ink),
              ),
            ),
          ),
          onTurnAllOn: _saving ? null : _turnAllOn,
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        RemindersHeader(
          eyebrow: widget.itemName,
          title: RemindersCopy.reviewTitle,
          blurb: RemindersCopy.reviewBlurb,
        ),
        gap,
        ReviewSummaryCard(
          on: selected.length,
          all: widget.tasks.length,
          perMonth: ReminderFrequency.perMonth(
            selected.map((t) => t.recurrenceType),
          ),
        ),
        gap,
        ReviewGroupSection(
          title: widget.itemName,
          subtitle: RemindersCopy.becauseYouAdded(widget.itemName),
          rows: [
            for (var i = 0; i < widget.tasks.length; i++)
              ReviewRow(
                key: '$i',
                name: widget.tasks[i].name,
                frequency: ReminderFrequency.label(
                  widget.tasks[i].recurrenceType,
                ),
                on: _on[i],
              ),
          ],
          onToggle: _toggle,
        ),
        gap,
        const ReviewFooterNote(),
        gap,
        PrimaryButton(
          label: RemindersCopy.keepLabel(selected.length),
          expand: true,
          large: true,
          loading: _saving,
          onPressed: selected.isEmpty || _saving ? null : _confirm,
        ),
      ],
    );
  }
}
