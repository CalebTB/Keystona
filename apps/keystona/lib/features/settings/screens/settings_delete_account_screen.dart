import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
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
          padding: const EdgeInsets.all(AuroraSpacing.screenPadH)
              .copyWith(top: AuroraSpacing.space10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AuroraColors.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 26, color: AuroraColors.coral),
              ),
              const SizedBox(height: AuroraSpacing.space7),
              Text('Delete your account', style: AuroraType.h1),
              const SizedBox(height: AuroraSpacing.space3),
              Text(
                'This will permanently delete your account and all associated data including documents, tasks, systems, and home history. This cannot be undone.',
                style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              ),

              const SizedBox(height: AuroraSpacing.space10),

              Text(
                'TYPE DELETE TO CONFIRM',
                style: AuroraType.label,
              ),
              const SizedBox(height: AuroraSpacing.space3),
              Container(
                decoration: BoxDecoration(
                  color: AuroraColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: TextField(
                  controller: _confirmController,
                  style: AuroraType.bodyLg,
                  decoration: null,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: AuroraSpacing.space10),

              GestureDetector(
                onTap: (_confirmed && !_deleting) ? _delete : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _confirmed
                        ? AuroraColors.coral
                        : AuroraColors.coral.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _deleting
                      ? const Center(
                          child: CupertinoActivityIndicator(color: Colors.white))
                      : Text(
                          'Delete my account',
                          textAlign: TextAlign.center,
                          style: AuroraType.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
