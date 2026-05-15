import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';

/// Skeleton for the documents vault list view.
///
/// Mirrors the exact layout of DocumentsVaultListView:
/// eyebrow + heading → dark banner → filter chips → 4 document rows.
class DocumentsListSkeleton extends StatefulWidget {
  const DocumentsListSkeleton({super.key});

  @override
  State<DocumentsListSkeleton> createState() => _DocumentsListSkeletonState();
}

class _DocumentsListSkeletonState extends State<DocumentsListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bar({
    required double width,
    required double height,
    Color? color,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppColors.gray300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _row() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // File type block placeholder — 44×56
          Container(
            width: 44,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _bar(width: double.infinity, height: 13),
                    ),
                    const SizedBox(width: 8),
                    _bar(width: 52, height: 18, radius: 3),
                  ],
                ),
                const SizedBox(height: 6),
                _bar(width: 120, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _bar(width: 14, height: 14, radius: 2),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: AppPadding.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow line
              _bar(width: 160, height: 11),
              const SizedBox(height: 6),
              // Heading
              _bar(width: 220, height: 28, radius: 6),
              const SizedBox(height: 16),

              // Dark summary banner placeholder
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.deepNavy.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _bar(
                            width: 90,
                            height: 9,
                            color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 6),
                        _bar(
                            width: 40,
                            height: 22,
                            color: Colors.white.withValues(alpha: 0.3),
                            radius: 4),
                      ],
                    ),
                    const Spacer(),
                    _bar(
                        width: 30,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.2),
                        radius: 4),
                    const SizedBox(width: 14),
                    _bar(
                        width: 30,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.2),
                        radius: 4),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Filter chip row
              Row(
                children: [
                  _bar(width: 40, height: 28, radius: 14),
                  const SizedBox(width: 6),
                  _bar(width: 72, height: 28, radius: 14),
                  const SizedBox(width: 6),
                  _bar(width: 60, height: 28, radius: 14),
                  const SizedBox(width: 6),
                  _bar(width: 80, height: 28, radius: 14),
                ],
              ),
              const SizedBox(height: 12),

              // Document rows
              _row(),
              const SizedBox(height: 6),
              _row(),
              const SizedBox(height: 6),
              _row(),
              const SizedBox(height: 6),
              _row(),
            ],
          ),
        ),
      ),
    );
  }
}
