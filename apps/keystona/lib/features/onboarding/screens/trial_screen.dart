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
import '../../../core/widgets/aurora/aurora_chip.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/onb_plans.dart';
import '../models/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onb_parts.dart';
import '../widgets/onb_scaffold.dart';

/// OnbTrial (1.9): the 30-day free month. RevenueCat is mocked: starting the
/// trial succeeds without a purchase (see [MockTrialStarter]).
class TrialScreen extends ConsumerStatefulWidget {
  const TrialScreen({super.key});

  @override
  ConsumerState<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends ConsumerState<TrialScreen> {
  static const List<_Benefit> _benefits = [
    _Benefit(
      Icons.document_scanner_outlined,
      'Scan your furnace label in 5 seconds',
      'Smart scan fills in brand, model and serial for you.',
    ),
    _Benefit(
      Icons.all_inclusive,
      'No limits',
      'Every document, project and contact you’ll ever add.',
    ),
    _Benefit(
      Icons.assignment_outlined,
      'The Home History Report',
      'Your home’s record as a PDF — worth a lot when you sell.',
    ),
  ];

  OnbPlan _plan = OnbPlan.yearly;
  bool _starting = false;
  bool _skipping = false;

  bool get _busy => _starting || _skipping;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboardingProperty);
    }
  }

  Future<void> _start() async {
    final starter = ref.read(trialStarterProvider);
    final progress = ref.read(onboardingProgressProvider.notifier);
    setState(() => _starting = true);
    try {
      await starter.startTrial(_plan);
      await progress.setTrialStarted();
    } catch (_) {
      if (!mounted) return;
      setState(() => _starting = false);
      SnackbarService.showError(
        context,
        'Could not start your free month. Please try again.',
      );
      return;
    }
    await _finish();
  }

  Future<void> _skip() async {
    setState(() => _skipping = true);
    await _finish();
  }

  /// Marks onboarding complete (a failure does not block) and opens the
  /// checklist.
  Future<void> _finish() async {
    final repository = ref.read(onboardingRepositoryProvider);
    final progress = ref.read(onboardingProgressProvider.notifier);
    var saved = true;
    try {
      await repository.completeOnboarding();
    } catch (_) {
      saved = false;
    }
    await progress.reachStage(OnbStage.checklist);
    if (!mounted) return;
    setState(() {
      _starting = false;
      _skipping = false;
    });
    if (!saved) {
      SnackbarService.showError(
        context,
        'Could not save setup status. You can always set up later.',
      );
    }
    context.go(AppRoutes.onboardingChecklist);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final clock = ref.watch(onboardingClockProvider);
    final endDate = DateFormat.MMMd().format(OnbPlans.trialEnd(clock()));
    return OnbScaffold(
      step: 3,
      onBack: _busy ? null : _back,
      content: [
        OnbHeader(
          badge: Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusChip(
              label: '★ Premium · ${OnbPlans.trialDays} days free',
              background: AuroraColors.coral,
              foreground: AuroraColors.paper,
            ),
          ),
          title: 'Try everything free for a month.',
          subtitle:
              'Setting up is when Premium helps most. Keep it or not — what you add stays yours.',
        ),
        Column(
          spacing: a.of(AuroraSpacing.space6),
          children: [for (final b in _benefits) _BenefitRow(b)],
        ),
        Semantics(
          container: true,
          label: 'Plan',
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: a.of(AuroraSpacing.space3),
              children: [
                Expanded(
                  child: _PlanCard(
                    name: 'Yearly',
                    price: OnbPlans.yearlyPrice,
                    sub: OnbPlans.yearlyPerMonth,
                    saveBadge: 'Save 33%',
                    selected: _plan == OnbPlan.yearly,
                    onTap: () => setState(() => _plan = OnbPlan.yearly),
                  ),
                ),
                Expanded(
                  child: _PlanCard(
                    name: 'Monthly',
                    price: OnbPlans.monthlyPrice,
                    sub: 'Cancel any time',
                    selected: _plan == OnbPlan.monthly,
                    onTap: () => setState(() => _plan = OnbPlan.monthly),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      footer: [
        OnbCta(
          label: 'Start my free month',
          onPressed: _busy ? null : _start,
          loading: _starting,
        ),
        Padding(
          padding: EdgeInsets.only(top: a.of(AuroraSpacing.space1)),
          child: Text(
            OnbPlans.finePrint(_plan, endDate),
            textAlign: TextAlign.center,
            style: AuroraOnbType.finePrint,
          ),
        ),
        OnbTextLink(
          label: 'Not now — start on Free',
          onTap: _busy ? null : _skip,
        ),
      ],
    );
  }
}

class _Benefit {
  const _Benefit(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow(this.benefit);

  final _Benefit benefit;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: a.of(AuroraSpacing.space5),
      children: [
        Container(
          width: a.of(AuroraOnbSizes.benefitTile),
          height: a.of(AuroraOnbSizes.benefitTile),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.tile,
            border: Border.all(
              color: AuroraColors.coral,
              width: AuroraBorders.emphasis,
            ),
          ),
          child: ExcludeSemantics(
            child: Icon(
              benefit.icon,
              size: a.of(AuroraOnbSizes.benefitGlyph),
              color: AuroraColors.coral,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: a.of(AuroraSpacing.space1),
            children: [
              Text(benefit.title, style: AuroraOnbType.itemTitle),
              Text(benefit.body, style: AuroraOnbType.itemBody),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.saveBadge,
  });

  final String name;
  final String price;
  final String sub;
  final String? saveBadge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return OnbChoiceCard(
      selected: selected,
      onTap: onTap,
      selectedColor: AuroraColors.ink,
      semanticLabel: '$name, $price',
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: a.of(AuroraSpacing.space1),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: a.of(AuroraSpacing.space2),
            runSpacing: a.of(AuroraSpacing.space1),
            children: [
              Text(name, style: AuroraOnbType.itemTitle),
              if (saveBadge != null) StatusChip.done(label: saveBadge!),
            ],
          ),
          Text(price, style: AuroraOnbType.planPrice),
          Text(sub.toUpperCase(), style: AuroraType.meta),
        ],
      ),
    );
  }
}
