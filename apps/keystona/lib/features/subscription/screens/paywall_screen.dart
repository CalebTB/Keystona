import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';

/// Keystona Pro paywall — custom-built UI that fetches offerings directly
/// from RevenueCat without using RevenueCatUI.
///
/// Layout: hero → feature list → package selector → CTA → restore → legal.
/// Default selection: Yearly (index 1).
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  // ─── State ──────────────────────────────────────────────────────────────────

  List<Package> _packages = [];
  int _selectedIndex = 1; // Default: Yearly
  bool _isLoading = false;
  bool _isLoadingOfferings = true;
  String? _offeringsError;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  // ─── Data ───────────────────────────────────────────────────────────────────

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
      for (final type in [
        PackageType.monthly,
        PackageType.annual,
      ]) {
        final match = available.where((p) => p.packageType == type);
        sorted.addAll(match);
      }
      // Append any remaining packages not in the canonical order.
      for (final p in available) {
        if (!sorted.contains(p)) sorted.add(p);
      }

      if (mounted) {
        setState(() {
          _packages = sorted;
          // Default to Yearly (index 1) if available, otherwise 0.
          _selectedIndex = sorted.length > 1 ? 1 : 0;
          _isLoadingOfferings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offeringsError = 'Unable to load subscription options. Please check your connection and try again.';
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: Stack(
        children: [
          // Gradient background: deep navy at top → warm off-white at bottom.
          _GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _CloseButton(onClose: () => context.pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSizes.lg),
                        const _HeroSection(),
                        const SizedBox(height: AppSizes.xl),
                        const _FeatureList(),
                        const SizedBox(height: AppSizes.xl),
                        _PackageSection(
                          isLoading: _isLoadingOfferings,
                          error: _offeringsError,
                          packages: _packages,
                          selectedIndex: _selectedIndex,
                          onRetry: _loadOfferings,
                          onSelected: (i) => setState(() => _selectedIndex = i),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _CtaButton(
                          packages: _packages,
                          selectedIndex: _selectedIndex,
                          isLoading: _isLoading,
                          isLoadingOfferings: _isLoadingOfferings,
                          onPressed: _purchase,
                        ),
                        const SizedBox(height: AppSizes.md),
                        _RestoreButton(
                          isLoading: _isLoading,
                          onPressed: _restorePurchases,
                        ),
                        const SizedBox(height: AppSizes.md),
                        const _LegalFooter(),
                        const SizedBox(height: AppSizes.xl),
                      ],
                    ),
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

// ─── Gradient background ─────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.45, 1.0],
          colors: [
            AppColors.deepNavy,
            Color(0xFF2C3E60), // Mid-blend between navy and off-white.
            AppColors.warmOffWhite,
          ],
        ),
      ),
    );
  }
}

// ─── Close button ────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSizes.sm,
          right: AppSizes.md,
        ),
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: const Icon(
              Icons.close,
              color: AppColors.textInverse,
              size: AppSizes.iconMd,
            ),
          ),
        ),
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
        // Gold home icon in a navy circle.
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: AppColors.goldAccent.withAlpha(100),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: AppColors.goldAccent,
            size: 44,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          'Keystona Pro',
          textAlign: TextAlign.center,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'The smart way to manage your home,\nunlocked in full.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white.withAlpha(200),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Feature list ─────────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const List<_Feature> _features = [
    _Feature(icon: Icons.folder_open_rounded, label: 'Unlimited document storage'),
    _Feature(icon: Icons.document_scanner_rounded, label: 'AI-powered document scanning'),
    _Feature(icon: Icons.event_repeat_rounded, label: 'Advanced maintenance scheduling'),
    _Feature(icon: Icons.favorite_rounded, label: 'Home health score tracking'),
    _Feature(icon: Icons.emergency_rounded, label: 'Emergency hub & utility shutoffs'),
    _Feature(icon: Icons.support_agent_rounded, label: 'Priority support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: Colors.white.withAlpha(30),
        ),
      ),
      child: Column(
        children: _features
            .map((f) => _FeatureRow(feature: f))
            .toList(growable: false),
      ),
    );
  }
}

class _Feature {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs + 2),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.goldAccent,
              size: AppSizes.iconSm,
            ),
          ),
          const SizedBox(width: AppSizes.sm + 4),
          Expanded(
            child: Text(
              feature.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textInverse,
              ),
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
          padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
          child: CupertinoActivityIndicator(color: AppColors.goldAccent),
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
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
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
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try Again',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Selection indicator.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.goldAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: isSelected ? AppColors.goldAccent : AppColors.gray400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.deepNavy,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: AppSizes.md),
                // Labels.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _periodLabel,
                        style: AppTextStyles.h4.copyWith(
                          color: isSelected
                              ? AppColors.textInverse
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_savingsNote != null) ...[
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          _savingsNote!,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Price.
                Text(
                  package.storeProduct.priceString,
                  style: AppTextStyles.bodyLargeSemibold.copyWith(
                    color: isSelected
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            // "Best Value" badge on the Yearly card.
            if (_isYearly)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'Best Value',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w700,
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

// ─── CTA button ──────────────────────────────────────────────────────────────

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
    final pkg = packages[selectedIndex];
    // Check for iOS intro offer or Android free trial.
    return pkg.storeProduct.introductoryPrice != null;
  }

  String get _ctaLabel {
    if (packages.isEmpty) return 'Get Pro';
    return _hasIntroOffer ? 'Start Free Trial' : 'Get Pro';
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && !isLoadingOfferings && packages.isNotEmpty;

    return SizedBox(
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepNavy,
          disabledBackgroundColor: AppColors.gray300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CupertinoActivityIndicator(color: AppColors.goldAccent)
            : Text(
                _ctaLabel,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.goldAccent,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

// ─── Restore button ───────────────────────────────────────────────────────────

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        child: Text(
          'Restore Purchases',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
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
      style: AppTextStyles.caption.copyWith(
        color: AppColors.gray500,
        fontSize: 10,
      ),
    );
  }
}
