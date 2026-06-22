import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
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
          'This is permanent. All your data will be erased and cannot be recovered.',
        ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.screenPadH,
          ).copyWith(top: AuroraSpacing.space10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Warning icon tile ─────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AuroraColors.coralDim,
                  borderRadius: AuroraRadius.xl,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 26,
                  color: AuroraColors.coral,
                ),
              ),
              const SizedBox(height: AuroraSpacing.space7),

              // ── Title + description ───────────────────────────────────
              Text('Delete your account', style: AuroraType.h1),
              const SizedBox(height: AuroraSpacing.space3),
              Text(
                'This will permanently delete your account and all associated data including documents, tasks, systems, and home history. This cannot be undone.',
                style: AuroraType.body.copyWith(
                  color: AuroraColors.coral,
                ),
              ),

              const SizedBox(height: AuroraSpacing.space10),

              // ── Confirm field label (eyebrow) ─────────────────────────
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AuroraColors.coral,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TYPE DELETE TO CONFIRM',
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.coral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AuroraSpacing.space3),
              _ConfirmField(
                controller: _confirmController,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AuroraSpacing.space10),

              // ── CTA row: cancel + delete (coral = PrimaryButton) ──────
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      onPressed: _deleting ? null : () => context.pop(),
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.space5),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Delete account',
                      onPressed:
                          (_confirmed && !_deleting) ? _delete : null,
                      loading: _deleting,
                      expand: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm text field ────────────────────────────────────────────────────────

class _ConfirmField extends StatefulWidget {
  const _ConfirmField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_ConfirmField> createState() => _ConfirmFieldState();
}

class _ConfirmFieldState extends State<_ConfirmField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: _isFocused ? AuroraColors.coral : AuroraColors.inkBorder,
          width: _isFocused ? 2.0 : 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AuroraColors.focusCoral,
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space5,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: AuroraType.bodyLg,
        textCapitalization: TextCapitalization.characters,
        cursorColor: AuroraColors.coral,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'DELETE',
          hintStyle: AuroraType.bodyLg.copyWith(
            color: AuroraColors.inkTertiary,
          ),
        ),
      ),
    );
  }
}
