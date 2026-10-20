import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_button.dart';
import '../../../models/document_ocr.dart';
import '../../../providers/scan_reading_provider.dart';
import 'reading_step_row.dart';

/// "Reading your document…": progress, the four steps with what each found,
/// and the way out (kit: DocReading).
class DocumentReadingCard extends StatelessWidget {
  const DocumentReadingCard({
    super.key,
    required this.reading,
    required this.pageCount,
    required this.onCheck,
    required this.onBackground,
    required this.onRetry,
    required this.onSkip,
  });

  final ScanReadingState reading;
  final int pageCount;

  /// "Check what we found": the reader finished.
  final VoidCallback onCheck;

  /// "Keep going in the background".
  final VoidCallback onBackground;

  /// Read again after a failure.
  final VoidCallback onRetry;

  /// Carry on without the reader's help after a failure.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final failed = reading.isFailed;
    return Semantics(
      container: true,
      label: 'Reading your document',
      child: Container(
        padding: a.all(AuroraSpacing.space8),
        decoration: const BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.modal,
          boxShadow: AuroraCameraShadows.readingCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Eyebrow(
              pageCount: pageCount,
              percent: failed ? null : reading.percent,
            ),
            SizedBox(height: a.of(AuroraSpacing.space7)),
            Text(_title(), style: AuroraSharedType.stateTitle),
            SizedBox(height: a.of(AuroraSpacing.space7)),
            if (failed) ...[
              Text(
                'You can still add it and fill in the details yourself.',
                style: AuroraSharedType.stateBody,
              ),
              SizedBox(height: a.of(AuroraSpacing.space7)),
              PrimaryButton(
                label: 'Try again',
                expand: true,
                onPressed: onRetry,
              ),
              SizedBox(height: a.of(AuroraSpacing.space5)),
              SecondaryButton(
                label: 'Fill it in myself',
                expand: true,
                onPressed: onSkip,
              ),
            ] else ...[
              _ProgressBar(
                percent: reading.percent,
                fraction: reading.fraction,
              ),
              SizedBox(height: a.of(AuroraSpacing.space7)),
              for (final stage in OcrStage.values) ...[
                ReadingStepRow(
                  title: stage.label,
                  state: _stateOf(stage),
                  found: _foundFor(stage),
                ),
                SizedBox(height: a.of(AuroraSpacing.space5)),
              ],
              SizedBox(height: a.of(AuroraSpacing.space3)),
              if (reading.isDone)
                PrimaryButton(
                  label: 'Check what we found',
                  expand: true,
                  onPressed: onCheck,
                )
              else
                SecondaryButton(
                  label: 'Keep going in the background',
                  expand: true,
                  onPressed: onBackground,
                ),
            ],
            SizedBox(height: a.of(AuroraSpacing.space7)),
            Text(
              'USUALLY UNDER 10 SECONDS · NOTHING IS SAVED UNTIL YOU CHECK IT',
              textAlign: TextAlign.center,
              style: AuroraType.helper,
            ),
          ],
        ),
      ),
    );
  }

  String _title() {
    if (reading.isFailed) return "We couldn't read that one";
    if (reading.isDone) return 'Found ${reading.result.detailCount} details';
    return 'Reading your document…';
  }

  ReadingStepState _stateOf(OcrStage stage) {
    if (stage.index < reading.completed) return ReadingStepState.done;
    if (stage.index == reading.completed) return ReadingStepState.active;
    return ReadingStepState.pending;
  }

  String? _foundFor(OcrStage stage) {
    final r = reading.result;
    return switch (stage) {
      OcrStage.readingText => r.textSummary,
      OcrStage.classifying => r.categoryName,
      OcrStage.findingDates =>
        r.expirationDate == null
            ? null
            : 'Expires ${DateFormat.yMMMd().format(r.expirationDate!)}',
      OcrStage.matching => r.link?.summary,
    };
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.pageCount, required this.percent});

  final int pageCount;
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final pages = '$pageCount ${pageCount == 1 ? 'PAGE' : 'PAGES'}';
    return Row(
      children: [
        Expanded(
          child: Text(
            '★ SMART SCAN · $pages',
            style: AuroraType.label.copyWith(
              color: AuroraColors.coralDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (percent != null)
          Text(
            '$percent%',
            style: AuroraType.label.copyWith(
              color: AuroraColors.cobalt,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent, required this.fraction});

  final int percent;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      label: 'Reading progress',
      value: '$percent%',
      child: Container(
        height: a.of(AuroraUploadSizes.readingBar),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.bar,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: ClipRRect(
          borderRadius: AuroraRadius.bar,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: const ColoredBox(color: AuroraColors.cobalt),
            ),
          ),
        ),
      ),
    );
  }
}
