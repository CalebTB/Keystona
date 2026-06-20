import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/providers/service_providers.dart';

class SettingsDeleteAccountScreen extends ConsumerStatefulWidget {
  const SettingsDeleteAccountScreen({super.key});

  @override
  ConsumerState<SettingsDeleteAccountScreen> createState() =>
      _SettingsDeleteAccountScreenState();
}

class _SettingsDeleteAccountScreenState
    extends ConsumerState<SettingsDeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _deleting = false;
  bool get _confirmed =>
      _confirmController.text.trim().toLowerCase() == 'delete';

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_confirmed) return;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This is permanent. All your data will be erased and cannot be recovered.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    // Stub: call Edge Function to delete account data, then sign out.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.warmOffWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.warmOffWhite,
        border: null,
        middle: const Text('Delete Account'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _deleting ? null : () => context.pop(),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 26, color: AppColors.accent),
              ),
              const SizedBox(height: AppSizes.md),
              Text('Delete your account', style: AppTextStyles.displaySmall),
              const SizedBox(height: AppSizes.sm),
              Text(
                'This will permanently delete your account and all associated data including documents, tasks, systems, and home history. This cannot be undone.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppSizes.xl),

              Text(
                'Type DELETE to confirm',
                style: AppTextStyles.monoSection,
              ),
              const SizedBox(height: AppSizes.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: TextField(
                  controller: _confirmController,
                  style: AppTextStyles.bodyLarge,
                  decoration: null,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              GestureDetector(
                onTap: (_confirmed && !_deleting) ? _delete : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _confirmed
                        ? AppColors.accent
                        : AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  ),
                  child: _deleting
                      ? const Center(
                          child: CupertinoActivityIndicator(
                              color: AppColors.textInverse))
                      : Text(
                          'Delete my account',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMediumSemibold
                              .copyWith(color: AppColors.textInverse),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
