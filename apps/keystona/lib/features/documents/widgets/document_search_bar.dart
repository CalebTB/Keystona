import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';

/// Adaptive search bar for the Document Vault.
///
/// - iOS: [CupertinoSearchTextField] with the system appearance.
/// - Android: styled [TextField] with a leading search icon.
///
/// Debounces input by 300 ms before calling [onChanged].
/// Shows a gold ✦ PRO badge as a suffix for free-tier users, indicating that
/// full-text OCR search is a Premium feature.
class DocumentSearchBar extends ConsumerStatefulWidget {
  const DocumentSearchBar({
    super.key,
    required this.onChanged,
  });

  /// Called with the trimmed query after the 300 ms debounce, or with null
  /// when the field is cleared.
  final void Function(String? query) onChanged;

  @override
  ConsumerState<DocumentSearchBar> createState() => _DocumentSearchBarState();
}

class _DocumentSearchBarState extends ConsumerState<DocumentSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();
      widget.onChanged(trimmed.isEmpty ? null : trimmed);
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onChanged(null);
  }

  Future<void> _showOcrUpgradeSheet(BuildContext context) async {
    await UpgradeSheet.show(
      context,
      config: const UpgradeSheetConfig(
        headline: 'Unlock Full-Text Search',
        reason: 'Free accounts can search by name and category only.',
        features: [
          'Search inside every document with OCR',
          'Find any text across your entire vault',
          'Instant results with highlighted snippets',
        ],
        triggerKey: 'ocr_search',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final searchBar = isIOS
        ? _IOSSearchBar(
            controller: _controller,
            isPremium: isPremium,
            onChanged: _onTextChanged,
            onClear: _clear,
          )
        : _AndroidSearchBar(
            controller: _controller,
            isPremium: isPremium,
            onChanged: _onTextChanged,
            onClear: _clear,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.xs,
      ),
      // For free users, absorb taps on the search field and show upgrade sheet.
      child: !isPremium
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showOcrUpgradeSheet(context),
              child: IgnorePointer(child: searchBar),
            )
          : searchBar,
    );
  }
}

// ── iOS ───────────────────────────────────────────────────────────────────────

class _IOSSearchBar extends StatelessWidget {
  const _IOSSearchBar({
    required this.controller,
    required this.isPremium,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isPremium;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoSearchTextField(
            controller: controller,
            placeholder: 'Search documents',
            onChanged: onChanged,
            onSuffixTap: onClear,
          ),
        ),
        if (!isPremium) ...[
          const SizedBox(width: AppSizes.sm),
          const _ProBadge(),
        ],
      ],
    );
  }
}

// ── Android ───────────────────────────────────────────────────────────────────

class _AndroidSearchBar extends StatelessWidget {
  const _AndroidSearchBar({
    required this.controller,
    required this.isPremium,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isPremium;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search documents',
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textSecondary, size: AppSizes.iconMd),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPremium) const _ProBadge(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textSecondary, size: AppSizes.iconMd),
                  onPressed: onClear,
                );
              },
            ),
          ],
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(vertical: AppSizes.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: const BorderSide(color: AppColors.deepNavy),
        ),
      ),
    );
  }
}

// ── PRO badge ─────────────────────────────────────────────────────────────────

/// Small gold badge indicating OCR search is a Premium feature.
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.goldAccent.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppColors.goldAccent,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            'PRO',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.goldAccent,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
