import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_button.dart';
import '../../../models/maintenance_task.dart';
import '../../../models/skip_plan.dart';
import '../../../tasks_copy.dart';
import 'choice_chips.dart';
import 'skip_reason_card.dart';

/// The body of the "Not now?" sheet. Pops the sheet with the chosen
/// [SkipPlan] when the big button is pressed.
class SkipSheetBody extends StatefulWidget {
  const SkipSheetBody({super.key, required this.task, required this.today});

  final MaintenanceTask task;
  final DateTime today;

  @override
  State<SkipSheetBody> createState() => _SkipSheetBodyState();
}

class _SkipSheetBodyState extends State<SkipSheetBody> {
  SkipPlan _plan = const SkipPlan();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final nextForSkip = SkipPlan.nextAfter(widget.task, widget.task.dueDate);
    final reasons = <({SkipReason reason, String title, String sub})>[
      (
        reason: SkipReason.later,
        title: TasksCopy.reasonLater,
        sub: TasksCopy.reasonLaterSub,
      ),
      (
        reason: SkipReason.other,
        title: TasksCopy.reasonOther,
        sub: TasksCopy.reasonOtherSub,
      ),
      (
        reason: SkipReason.notApplicable,
        title: TasksCopy.reasonNotApplicable,
        sub: TasksCopy.reasonNotApplicableSub,
      ),
      (
        reason: SkipReason.skip,
        title: TasksCopy.reasonSkip,
        sub: TasksCopy.reasonSkipSub(
          nextForSkip == null
              ? null
              : TasksCopy.comesBack(nextForSkip, widget.today),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.task.name, style: AuroraTasksAType.sheetHeading),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        Text(TasksCopy.dueMeta(widget.task), style: AuroraType.meta),
        gap,
        for (final r in reasons) ...[
          SkipReasonCard(
            title: r.title,
            subtitle: r.sub,
            selected: _plan.reason == r.reason,
            onTap: () =>
                setState(() => _plan = _plan.copyWith(reason: r.reason)),
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
        if (_plan.reason == SkipReason.later) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ChoiceChips<SkipDelay>(
            label: TasksCopy.remindMe,
            selected: _plan.delay,
            onSelected: (d) => setState(() => _plan = _plan.copyWith(delay: d)),
            options: const [
              (value: SkipDelay.oneWeek, label: TasksCopy.delayWeek),
              (value: SkipDelay.twoWeeks, label: TasksCopy.delayTwoWeeks),
              (value: SkipDelay.oneMonth, label: TasksCopy.delayMonth),
            ],
          ),
        ],
        if (_plan.reason == SkipReason.other) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          ChoiceChips<bool>(
            label: TasksCopy.whoDidIt,
            selected: _plan.byPro,
            onSelected: (pro) =>
                setState(() => _plan = _plan.copyWith(byPro: pro)),
            options: const [
              (value: false, label: TasksCopy.whoSomeoneElse),
              (value: true, label: TasksCopy.whoPro),
            ],
          ),
        ],
        gap,
        _ResultBox(text: _plan.result(widget.task, widget.today)),
        gap,
        PrimaryButton(
          label: _plan.cta,
          expand: true,
          large: true,
          tone: _plan.reason == SkipReason.notApplicable
              ? AuroraButtonTone.coral
              : AuroraButtonTone.cobalt,
          onPressed: () => Navigator.of(context).pop(_plan),
        ),
      ],
    );
  }
}

/// What the choice will do, in a bordered box.
class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraSpacing.space6),
        vertical: a.of(AuroraSpacing.space5),
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: a.of(AuroraSpacing.space1)),
            child: Icon(
              Icons.done_all,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkHelper,
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space4)),
          Expanded(child: Text(text, style: AuroraTasksAType.result)),
        ],
      ),
    );
  }
}
