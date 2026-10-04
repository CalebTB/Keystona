import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_typography.dart';


/// Shown when the documents screen is entered with an active contractor filter.
///
/// Displays "Showing docs for {contractorName}" with an × clear button.
class ContractorFilterBanner extends StatelessWidget {
  const ContractorFilterBanner({
    super.key,
    required this.contractorName,
    required this.onClear,
  });

  final String contractorName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AuroraColors.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 14,
            color: AuroraColors.ink,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Showing docs for $contractorName',
              style: AuroraType.label.copyWith(color: AuroraColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.close,
                size: 14,
                color: AuroraColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
