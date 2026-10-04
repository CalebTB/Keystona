import 'package:flutter/material.dart';

/// Summary strip — removed as redundant. Callers still construct this widget;
/// it renders nothing.
class PhotosSummaryStrip extends StatelessWidget {
  const PhotosSummaryStrip({
    super.key,
    required this.pairCount,
    required this.unpairedCount,
    required this.latestDate,
    required this.total,
  });

  final int pairCount;
  final int unpairedCount;
  final DateTime? latestDate;
  final int total;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
