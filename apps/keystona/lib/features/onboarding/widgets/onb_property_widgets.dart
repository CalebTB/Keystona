import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import '../models/onboarding_models.dart';

/// Address input with a leading pin. The border is coral until an address is
/// picked (kit).
class OnbAddressField extends StatelessWidget {
  const OnbAddressField({
    super.key,
    required this.controller,
    required this.picked,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool picked;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: a.of(AuroraSpacing.space2),
      children: [
        const AuroraFieldLabel(label: 'Address', isRequired: true),
        AuroraFieldBox(
          error: !picked,
          child: Row(
            spacing: a.of(AuroraSpacing.space4),
            children: [
              Icon(
                Icons.location_on_outlined,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.inkHelper,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: AuroraType.input,
                  cursorColor: AuroraColors.cobalt,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Start typing your address',
                    hintStyle: AuroraType.input.copyWith(
                      color: AuroraColors.inkPlaceholder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The suggestion list under the address field.
class OnbSuggestionList extends StatelessWidget {
  const OnbSuggestionList({
    super.key,
    required this.suggestions,
    required this.onPick,
  });

  final List<OnbAddress> suggestions;
  final ValueChanged<OnbAddress> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.all(AuroraSpacing.space1),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
        boxShadow: AuroraOnbShadows.suggestions,
      ),
      child: Column(
        children: [
          for (final s in suggestions)
            AuroraPressable(
              onTap: () => onPick(s),
              semanticLabel: s.street,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AuroraSizes.minTouch,
                ),
                child: Padding(
                  padding: a.symmetric(
                    horizontal: AuroraSpacing.space5,
                    vertical: AuroraSpacing.space4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: a.of(AuroraSpacing.space1),
                      children: [
                        Text(s.street, style: AuroraOnbType.suggestion),
                        Text(
                          '${s.city} · ${s.zip}'.toUpperCase(),
                          style: AuroraType.meta,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kind-of-home tile: ink fill when selected.
class OnbTypeTile extends StatelessWidget {
  const OnbTypeTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: AuroraPressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: label,
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraOnbSizes.typeTileHeight),
          ),
          padding: a.symmetric(horizontal: AuroraSpacing.space3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AuroraColors.ink : AuroraColors.paper,
            borderRadius: AuroraRadius.md,
            border: Border.all(
              color: selected ? AuroraColors.ink : AuroraColors.inkInputBorder,
              width: selected ? AuroraBorders.emphasis : AuroraBorders.regular,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AuroraOnbType.tile.copyWith(
              color: selected ? AuroraColors.paper : AuroraColors.inkBody,
            ),
          ),
        ),
      ),
    );
  }
}
