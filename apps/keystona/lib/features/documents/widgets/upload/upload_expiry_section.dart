import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import 'upload_box_field.dart';
import 'upload_formatters.dart';

/// "It expires" switch and, when on, the expiry date with its reminder line.
class UploadExpirySection extends StatelessWidget {
  const UploadExpirySection({
    super.key,
    required this.expires,
    required this.date,
    required this.foundOnPage,
    required this.dateEdged,
    this.renewing = false,
    required this.onToggle,
    required this.onPickDate,
  });

  final bool expires;
  final DateTime? date;
  final int? foundOnPage;
  final bool dateEdged;

  /// The date is the new copy's end date: the helper asks for it.
  final bool renewing;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuroraToggleRow(
          label: 'It expires',
          helperText: "We'll remind you 30 days before",
          value: expires,
          onChanged: onToggle,
        ),
        if (expires) ...[
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Container(
            padding: EdgeInsetsDirectional.only(
              start: a.of(AuroraSpacing.space6),
            ),
            decoration: const BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: AuroraColors.cobaltBorder,
                  width: AuroraBorders.indicator,
                ),
              ),
            ),
            child: UploadBoxField(
              label: 'Expires',
              isRequired: true,
              edged: dateEdged,
              onTap: onPickDate,
              semanticLabel: date == null
                  ? 'Expires, pick a date'
                  : 'Expires, ${UploadFormatters.fieldDate(date!)}',
              helper: UploadFormatters.dateHelp(
                date,
                foundOnPage: foundOnPage,
                renewing: renewing,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null
                          ? 'MM/DD/YYYY'
                          : UploadFormatters.fieldDate(date!),
                      style: AuroraType.input.copyWith(
                        color: date == null
                            ? AuroraColors.inkPlaceholder
                            : AuroraColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: a.of(AuroraIconSizes.md),
                    color: AuroraColors.inkSubtle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
