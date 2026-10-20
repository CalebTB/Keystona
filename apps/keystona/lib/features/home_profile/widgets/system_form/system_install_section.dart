import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../forms/system_form_controller.dart';
import '../../models/system_template.dart';
import '../../systems_copy.dart';
import 'lifespan_slider.dart';
import 'option_picker.dart';
import 'scan_select_field.dart';

/// INSTALL & LIFESPAN: month and year, the lifespan slider and the "Add its
/// maintenance tasks" switch.
class SystemInstallSection extends StatelessWidget {
  const SystemInstallSection({
    super.key,
    required this.form,
    required this.online,
    required this.onOfflineTasks,
    this.showTasksSwitch = true,
  });

  final SystemFormController form;

  /// False dims the tasks switch; turning it on says so instead.
  final bool online;
  final VoidCallback onOfflineTasks;

  /// Edit mode does not offer new tasks.
  final bool showTasksSwitch;

  static String _monthName(int m) => DateFormat.MMM().format(DateTime(2000, m));

  List<int> _years() {
    final now = DateTime.now().year;
    return [for (var y = now; y >= AuroraHomeBSizes.firstInstallYear; y--) y];
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraFormSection(
      title: SystemsCopy.sectionInstall,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ScanSelectField(
                label: SystemsCopy.installed,
                placeholder: SystemsCopy.month,
                value: form.month == null ? null : _monthName(form.month!),
                fromScan: form.monthFromScan(),
                onTap: () async {
                  final picked = await pickOption<int>(
                    context,
                    title: SystemsCopy.monthSheet,
                    options: [for (var m = 1; m <= 12; m++) m],
                    labelOf: _monthName,
                  );
                  if (picked != null) form.setMonth(picked);
                },
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: ScanSelectField(
                label: '',
                placeholder: SystemsCopy.year,
                value: form.year?.toString(),
                fromScan: form.yearFromScan(),
                onTap: () async {
                  final picked = await pickOption<int>(
                    context,
                    title: SystemsCopy.yearSheet,
                    options: _years(),
                    labelOf: (y) => '$y',
                  );
                  if (picked != null) form.setYear(picked);
                },
              ),
            ),
          ],
        ),
        LifespanSlider(
          years: form.life,
          help: SystemsCopy.lifeHelp(form.category, form.replaceYear),
          onChanged: form.setLife,
        ),
        if (showTasksSwitch)
          Opacity(
            opacity: online ? 1 : AuroraOpacity.disabled,
            child: AuroraToggleRow(
              label: SystemsCopy.addTasks,
              helperText: form.addTasks
                  ? SystemDefaults.tasksMeta(form.category)
                  : SystemsCopy.addTasksOff,
              value: form.addTasks,
              onChanged: (on) {
                if (on && !online) {
                  onOfflineTasks();
                  return;
                }
                form.setAddTasks(on);
              },
            ),
          ),
      ],
    );
  }
}
