import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';

// Colors.white is used intentionally in two places: the white icon on the coral
// hero circle, the white check icon on the coral radio dot, and the "BEST VALUE"
// badge text on coral. All other surfaces use Aurora ink tokens.

/// Keystona Pro paywall — custom-built UI that fetches offerings directly
/// from RevenueCat without using RevenueCatUI.
///
/// Layout: paper bg → header bar (RESTORE left, × right) → hero → top CTA →
///         feature list → legal → package selector → bottom "Get started" CTA.
/// Default selection: Yearly (index 1).
///
/// Design: clean white paper background, coral PrimaryButton for top CTA,
/// cobalt SaveButton for bottom CTA, ink text throughout.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  // ─── State ───────────────────────────────────────────────────────────────────

  List<Package> _packages = [];
  int _selectedIndex = 1; // Default: Yearly
  bool _isLoading = false;
  bool _isLoadingOfferings = true;
  String? _offeringsError;

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  // ─── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
      _offeringsError = null;
    });

    try {
      final offerings = await Purchases.getOfferings();
      final available = offerings.current?.availablePackages ?? [];

      // Sort into canonical order: Monthly → Yearly.
      final sorted = <Package>[];
      for (final type in [PackageType.monthly, PackageType.annual]) {
        final match = available.where((p) => p.packageType == type);
        sorted.addAll(match);
      }
      for (final p in available) {
        if (!sorted.contains(p)) sorted.add(p);
      }

      if (mounted) {
        setState(() {
          _packages = sorted;
          _selectedIndex = sorted.length > 1 ? 1 : 0;
          _isLoadingOfferings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offeringsError =
              'Unable to load subscription options. Please check your connection and try again.';
          _isLoadingOfferings = false;
        });
      }
    }
  }

  Future<void> _purchase() async {
    if (_packages.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final purchaseParams = PurchaseParams.package(_packages[_selectedIndex]);
      await Purchases.purchase(purchaseParams);
      if (mounted) {
        SnackbarService.showSuccess(context, 'Welcome to Keystona Pro!');
        context.pop();
      }
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        // User cancelled — no feedback needed.
      } else {
        if (mounted) {
          SnackbarService.showError(context, e.message);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      await Purchases.restorePurchases();
      if (mounted) {
        SnackbarService.showSuccess(context, 'Purchases restored successfully.');
        context.pop();
      }
    } on PurchasesError catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              onClose: () => context.pop(),
              onRestore: _restorePurchases,
              isLoading: _isLoading,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.screenPadH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AuroraSpacing.space8),
                    const _HeroSection(),
                    const SizedBox(height: AuroraSpacing.space7),
                    _CtaButton(
                      packages: _packages,
                      selectedIndex: _selectedIndex,
                      isLoading: _isLoading,
                      isLoadingOfferings: _isLoadingOfferings,
                      onPressed: _purchase,
                    ),
                    const SizedBox(height: AuroraSpacing.space10),
                    const _FeatureList(),
                    const SizedBox(height: AuroraSpacing.space7),
                    const _LegalFooter(),
                    const SizedBox(height: AuroraSpacing.space9),
                    _PackageSection(
                      isLoading: _isLoadingOfferings,
                      error: _offeringsError,
                      packages: _packages,
                      selectedIndex: _selectedIndex,
                      onRetry: _loadOfferings,
                      onSelected: (i) => setState(() => _selectedIndex = i),
                    ),
                    const SizedBox(height: AuroraSpacing.space7),
                    SaveButton(
                      label: 'Get started',
                      onPressed: (_isLoading || _isLoadingOfferings || _packages.isEmpty)
                          ? null
                          : _purchase,
                      loading: _isLoading,
                      expand: true,
                    ),
                    const SizedBox(height: AuroraSpacing.space10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header bar (Restore left · Close right) ─────────────────────────────────

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.onClose,
    required this.onRestore,
    required this.isLoading,
  });

  final VoidCallback onClose;
  final VoidCallback onRestore;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: isLoading ? null : onRestore,
            child: Text(
              'RESTORE',
              style: AuroraType.label.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AuroraColors.butter,
                borderRadius: AuroraRadius.full,
              ),
              child: const Icon(
                Icons.close,
                color: AuroraColors.ink,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Coral circle with yellow blob — one coral hero per screen.
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Yellow blob accent
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AuroraColors.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AuroraColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.white, // intentional: white icon on coral surface
                  size: 38,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AuroraSpacing.space7),
        Text(
          'Keystona Pro',
          textAlign: TextAlign.center,
          style: AuroraType.h1.copyWith(color: AuroraColors.ink),
        ),
        const SizedBox(height: AuroraSpacing.space3),
        Text(
          'The smart way to manage your home,\nunlocked in full.',
          textAlign: TextAlign.center,
          style: AuroraType.bodyLg.copyWith(
            color: AuroraColors.inkSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Feature list ─────────────────────────────────────────────────────────────

/// Copy-driven feature list — no icons, two-line rows separated by Dividers.
/// Small coral check circle is the only visual element per row.
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const List<({String headline, String description})> _features = [
    (
      headline: 'Unlimited document storage',
      description: 'Warranties, manuals, receipts — all in one place',
    ),
    (
      headline: 'AI document scanning',
      description: 'Snap a photo and we extract the details automatically',
    ),
    (
      headline: 'Smart maintenance scheduling',
      description: 'Never miss a service reminder for your home again',
    ),
    (
      headline: 'Home health score',
      description: "Track your property's condition over time",
    ),
    (
      headline: 'Emergency hub',
      description:
          'Utility shutoffs and emergency contacts always at your fingertips',
    ),
    (
      headline: 'Priority support',
      description: 'Get help from our team when you need it most',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _features.length; i++) ...[
          _FeatureRow(feature: _features[i]),
          if (i < _features.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              color: AuroraColors.inkBorder,
            ),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final ({String headline, String description}) feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.space5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small coral check circle — 14px, top-aligned with headline.
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AuroraColors.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white, // intentional: white icon on coral surface
                size: 10,
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.headline,
                  style: AuroraType.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Package selector ─────────────────────────────────────────────────────────

class _PackageSection extends StatelessWidget {
  const _PackageSection({
    required this.isLoading,
    required this.error,
    required this.packages,
    required this.selectedIndex,
    required this.onRetry,
    required this.onSelected,
  });

  final bool isLoading;
  final String? error;
  final List<Package> packages;
  final int selectedIndex;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AuroraSpacing.space9),
          child: CupertinoActivityIndicator(color: AuroraColors.coral),
        ),
      );
    }

    if (error != null) {
      return _PackageError(message: error!, onRetry: onRetry);
    }

    if (packages.isEmpty) {
      return _PackageError(
        message: 'No subscription options available at this time.',
        onRetry: onRetry,
      );
    }

    return Column(
      children: List.generate(
        packages.length,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
          child: _PackageCard(
            package: packages[i],
            index: i,
            isSelected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
        ),
      ),
    );
  }
}

class _PackageError extends StatelessWidget {
  const _PackageError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.xl,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AuroraType.body.copyWith(color: AuroraColors.ink),
          ),
          const SizedBox(height: AuroraSpacing.space7),
          GhostButton(
            label: 'Try Again',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Plan picker pill.
///
/// Selected: paper bg + coral 2px border.
/// Unselected: butter bg + inkBorder 1px border.
class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final Package package;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  bool get _isYearly => package.packageType == PackageType.annual;

  String get _periodLabel {
    return switch (package.packageType) {
      PackageType.monthly => 'Monthly',
      PackageType.annual => 'Yearly',
      _ => package.identifier,
    };
  }

  String? get _savingsNote {
    if (_isYearly) return 'Save ~17% vs monthly';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AuroraSpacing.space7),
        decoration: BoxDecoration(
          color: isSelected ? AuroraColors.paper : AuroraColors.butter,
          borderRadius: AuroraRadius.xl,
          border: Border.all(
            color: isSelected ? AuroraColors.coral : AuroraColors.inkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AuroraColors.coral
                        : Colors.transparent,
                    borderRadius: AuroraRadius.full,
                    border: Border.all(
                      color: isSelected
                          ? AuroraColors.coral
                          : AuroraColors.inkBorderStrong,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white, // intentional: white check on coral radio
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: AuroraSpacing.space7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _periodLabel,
                        style: AuroraType.h3.copyWith(
                          color: AuroraColors.ink,
                        ),
                      ),
                      if (_savingsNote != null) ...[
                        const SizedBox(height: AuroraSpacing.space1),
                        Text(
                          _savingsNote!,
                          style: AuroraType.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AuroraColors.cobalt,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  package.storeProduct.priceString,
                  style: AuroraType.number.copyWith(
                    color: AuroraColors.ink,
                  ),
                ),
              ],
            ),
            // "Best Value" badge on yearly plan
            if (_isYearly)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space3,
                    vertical: AuroraSpacing.space1,
                  ),
                  decoration: const BoxDecoration(
                    color: AuroraColors.coral,
                    borderRadius: AuroraRadius.full,
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: AuroraType.labelSm.copyWith(
                      color: Colors.white, // intentional: white text on coral badge
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── CTA button ───────────────────────────────────────────────────────────────

/// "Start Free Trial" / "Get Pro" — coral PrimaryButton.
/// Purchase is a brand action, not a form save → PrimaryButton is correct.
class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.packages,
    required this.selectedIndex,
    required this.isLoading,
    required this.isLoadingOfferings,
    required this.onPressed,
  });

  final List<Package> packages;
  final int selectedIndex;
  final bool isLoading;
  final bool isLoadingOfferings;
  final VoidCallback onPressed;

  bool get _hasIntroOffer {
    if (packages.isEmpty) return false;
    return packages[selectedIndex].storeProduct.introductoryPrice != null;
  }

  String get _ctaLabel {
    if (packages.isEmpty) return 'Get Pro';
    return _hasIntroOffer ? 'Start Free Trial' : 'Get Pro';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && !isLoadingOfferings && packages.isNotEmpty;
    return PrimaryButton(
      label: _ctaLabel,
      onPressed: enabled ? onPressed : null,
      loading: isLoading,
      expand: true,
    );
  }
}

// ─── Legal footer ─────────────────────────────────────────────────────────────

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Cancel anytime · Prices in USD · Terms & Privacy',
      textAlign: TextAlign.center,
      style: AuroraType.labelSm.copyWith(
        color: AuroraColors.inkTertiary,
      ),
    );
  }
}
