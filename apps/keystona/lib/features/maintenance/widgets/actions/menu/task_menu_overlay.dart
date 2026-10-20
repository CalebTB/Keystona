import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_shadows.dart';
import '../../../../../core/theme/aurora_motion.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../models/maintenance_task.dart';
import '../../../models/skip_plan.dart';
import '../../../models/task_menu_choice.dart';
import '../../../tasks_copy.dart';
import 'task_menu_divider.dart';
import 'task_menu_frequency.dart';
import 'task_menu_preview.dart';
import 'task_menu_row.dart';

/// The long-press menu (TaskMenu): the screen behind blurs, the pressed task
/// lifts, and four choices open under it. Tapping anywhere else closes it;
/// there is no Cancel button. Pops with the chosen [TaskMenuChoice].
class TaskMenuOverlay extends StatefulWidget {
  const TaskMenuOverlay({super.key, required this.task, required this.today});

  final MaintenanceTask task;
  final DateTime today;

  @override
  State<TaskMenuOverlay> createState() => _TaskMenuOverlayState();
}

class _TaskMenuOverlayState extends State<TaskMenuOverlay> {
  bool _frequencyOpen = false;

  void _choose(TaskMenuChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final task = widget.task;
    final next = SkipPlan.nextAfter(task, task.dueDate);
    final skipSub = TasksCopy.menuSkipSub(
      next == null ? null : TasksCopy.comesBack(next, widget.today),
    );

    final menu = DecoratedBox(
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.all(
          Radius.circular(AuroraTasksA.menuRadius),
        ),
        boxShadow: AuroraShadows.modal,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(AuroraTasksA.menuRadius),
        ),
        child: Semantics(
          label: TasksCopy.menuLabel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TaskMenuRow(
                icon: Icons.schedule,
                title: TasksCopy.menuSkip,
                subtitle: skipSub,
                onTap: () => _choose(const TaskMenuChoice(TaskMenuAction.skip)),
              ),
              const TaskMenuDivider(),
              TaskMenuRow(
                icon: Icons.calendar_today_outlined,
                title: TasksCopy.menuFrequency,
                subtitle: TasksCopy.menuFrequencySub(
                  TasksCopy.frequencyName(task.recurrence),
                ),
                expanded: _frequencyOpen,
                onTap: () => setState(() => _frequencyOpen = !_frequencyOpen),
                trailing: AnimatedRotation(
                  turns: _frequencyOpen ? 0.5 : 0,
                  duration: AuroraDurations.fast,
                  child: Icon(
                    Icons.expand_more,
                    size: a.of(AuroraIconSizes.lg),
                    color: AuroraColors.inkHelper,
                  ),
                ),
              ),
              if (_frequencyOpen)
                TaskMenuFrequency(
                  current: task.recurrence,
                  onPick: (type) =>
                      _choose(TaskMenuChoice(TaskMenuAction.frequency, type)),
                ),
              const TaskMenuDivider(),
              TaskMenuRow(
                icon: Icons.description_outlined,
                title: TasksCopy.menuOpen,
                onTap: () => _choose(const TaskMenuChoice(TaskMenuAction.open)),
                trailing: Icon(
                  Icons.chevron_right,
                  size: a.of(AuroraIconSizes.md),
                  color: AuroraColors.inkHelper,
                ),
              ),
              const ColoredBox(
                color: AuroraTasksA.setApartBar,
                child: SizedBox(
                  height: AuroraTasksA.menuSetApart,
                  width: double.infinity,
                ),
              ),
              TaskMenuRow(
                icon: Icons.notifications_off_outlined,
                title: TasksCopy.menuStop,
                subtitle: TasksCopy.menuStopSub,
                destructive: true,
                onTap: () => _choose(const TaskMenuChoice(TaskMenuAction.stop)),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AuroraTasksA.blurSigma,
            sigmaY: AuroraTasksA.blurSigma,
          ),
          child: ColoredBox(
            color: AuroraTasksA.menuScrim,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: a.contentMaxWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: a.of(AuroraSpacing.screenPadH),
                            vertical: a.of(AuroraSpacing.space9),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              IgnorePointer(
                                child: TaskMenuPreview(
                                  task: task,
                                  today: widget.today,
                                ),
                              ),
                              SizedBox(height: a.of(AuroraSpacing.space9)),
                              menu,
                              SizedBox(height: a.of(AuroraSpacing.space9)),
                              Text(
                                TasksCopy.closeHint,
                                textAlign: TextAlign.center,
                                style: AuroraTasksAType.closeHint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
