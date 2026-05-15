import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

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
        color: AppColors.deepNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            size: 14,
            color: AppColors.deepNavy,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Showing docs for $contractorName',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.deepNavy,
              ),
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
