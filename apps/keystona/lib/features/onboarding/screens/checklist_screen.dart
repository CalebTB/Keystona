import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_card.dart';
import '../../../core/widgets/aurora/aurora_chip.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_skeleton_card.dart';
import '../models/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onb_parts.dart';
import '../widgets/onb_scaffold.dart';

/// OnbChecklist (1.10): "Your home is on Keystona." and the steps to do first.
/// Steps the user finished stay done, so leaving and coming back resumes where
/// they left off.
class OnbChecklistScreen extends ConsumerWidget {
  const OnbChecklistScreen({super.key});

  static const List<_Step> _steps = [
    _Step(
      ChecklistStep.scan,
      'Scan your systems',
      'Brings in their maintenance reminders.',
      'Furnace, water heater, roof · 3 min',
    ),
    _Step(
      ChecklistStep.shutoffs,
      'Find your shutoffs',
      'Works offline when you need it most.',
      'Water, gas, electric · 2 min',
    ),
    _Step(
      ChecklistStep.document,
      'Add one document',
      'Your inspection report is a great first one.',
      'A warranty or inspection · 1 min',
    ),
    _Step(
      ChecklistStep.household,
      'Invite your household',
      'Everyone sees the same home.',
      'Optional',
    ),
  ];

  /// Where each step opens. Sprint 2+ replaces these with the kit's flows.
  static String routeFor(ChecklistStep step) => switch (step) {
        ChecklistStep.scan => AppRoutes.homeSystemsAdd,
        ChecklistStep.shutoffs => AppRoutes.emergency,
        ChecklistStep.document => AppRoutes.documentsUpload,
        ChecklistStep.household => AppRoutes.settingsHousehold,
      };

  /// Opens [step]. The screen it opens pops `true` when the step is done.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    ChecklistStep step,
  ) async {
    final progress = ref.read(onboardingProgressProvider.notifier);
    final done = await context.push<bool>(routeFor(step));
    if (done == true) await progress.markStepDone(step);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final progressAsync = ref.watch(onboardingProgressProvider);
    final summaryAsync = ref.watch(onbHomeSummaryProvider);

    if (progressAsync.hasError || summaryAsync.hasError) {
      return OnbScaffold(
        content: [
          Expanded(
            child: ErrorView(
              message:
                  'We couldn’t load your home. Check your connection and try again.',
              onRetry: () {
                ref.invalidate(onboardingProgressProvider);
                ref.invalidate(onbHomeSummaryProvider);
              },
            ),
          ),
        ],
      );
    }
    final progress = progressAsync.value;
    if (progress == null || summaryAsync.isLoading) {
      return OnbScaffold(
        content: [
          const _HeroCheck(),
          const _Intro(),
          LoadingSkeletonCard(height: a.of(AuroraOnbSizes.skeletonRowHeight)),
          LoadingSkeletonCard(height: a.of(AuroraOnbSizes.skeletonCardHeight)),
        ],
      );
    }

    final summary = summaryAsync.value;
    final done = progress.doneSteps;
    final next = _steps.where((s) => !done.contains(s.step)).firstOrNull;
    final nothingDone = done.isEmpty;

    return OnbScaffold(
      content: [
        const _HeroCheck(),
        const _Intro(),
        if (summary != null)
          _HomeCard(summary: summary, onTrial: progress.trialStarted),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            const OnbSectionHeader(
              title: 'Do these first',
              trailing: 'About 6 min',
            ),
            OnbRowGroup(
              rows: [
                for (var i = 0; i < _steps.length; i++)
                  _StepRow(
                    number: i + 1,
                    step: _steps[i],
                    done: done.contains(_steps[i].step),
                    active: _steps[i] == next,
                    onTap: () => _open(context, ref, _steps[i].step),
                  ),
              ],
            ),
          ],
        ),
      ],
      footer: [
        if (next == null)
          OnbCta(
            label: 'Go to my home',
            onPressed: () => context.go(AppRoutes.home),
          )
        else ...[
          OnbCta(
            label: nothingDone ? 'Start with my systems' : 'Continue setup',
            onPressed: () => _open(context, ref, next.step),
          ),
          OnbTextLink(
            label: 'Go to my home first',
            onTap: () => context.go(AppRoutes.home),
          ),
        ],
      ],
    );
  }
}

class _Step {
  const _Step(this.step, this.title, this.body, this.meta);

  final ChecklistStep step;
  final String title;
  final String body;
  final String meta;
}

class _HeroCheck extends StatelessWidget {
  const _HeroCheck();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.only(top: a.of(AuroraSpacing.space10)),
        child: Container(
          width: a.of(AuroraOnbSizes.heroCheck),
          height: a.of(AuroraOnbSizes.heroCheck),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.lime,
          ),
          child: ExcludeSemantics(
            child: Icon(
              Icons.check,
              size: a.of(AuroraOnbSizes.heroCheckGlyph),
              color: AuroraColors.olive,
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => const OnbHeader(
        title: 'Your home is on Keystona.',
        subtitle:
            "Here's the quickest way to make it useful. Each one takes a couple of minutes.",
      );
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.summary, required this.onTrial});

  final OnbHomeSummary summary;
  final bool onTrial;

  String get _meta {
    final fmt = NumberFormat.decimalPattern('en_US');
    final zone = summary.climateZone == null
        ? null
        : 'Zone ${summary.climateZone}${summary.climateMoisture ?? ''}';
    return [
      ?summary.kind?.label,
      if (summary.yearBuilt != null) 'Built ${summary.yearBuilt}',
      if (summary.squareFeet != null) '${fmt.format(summary.squareFeet)} sq ft',
      ?zone,
    ].join(' · ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraCard(
      child: Row(
        spacing: a.of(AuroraSpacing.space5),
        children: [
          Container(
            width: a.of(AuroraOnbSizes.homeTile),
            height: a.of(AuroraOnbSizes.homeTile),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.md,
              border: Border.all(
                color: AuroraColors.inkTileBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.home_outlined,
                size: a.of(AuroraOnbSizes.homeTileGlyph),
                color: AuroraColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: a.of(AuroraSpacing.space1),
              children: [
                Text(summary.street, style: AuroraOnbType.homeName),
                if (_meta.isNotEmpty) Text(_meta, style: AuroraType.meta),
              ],
            ),
          ),
          if (onTrial)
            const StatusChip(
              label: '★ Trial',
              background: AuroraColors.coral,
              foreground: AuroraColors.paper,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.step,
    required this.done,
    required this.active,
    required this.onTap,
  });

  final int number;
  final _Step step;
  final bool done;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final ringColor = done
        ? AuroraColors.lime
        : active
            ? AuroraColors.coral
            : AuroraColors.inkCheckBorder;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: done ? '${step.title}, done' : step.title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraOnbSizes.stepRowMinHeight),
        ),
        child: Padding(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          child: Row(
            spacing: a.of(AuroraSpacing.space5),
            children: [
              Container(
                width: a.of(AuroraOnbSizes.stepNumber),
                height: a.of(AuroraOnbSizes.stepNumber),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AuroraColors.lime : AuroraColors.paper,
                  border: done
                      ? null
                      : Border.all(
                          color: ringColor,
                          width: AuroraBorders.emphasis,
                        ),
                ),
                child: done
                    ? Icon(
                        Icons.check,
                        size: a.of(AuroraIconSizes.sm),
                        color: AuroraColors.olive,
                      )
                    : Text(
                        '$number',
                        style: AuroraOnbType.stepNumber.copyWith(
                          color: active ? AuroraColors.coral : AuroraColors.ink,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: a.of(AuroraSpacing.space1),
                  children: [
                    Text(step.title, style: AuroraOnbType.itemTitle),
                    Text(step.body, style: AuroraOnbType.stepBody),
                    Text(step.meta.toUpperCase(), style: AuroraType.meta),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.inkPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
