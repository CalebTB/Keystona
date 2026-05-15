import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';

/// Skeleton loading state for the contractors ledger view.
///
/// Mirrors the banner → filter chips → card layout of the real content.
/// Displayed on frame 1 while [projectContractorsProvider] is loading.
class ContractorsLedgerSkeleton extends StatelessWidget {
  const ContractorsLedgerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // Dark banner placeholder.
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, 0,
              ),
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
            ),
          ),

          // Filter chip row.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: List.generate(4, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < 3 ? AppSizes.sm : 0),
                    child: Container(
                      width: 64,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Three card placeholders.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            sliver: SliverList.separated(
              itemCount: 3,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.sm + 2),
              itemBuilder: (_, _) => const _CardPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name lines.
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.gray300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FractionallySizedBox(
                      widthFactor: 0.38,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.gray300,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar stub.
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          const SizedBox(height: 10),
          // Foot pills.
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
