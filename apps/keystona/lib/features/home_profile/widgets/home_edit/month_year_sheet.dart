import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../home_edit_copy.dart';

/// What the month and year sheet returns: a date (the first of the month) or
/// null to clear it. Dismissing the sheet returns nothing at all.
class MonthYearChoice {
  const MonthYearChoice(this.date);

  final DateTime? date;
}

/// A month wheel and a year wheel in a sheet, for "when you bought it".
class MonthYearSheet extends StatefulWidget {
  const MonthYearSheet({super.key, required this.initial, required this.now});

  /// Shows the sheet. [initial] is the current date, [now] bounds the years.
  static Future<MonthYearChoice?> show(
    BuildContext context, {
    required DateTime? initial,
    required DateTime now,
  }) => AuroraSheet.showAuto<MonthYearChoice>(
    context,
    title: HomeEditCopy.purchaseSheet,
    child: MonthYearSheet(initial: initial, now: now),
  );

  final DateTime? initial;
  final DateTime now;

  /// Earliest year offered.
  static const int firstYear = 1900;

  @override
  State<MonthYearSheet> createState() => _MonthYearSheetState();
}

class _MonthYearSheetState extends State<MonthYearSheet> {
  late final FixedExtentScrollController _months;
  late final FixedExtentScrollController _years;
  late int _month;
  late int _year;

  static final List<String> _monthNames = DateFormat.MMMM().dateSymbols.MONTHS;

  /// Years run newest first.
  List<int> get _yearList => [
    for (var y = widget.now.year; y >= MonthYearSheet.firstYear; y--) y,
  ];

  @override
  void initState() {
    super.initState();
    final start = widget.initial ?? widget.now;
    _month = start.month;
    _year = start.year.clamp(MonthYearSheet.firstYear, widget.now.year);
    _months = FixedExtentScrollController(initialItem: _month - 1);
    _years = FixedExtentScrollController(
      initialItem: widget.now.year - _year,
    );
  }

  @override
  void dispose() {
    _months.dispose();
    _years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final years = _yearList;
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: a.all(AuroraSpacing.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: a.of(AuroraHomeASizes.wheelHeight),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Wheel(
                      controller: _months,
                      labels: _monthNames,
                      onChanged: (i) => _month = i + 1,
                    ),
                  ),
                  Expanded(
                    child: _Wheel(
                      controller: _years,
                      labels: [for (final y in years) '$y'],
                      onChanged: (i) => _year = years[i],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: a.of(AuroraSpacing.space5)),
            PrimaryButton(
              label: HomeEditCopy.purchaseSet,
              expand: true,
              onPressed: () => Navigator.of(
                context,
              ).pop(MonthYearChoice(DateTime(_year, _month))),
            ),
            GhostButton(
              label: HomeEditCopy.purchaseClear,
              onPressed: () =>
                  Navigator.of(context).pop(const MonthYearChoice(null)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.labels,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: a.of(AuroraHomeASizes.wheelItem),
      backgroundColor: AuroraColors.paper,
      onSelectedItemChanged: onChanged,
      children: [
        for (final label in labels)
          Center(child: Text(label, style: AuroraType.input)),
      ],
    );
  }
}
