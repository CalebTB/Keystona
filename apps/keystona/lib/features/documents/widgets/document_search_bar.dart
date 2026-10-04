import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
            onProBadgeTap: isPremium ? null : () => _showOcrUpgradeSheet(context),
          )
        : _AndroidSearchBar(
            controller: _controller,
            isPremium: isPremium,
            onChanged: _onTextChanged,
            onClear: _clear,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.space5,
        AuroraSpacing.space3,
        AuroraSpacing.space5,
        AuroraSpacing.space1,
      ),
      child: searchBar,
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
    this.onProBadgeTap,
  });

  final TextEditingController controller;
  final bool isPremium;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final VoidCallback? onProBadgeTap;

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
          const SizedBox(width: AuroraSpacing.space3),
          GestureDetector(
            onTap: onProBadgeTap,
            child: const _ProBadge(),
          ),
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
      style: AuroraType.body,
      decoration: InputDecoration(
        hintText: 'Search documents',
        hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
        prefixIcon: Icon(
          Icons.search,
          color: AuroraColors.inkSecondary,
          size: 20,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPremium) const _ProBadge(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AuroraColors.inkSecondary,
                    size: 20,
                  ),
                  onPressed: onClear,
                );
              },
            ),
          ],
        ),
        filled: true,
        fillColor: AuroraColors.paper,
        contentPadding:
            const EdgeInsets.symmetric(vertical: AuroraSpacing.space3),
        border: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.inkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.inkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.ink),
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
        horizontal: AuroraSpacing.space3,
        vertical: AuroraSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.yellow.withAlpha(25),
        borderRadius: AuroraRadius.full,
        border: Border.all(color: AuroraColors.yellow.withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AuroraColors.yellow,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            'PRO',
            style: AuroraType.labelSm.copyWith(
              color: AuroraColors.yellowDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
