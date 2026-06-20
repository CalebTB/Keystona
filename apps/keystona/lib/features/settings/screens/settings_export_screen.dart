import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';

class SettingsExportScreen extends StatefulWidget {
  const SettingsExportScreen({super.key});

  @override
  State<SettingsExportScreen> createState() => _SettingsExportScreenState();
}

class _SettingsExportScreenState extends State<SettingsExportScreen> {
  bool _exporting = false;

  Future<void> _requestExport() async {
    setState(() => _exporting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _exporting = false);
    SnackbarService.showSuccess(
        context, 'Export requested — you\'ll receive an email shortly.');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.warmOffWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.warmOffWhite,
        border: null,
        middle: const Text('Export My Data'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Back'),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppPadding.screen.copyWith(top: AppSizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export your data', style: AppTextStyles.displaySmall),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Download a copy of everything Keystona stores about your home — documents, tasks, systems, and more.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.xl),

              _ExportItem(
                icon: CupertinoIcons.doc_text,
                color: AppColors.plum,
                title: 'Documents',
                subtitle: 'All uploaded files and metadata',
              ),
              const SizedBox(height: AppSizes.cardGap),
              _ExportItem(
                icon: CupertinoIcons.wrench,
                color: AppColors.olive,
                title: 'Maintenance tasks',
                subtitle: 'History and completion records',
              ),
              const SizedBox(height: AppSizes.cardGap),
              _ExportItem(
                icon: CupertinoIcons.house,
                color: AppColors.accent,
                title: 'Home profile',
                subtitle: 'Property details, systems, appliances',
              ),

              const SizedBox(height: AppSizes.xl),

              GestureDetector(
                onTap: _exporting ? null : _requestExport,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _exporting
                        ? AppColors.plum.withValues(alpha: 0.5)
                        : AppColors.plum,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  ),
                  child: _exporting
                      ? const Center(
                          child: CupertinoActivityIndicator(
                              color: AppColors.textInverse))
                      : Text(
                          'Request export',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMediumSemibold
                              .copyWith(color: AppColors.textInverse),
                        ),
                ),
              ),

              const SizedBox(height: AppSizes.md),
              Text(
                'You\'ll receive an email with a download link within 24 hours.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportItem extends StatelessWidget {
  const _ExportItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMediumSemibold),
              Text(subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
