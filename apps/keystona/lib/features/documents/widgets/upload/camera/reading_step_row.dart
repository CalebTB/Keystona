import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';

enum ReadingStepState { pending, active, done }

/// One line on the reading card: a status dot, the step, and what it found.
class ReadingStepRow extends StatelessWidget {
  const ReadingStepRow({
    super.key,
    required this.title,
    required this.state,
    this.found,
  });

  final String title;
  final ReadingStepState state;

  /// What this step found, shown under the title once it is done.
  final String? found;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final dim = state == ReadingStepState.pending;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Dot(state: state),
        SizedBox(width: a.of(AuroraSpacing.space5)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AuroraType.button.copyWith(
                  fontWeight: state == ReadingStepState.active
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: dim ? AuroraColors.inkPlaceholder : AuroraColors.ink,
                ),
              ),
              if (state == ReadingStepState.done && found != null) ...[
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(
                  found!,
                  style: AuroraType.chip.copyWith(color: AuroraColors.cobalt),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state});

  final ReadingStepState state;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final side = a.of(AuroraUploadSizes.stepDot);
    return Semantics(
      label: switch (state) {
        ReadingStepState.done => 'Done',
        ReadingStepState.active => 'In progress',
        ReadingStepState.pending => 'Waiting',
      },
      child: switch (state) {
        ReadingStepState.done => Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.lime,
            border: Border.all(
              color: AuroraColors.olive,
              width: AuroraBorders.emphasis,
            ),
          ),
          child: Icon(
            Icons.check,
            size: a.of(AuroraUploadSizes.stepCheck),
            color: AuroraColors.olive,
          ),
        ),
        ReadingStepState.active => SizedBox(
          width: side,
          height: side,
          child: const CircularProgressIndicator(
            strokeWidth: AuroraUploadSizes.stepSpinnerStroke,
            color: AuroraColors.cobalt,
          ),
        ),
        ReadingStepState.pending => Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AuroraColors.inkBorderStrong,
              width: AuroraBorders.emphasis,
            ),
          ),
        ),
      },
    );
  }
}
