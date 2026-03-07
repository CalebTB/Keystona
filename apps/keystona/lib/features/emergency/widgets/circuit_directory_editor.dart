import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

/// Editable list of circuit breaker entries (breaker number → description).
///
/// Renders one row per entry showing the circuit number and label. The user
/// can add new rows, edit inline, or remove rows. All mutations are reported
/// back to the parent via [onChanged] so the parent owns the canonical state.
///
/// Data model: [Map<String, String>] where key = circuit number string
/// (e.g. "1", "2A") and value = description label (e.g. "Kitchen outlets").
class CircuitDirectoryEditor extends StatefulWidget {
  const CircuitDirectoryEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  /// Starting entries. Not mutated directly — a copy is built internally.
  final Map<String, String> initialValue;

  /// Called whenever the user adds, edits, or removes a circuit entry.
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<CircuitDirectoryEditor> createState() => _CircuitDirectoryEditorState();
}

class _CircuitDirectoryEditorState extends State<CircuitDirectoryEditor> {
  // Maintain a stable ordered list of entries so row order is preserved
  // across add/remove operations.
  late final List<_CircuitEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialValue.entries
        .map((e) => _CircuitEntry(number: e.key, label: e.value))
        .toList();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _notify() {
    final map = <String, String>{
      for (final e in _entries) e.number: e.label,
    };
    widget.onChanged(map);
  }

  void _addEntry() {
    setState(() {
      _entries.add(_CircuitEntry(number: '', label: ''));
    });
    // No _notify() here — empty strings are filtered on save.
  }

  void _removeEntry(int index) {
    final entry = _entries[index];
    setState(() => _entries.removeAt(index));
    entry.dispose();
    _notify();
  }

  void _onNumberChanged(int index, String value) {
    _entries[index].number = value;
    _notify();
  }

  void _onLabelChanged(int index, String value) {
    _entries[index].label = value;
    _notify();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header.
        Text(
          'Circuit Directory',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Add each breaker number and what it controls.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Entry rows.
        if (_entries.isEmpty)
          _EmptyCircuitPlaceholder()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, index) {
              final entry = _entries[index];
              return _CircuitRow(
                numberCtrl: entry.numberCtrl,
                labelCtrl: entry.labelCtrl,
                isIOS: isIOS,
                onNumberChanged: (v) => _onNumberChanged(index, v),
                onLabelChanged: (v) => _onLabelChanged(index, v),
                onRemove: () => _removeEntry(index),
              );
            },
          ),

        const SizedBox(height: AppSizes.sm),

        // Add circuit button.
        _AddCircuitButton(isIOS: isIOS, onPressed: _addEntry),
      ],
    );
  }
}

// ── Circuit row ───────────────────────────────────────────────────────────────

class _CircuitRow extends StatelessWidget {
  const _CircuitRow({
    required this.numberCtrl,
    required this.labelCtrl,
    required this.isIOS,
    required this.onNumberChanged,
    required this.onLabelChanged,
    required this.onRemove,
  });

  final TextEditingController numberCtrl;
  final TextEditingController labelCtrl;
  final bool isIOS;
  final ValueChanged<String> onNumberChanged;
  final ValueChanged<String> onLabelChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circuit number — narrow field.
        SizedBox(
          width: 72,
          child: isIOS
              ? _IOSField(
                  placeholder: '#',
                  controller: numberCtrl,
                  onChanged: onNumberChanged,
                  keyboardType: TextInputType.text,
                )
              : _AndroidField(
                  hint: '#',
                  controller: numberCtrl,
                  onChanged: onNumberChanged,
                ),
        ),
        const SizedBox(width: AppSizes.sm),

        // Label — expands to fill remaining space.
        Expanded(
          child: isIOS
              ? _IOSField(
                  placeholder: 'Description (e.g. Kitchen outlets)',
                  controller: labelCtrl,
                  onChanged: onLabelChanged,
                  keyboardType: TextInputType.text,
                )
              : _AndroidField(
                  hint: 'Description (e.g. Kitchen outlets)',
                  controller: labelCtrl,
                  onChanged: onLabelChanged,
                ),
        ),
        const SizedBox(width: AppSizes.xs),

        // Remove button.
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              Icons.remove,
              size: AppSizes.iconSm,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Platform-specific inline fields ──────────────────────────────────────────

class _IOSField extends StatelessWidget {
  const _IOSField({
    required this.placeholder,
    required this.controller,
    required this.onChanged,
    required this.keyboardType,
  });

  final String placeholder;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      placeholder: placeholder,
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 10,
      ),
      style: AppTextStyles.bodyMedium,
      placeholderStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textDisabled,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }
}

class _AndroidField extends StatelessWidget {
  const _AndroidField({
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          borderSide: BorderSide(color: AppColors.deepNavy),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

// ── Empty placeholder ─────────────────────────────────────────────────────────

class _EmptyCircuitPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.electric_bolt_outlined,
            size: AppSizes.iconSm,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            'No circuits added yet',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add circuit button ────────────────────────────────────────────────────────

class _AddCircuitButton extends StatelessWidget {
  const _AddCircuitButton({required this.isIOS, required this.onPressed});
  final bool isIOS;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.add_circled,
              size: AppSizes.iconSm,
              color: AppColors.deepNavy,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              'Add Circuit',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.deepNavy,
              ),
            ),
          ],
        ),
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.add_circle_outline,
        size: AppSizes.iconSm,
        color: AppColors.deepNavy,
      ),
      label: Text(
        'Add Circuit',
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.deepNavy,
        ),
      ),
    );
  }
}

// ── Data container ────────────────────────────────────────────────────────────

/// Mutable container for a single circuit breaker entry.
///
/// Owns the [TextEditingController]s for the number and label fields so they
/// survive rebuilds. Call [dispose] when removing an entry.
class _CircuitEntry {
  _CircuitEntry({required this.number, required this.label})
      : numberCtrl = TextEditingController(text: number),
        labelCtrl = TextEditingController(text: label);

  String number;
  String label;
  final TextEditingController numberCtrl;
  final TextEditingController labelCtrl;

  void dispose() {
    numberCtrl.dispose();
    labelCtrl.dispose();
  }
}
