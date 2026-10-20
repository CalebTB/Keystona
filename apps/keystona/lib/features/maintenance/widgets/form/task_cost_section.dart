import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../models/task_draft.dart';
import '../../task_form_copy.dart';

/// Cost (optional): the estimate with a "$" in front, and tools and supplies.
class TaskCostSection extends StatelessWidget {
  const TaskCostSection({
    super.key,
    required this.draft,
    required this.costController,
    required this.suppliesController,
    required this.onChanged,
  });

  final TaskDraft draft;
  final TextEditingController costController;
  final TextEditingController suppliesController;
  final ValueChanged<TaskDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final estimate = _EstimateField(
      controller: costController,
      error: draft.costError,
      onChanged: (v) => onChanged(draft.copyWith(cost: v)),
    );
    final supplies = AuroraTextField(
      label: TaskFormCopy.suppliesLabel,
      controller: suppliesController,
      hintText: TaskFormCopy.suppliesPlaceholder,
      onChanged: (v) => onChanged(draft.copyWith(supplies: v)),
    );
    return AuroraFormSection(
      title: TaskFormCopy.costTitle,
      isOptional: true,
      children: [
        a.textScale > AuroraTasksCRatios.stackTextScale
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  estimate,
                  SizedBox(height: a.of(AuroraSpacing.space6)),
                  supplies,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: AuroraTasksCRatios.estimateFlex,
                    child: estimate,
                  ),
                  SizedBox(width: a.of(AuroraSpacing.space4)),
                  Expanded(flex: AuroraTasksCRatios.toolsFlex, child: supplies),
                ],
              ),
      ],
    );
  }
}

class _EstimateField extends StatelessWidget {
  const _EstimateField({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuroraFieldLabel(
          label: TaskFormCopy.estimateLabel,
          isRequired: false,
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        AuroraFieldBox(
          error: error != null,
          child: Row(
            children: [
              Text(
                TaskFormCopy.costPrefix,
                style: AuroraType.input.copyWith(color: AuroraColors.inkSubtle),
              ),
              SizedBox(width: a.of(AuroraSpacing.space1)),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onChanged,
                  style: AuroraType.input.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  cursorColor: AuroraColors.cobalt,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: TaskFormCopy.costPlaceholder,
                    hintStyle: AuroraType.input.copyWith(
                      color: AuroraColors.inkPlaceholder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space2)),
          AuroraFieldHelper(text: error!, isError: true),
        ],
      ],
    );
  }
}
