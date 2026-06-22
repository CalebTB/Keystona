import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
      body: Stack(
        children: [
          const _GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _CloseButton(onClose: () => context.pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AuroraSpacing.screenPadH,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AuroraSpacing.space9),
                        const _HeroSection(),
                        const SizedBox(height: AuroraSpacing.space10),
                        const _FeatureList(),
                        const SizedBox(height: AuroraSpacing.space10),
                        _PackageSection(
                          isLoading: _isLoadingOfferings,
                          error: _offeringsError,
                          packages: _packages,
                          selectedIndex: _selectedIndex,
                          onRetry: _loadOfferings,
                          onSelected: (i) => setState(() => _selectedIndex = i),
                        ),
                        const SizedBox(height: AuroraSpacing.space9),
                        _CtaButton(
                          packages: _packages,
                          selectedIndex: _selectedIndex,
                          isLoading: _isLoading,
                          isLoadingOfferings: _isLoadingOfferings,
                          onPressed: _purchase,
                        ),
                        const SizedBox(height: AuroraSpacing.space7),
                        _RestoreButton(
                          isLoading: _isLoading,
                          onPressed: _restorePurchases,
                        ),
                        const SizedBox(height: AuroraSpacing.space7),
                        const _LegalFooter(),
                        const SizedBox(height: AuroraSpacing.space10),
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

// ─── Gradient background ──────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.45, 1.0],
          colors: [
            AuroraColors.ink,
            AuroraColors.cobalt,
            AuroraColors.paper,
          ],
        ),
      ),
    );
  }
}

// ─── Close button ─────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AuroraSpacing.space3,
          right: AuroraSpacing.space7,
        ),
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
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
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AuroraColors.yellow.withAlpha(100),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.home_work_rounded,
            color: AuroraColors.yellow,
            size: 44,
          ),
        ),
        const SizedBox(height: AuroraSpacing.space7),
        Text(
          'Keystona Pro',
          textAlign: TextAlign.center,
          style: AuroraType.h1.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AuroraSpacing.space3),
        Text(
          'The smart way to manage your home,\nunlocked in full.',
          textAlign: TextAlign.center,
          style: AuroraType.bodyLg.copyWith(
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
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AuroraColors.yellow.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AuroraColors.yellow,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.label,
              style: AuroraType.body.copyWith(color: Colors.white),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.space9),
          child: CupertinoActivityIndicator(color: AuroraColors.yellow),
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
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F).withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AuroraType.body.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AuroraSpacing.space7),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AuroraColors.yellow,
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
        padding: const EdgeInsets.all(AuroraSpacing.space7),
        decoration: BoxDecoration(
          color: isSelected ? AuroraColors.ink : AuroraColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AuroraColors.yellow : const Color(0xFFC4C3D0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AuroraColors.yellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AuroraColors.yellow
                          : const Color(0xFFC4C3D0),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: AuroraColors.ink,
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AuroraColors.ink,
                        ),
                      ),
                      if (_savingsNote != null) ...[
                        const SizedBox(height: AuroraSpacing.space1),
                        Text(
                          _savingsNote!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AuroraColors.yellow
                                : AuroraColors.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  package.storeProduct.priceString,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AuroraColors.ink,
                  ),
                ),
              ],
            ),
            if (_isYearly)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space3,
                    vertical: AuroraSpacing.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AuroraColors.yellow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Best Value',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AuroraColors.ink,
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

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuroraColors.coral,
          disabledBackgroundColor: const Color(0xFFE0DFEA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? CupertinoActivityIndicator(color: AuroraColors.yellow)
            : Text(
                _ctaLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AuroraColors.yellow,
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
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AuroraColors.inkSecondary,
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
      style: AuroraType.bodySm.copyWith(
        color: const Color(0xFF9D9BB0),
        fontSize: 10,
      ),
    );
  }
}
