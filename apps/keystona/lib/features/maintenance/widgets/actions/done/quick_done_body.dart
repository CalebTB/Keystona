import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../models/maintenance_task.dart';
import '../../../models/quick_done_form.dart';
import '../../../models/quick_done_result.dart';
import '../../../tasks_copy.dart';
import '../skip/choice_chips.dart';
import 'quick_done_add_more.dart';
import 'quick_done_badge_row.dart';
import 'quick_done_fields.dart';

/// The body of the quick-done sheet: Undo | title | Save, what was done, when
/// and by whom, an optional cost and note, and a way to log more.
class QuickDoneBody extends StatefulWidget {
  const QuickDoneBody({super.key, required this.task, required this.today});

  final MaintenanceTask task;
  final DateTime today;

  @override
  State<QuickDoneBody> createState() => _QuickDoneBodyState();
}

class _QuickDoneBodyState extends State<QuickDoneBody> {
  late QuickDoneForm _form = QuickDoneForm(today: widget.today);
  final _cost = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.picked ?? _form.completedOn,
      firstDate: DateTime(
        widget.today.year - 1,
        widget.today.month,
        widget.today.day,
      ),
      lastDate: widget.today,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _form = _form.copyWith(when: DoneWhen.picked, picked: picked),
    );
  }

  void _close(QuickDoneResult result) => Navigator.of(context).pop(result);

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final pickedLabel = _form.picked == null
        ? TasksCopy.pickDay
        : TasksCopy.dateLabel(_form.picked!);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            onUndo: () => _close(const QuickDoneResult(QuickDoneOutcome.undo)),
            onSave: () => _close(
              QuickDoneResult(
                QuickDoneOutcome.save,
                _form.toCompletion(cost: _cost.text, note: _note.text),
              ),
            ),
          ),
          gap,
          QuickDoneBadgeRow(
            name: widget.task.name,
            meta: TasksCopy.doneMeta(_form.nextFor(widget.task)),
          ),
          gap,
          ChoiceChips<DoneWhen>(
            label: TasksCopy.when,
            selected: _form.when,
            onSelected: (when) => when == DoneWhen.picked
                ? _pickDay()
                : setState(() => _form = _form.copyWith(when: when)),
            options: [
              (value: DoneWhen.today, label: TasksCopy.whenToday),
              (value: DoneWhen.yesterday, label: TasksCopy.whenYesterday),
              (value: DoneWhen.picked, label: pickedLabel),
            ],
          ),
          gap,
          ChoiceChips<bool>(
            label: TasksCopy.whoDidIt,
            selected: _form.byPro,
            onSelected: (pro) =>
                setState(() => _form = _form.copyWith(byPro: pro)),
            options: const [
              (value: false, label: TasksCopy.whoMe),
              (value: true, label: TasksCopy.whoPro),
            ],
          ),
          gap,
          QuickDoneFields(cost: _cost, note: _note),
          gap,
          QuickDoneAddMore(
            onTap: () =>
                _close(const QuickDoneResult(QuickDoneOutcome.addMore)),
          ),
        ],
      ),
    );
  }
}

/// Undo (left), the title, and the Save pill (right).
class _Header extends StatelessWidget {
  const _Header({required this.onUndo, required this.onSave});

  final VoidCallback onUndo;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AuroraPressable(
              onTap: onUndo,
              enforceTouchTarget: true,
              child: Text(TasksCopy.undo, style: AuroraType.cancel),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: a.of(AuroraSpacing.space3),
            ),
            child: Text(
              TasksCopy.doneSheetTitle,
              textAlign: TextAlign.center,
              style: AuroraType.sheetTitle,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SaveButton(
              label: TasksCopy.save,
              onPressed: onSave,
              compact: true,
            ),
          ),
        ),
      ],
    );
  }
}
