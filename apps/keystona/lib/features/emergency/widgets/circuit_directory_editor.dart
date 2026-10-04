import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

/// Editable list of circuit breaker entries (breaker number → description).
class CircuitDirectoryEditor extends StatefulWidget {
  const CircuitDirectoryEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final Map<String, String> initialValue;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<CircuitDirectoryEditor> createState() => _CircuitDirectoryEditorState();
}

class _CircuitDirectoryEditorState extends State<CircuitDirectoryEditor> {
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

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Circuit Directory',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AuroraColors.ink,
          ),
        ),
        const SizedBox(height: AuroraSpacing.space1),
        Text(
          'Add each breaker number and what it controls.',
          style: AuroraType.bodySm.copyWith(
            color: AuroraColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AuroraSpacing.space3),

        if (_entries.isEmpty)
          _EmptyCircuitPlaceholder()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AuroraSpacing.space3),
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

        const SizedBox(height: AuroraSpacing.space3),
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
        const SizedBox(width: AuroraSpacing.space3),

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
        const SizedBox(width: AuroraSpacing.space1),

        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AuroraColors.coral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.remove,
              size: 16,
              color: AuroraColors.coral,
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
        horizontal: AuroraSpacing.space3,
        vertical: 10,
      ),
      style: AuroraType.body,
      placeholderStyle: AuroraType.body.copyWith(
        color: AuroraColors.inkTertiary,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        border: Border.all(color: AuroraColors.inkBorder),
        borderRadius: BorderRadius.circular(8),
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
      style: AuroraType.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space3,
          vertical: 10,
        ),
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
        filled: true,
        fillColor: AuroraColors.paper,
      ),
    );
  }
}

// ── Empty placeholder ─────────────────────────────────────────────────────────

class _EmptyCircuitPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.electric_bolt_outlined,
            size: 16,
            color: AuroraColors.inkSecondary,
          ),
          const SizedBox(width: AuroraSpacing.space3),
          Text(
            'No circuits added yet',
            style: AuroraType.bodySm.copyWith(
              color: AuroraColors.inkSecondary,
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
              size: 16,
              color: AuroraColors.ink,
            ),
            const SizedBox(width: AuroraSpacing.space1),
            Text(
              'Add Circuit',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AuroraColors.ink,
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
        size: 16,
        color: AuroraColors.ink,
      ),
      label: Text(
        'Add Circuit',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AuroraColors.ink,
        ),
      ),
    );
  }
}

// ── Data container ────────────────────────────────────────────────────────────

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
