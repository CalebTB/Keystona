import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../home_profile/providers/appliances_provider.dart';
import '../../../home_profile/providers/systems_provider.dart';
import '../../models/document_upload_state.dart';

/// What the "Linked to" sheet returns: a choice (possibly "no link"), or
/// null when the user cancelled.
typedef LinkChoice = ({UploadLink? link});

/// Sheet listing the home's systems and appliances to link a document to.
abstract final class LinkPickerSheet {
  static Future<LinkChoice?> show(
    BuildContext context, {
    required UploadLink? current,
  }) {
    return AuroraSheet.show<LinkChoice>(
      context,
      title: 'Linked to',
      height: AuroraSheetHeight.tall,
      child: _LinkPickerBody(current: current),
    );
  }
}

class _LinkPickerBody extends ConsumerWidget {
  const _LinkPickerBody({required this.current});

  final UploadLink? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systems = ref.watch(systemsProvider).value ?? const [];
    final appliances = ref.watch(appliancesProvider).value ?? const [];
    final a = context.aurora;

    UploadLink link(String id, String name, {required bool appliance}) =>
        (id: id, isAppliance: appliance, name: name, detail: null);

    void choose(UploadLink? choice) =>
        Navigator.of(context).pop<LinkChoice>((link: choice));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          label: 'No link',
          selected: current == null,
          onTap: () => choose(null),
        ),
        if (systems.isNotEmpty) ...[
          _Heading(text: 'Systems', gap: a.of(AuroraSpacing.space8)),
          for (final s in systems)
            _Row(
              label: s.name,
              selected: current?.id == s.id,
              onTap: () => choose(link(s.id, s.name, appliance: false)),
            ),
        ],
        if (appliances.isNotEmpty) ...[
          _Heading(text: 'Appliances', gap: a.of(AuroraSpacing.space8)),
          for (final ap in appliances)
            _Row(
              label: ap.name,
              selected: current?.id == ap.id,
              onTap: () => choose(link(ap.id, ap.name, appliance: true)),
            ),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text, required this.gap});

  final String text;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: gap),
      child: Text(text.toUpperCase(), style: AuroraType.label),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            Expanded(child: Text(label, style: AuroraType.rowTitle)),
            if (selected)
              Icon(
                Icons.check,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.cobalt,
              ),
          ],
        ),
      ),
    );
  }
}
