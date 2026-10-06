import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/error_view.dart';
import '../models/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onb_parts.dart';
import '../widgets/onb_scaffold.dart';
import '../widgets/onb_skeletons.dart';

/// OnbPersona (1.6): "Which sounds like you?" Owner continues to the home
/// setup; shopper goes to the saved-homes flow.
class OnbPersonaScreen extends ConsumerWidget {
  const OnbPersonaScreen({super.key});

  static const List<_PersonaOption> _options = [
    _PersonaOption(
      persona: OnboardingPersona.owner,
      title: 'I own a home',
      body:
          'Just bought it, or been there for years. Track what you have and stay ahead of upkeep.',
      meta: 'Systems · Maintenance · Warranties · Projects',
      icon: Icons.vpn_key_outlined,
    ),
    _PersonaOption(
      persona: OnboardingPersona.shopper,
      title: 'I’m shopping for one',
      body:
          'Compare homes you’re touring and keep inspection reports in one place.',
      meta: 'Saved homes · Inspections · What to ask',
      icon: Icons.search,
    ),
  ];

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    OnboardingPersona persona,
  ) async {
    final notifier = ref.read(onboardingProgressProvider.notifier);
    if (persona == OnboardingPersona.owner) {
      await notifier.reachStage(OnbStage.property);
      if (!context.mounted) return;
      context.go(AppRoutes.onboardingProperty);
    } else {
      // Sprint 10 builds the saved-homes flow; until then it is a placeholder.
      context.go(AppRoutes.shopAdd);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(onboardingProgressProvider);
    return progress.when(
      loading: () => OnbScaffold(
        step: 1,
        onBack: () => _back(context),
        content: const [OnbHeaderSkeleton(), OnbCardsSkeleton(count: 2)],
      ),
      error: (_, _) => OnbScaffold(
        step: 1,
        onBack: () => _back(context),
        content: [
          Expanded(
            child: ErrorView(
              message: 'We couldn’t load your setup. Check your connection and try again.',
              onRetry: () => ref.invalidate(onboardingProgressProvider),
            ),
          ),
        ],
      ),
      data: (p) => _Content(
        selected: p.persona,
        onBack: () => _back(context),
        onPick: (v) =>
            ref.read(onboardingProgressProvider.notifier).setPersona(v),
        onContinue: p.persona == null
            ? null
            : () => _continue(context, ref, p.persona!),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.selected,
    required this.onBack,
    required this.onPick,
    required this.onContinue,
  });

  final OnboardingPersona? selected;
  final VoidCallback onBack;
  final ValueChanged<OnboardingPersona> onPick;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    final name = ref.watch(onboardingFirstNameProvider);
    return OnbScaffold(
      step: 1,
      onBack: onBack,
      content: [
        OnbHeader(
          eyebrow: name == null ? 'Welcome' : 'Welcome, $name',
          title: 'Which sounds like you?',
          subtitle: "We'll set things up to match. You can add another home later.",
        ),
        Semantics(
          container: true,
          label: 'Which sounds like you',
          child: Column(
            spacing: a.of(AuroraSpacing.space5),
            children: [
              for (final o in OnbPersonaScreen._options)
                _PersonaCard(
                  option: o,
                  selected: selected == o.persona,
                  onTap: () => onPick(o.persona),
                ),
            ],
          ),
        ),
      ],
      footer: [OnbCta(label: 'Continue', onPressed: onContinue)],
    );
  }
}

class _PersonaOption {
  const _PersonaOption({
    required this.persona,
    required this.title,
    required this.body,
    required this.meta,
    required this.icon,
  });

  final OnboardingPersona persona;
  final String title;
  final String body;
  final String meta;
  final IconData icon;
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PersonaOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return OnbChoiceCard(
      selected: selected,
      onTap: onTap,
      selectedColor: AuroraColors.coral,
      radius: AuroraRadius.banner,
      semanticLabel: option.title,
      padding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraSpacing.space7),
        vertical: a.of(AuroraSpacing.pillH),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: a.of(AuroraSpacing.space6),
        children: [
          Container(
            width: a.of(AuroraOnbSizes.optionTile),
            height: a.of(AuroraOnbSizes.optionTile),
            decoration: BoxDecoration(
              color: selected ? AuroraColors.coral : AuroraColors.paper,
              borderRadius: AuroraRadius.lg,
              border: selected
                  ? null
                  : Border.all(
                      color: AuroraColors.inkInputBorder,
                      width: AuroraBorders.regular,
                    ),
            ),
            child: Icon(
              option.icon,
              size: a.of(AuroraOnbSizes.optionGlyph),
              color: selected ? AuroraColors.paper : AuroraColors.ink,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: a.of(AuroraSpacing.space1),
              children: [
                Text(option.title, style: AuroraOnbType.optionTitle),
                Text(option.body, style: AuroraOnbType.optionBody),
                Text(
                  option.meta.toUpperCase(),
                  style: AuroraOnbType.optionMeta,
                ),
              ],
            ),
          ),
          Container(
            width: a.of(AuroraOnbSizes.radioOuter),
            height: a.of(AuroraOnbSizes.radioOuter),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AuroraColors.coral
                    : AuroraColors.inkCheckBorder,
                width: selected
                    ? AuroraOnbSizes.selectedBorder
                    : AuroraBorders.emphasis,
              ),
            ),
            child: selected
                ? Container(
                    width: a.of(AuroraOnbSizes.radioDot),
                    height: a.of(AuroraOnbSizes.radioDot),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuroraColors.coral,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
