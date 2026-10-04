import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/upgrade_sheet.dart' show UpgradeSheet, UpgradeSheetConfig;
import '../models/document_upload_state.dart';
import '../providers/document_upload_provider.dart';

/// Step 3 of the upload wizard — upload progress and completion.
///
/// Shows an animated linear progress bar while uploading. On success, shows
/// a confirmation message. On error, shows the error with a retry button.
class UploadProgressStep extends ConsumerStatefulWidget {
  const UploadProgressStep({
    super.key,
    required this.onDone,
    required this.onRetry,
  });

  /// Called after a successful upload. Typically pops the wizard.
  final VoidCallback onDone;

  /// Called when the user taps "Retry" on an error.
  final VoidCallback onRetry;

  @override
  ConsumerState<UploadProgressStep> createState() =>
      _UploadProgressStepState();
}

class _UploadProgressStepState extends ConsumerState<UploadProgressStep> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentUploadProvider);

    if (state.step == DocumentUploadStep.success) {
      return _SuccessView(
        documentName: state.uploadedDocument?.name ?? state.name,
        onDone: widget.onDone,
      );
    }

    if (state.errorMessage != null) {
      if (state.errorMessage == 'free_tier') {
        return _FreeTierErrorView(
          onUpgrade: () => UpgradeSheet.show(
            context,
            config: const UpgradeSheetConfig(
              headline: 'Unlock Unlimited Documents',
              reason:
                  'Your Document Vault is full with 25 documents on the Free plan.',
              features: [
                'Unlimited document storage',
                'Full-text search across all docs',
                'Home health score tracking',
                'Weather-based maintenance alerts',
              ],
              triggerKey: 'doc_limit',
            ),
          ),
        );
      }

      return _ErrorView(
        message: state.errorMessage!,
        onRetry: widget.onRetry,
      );
    }

    // Uploading — show animated progress bar.
    return _ProgressView(progress: state.uploadProgress);
  }
}

// ── Progress view ──────────────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AnimatedUploadIcon(),
            const SizedBox(height: AuroraSpacing.space8),
            Text(
              progress < 0.5 ? 'Preparing upload…' : 'Uploading…',
              style: AuroraType.h3,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'This may take a moment.',
              style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
            ),
            const SizedBox(height: AuroraSpacing.space8),
            ClipRRect(
              borderRadius: AuroraRadius.full,
              child: LinearProgressIndicator(
                value: progress < 0.05 ? null : progress,
                minHeight: 6,
                backgroundColor: AuroraColors.butter,
                valueColor: const AlwaysStoppedAnimation(AuroraColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success view ───────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.documentName,
    required this.onDone,
  });

  final String documentName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AuroraColors.limeDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AuroraColors.limeDeep,
                size: 32,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space8),
            Text('Document saved!', style: AuroraType.h2),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              '"$documentName" has been added to your vault.',
              style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space8),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.coral,
                minimumSize: const Size.fromHeight(56),
                shape: const RoundedRectangleBorder(
                  borderRadius: AuroraRadius.sm,
                ),
              ),
              child: Text(
                'Done',
                style: AuroraType.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AuroraColors.paper,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error views ────────────────────────────────────────────────────────────────

class _FreeTierErrorView extends StatelessWidget {
  const _FreeTierErrorView({required this.onUpgrade});
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AuroraColors.limeDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AuroraColors.yellow,
                size: 32,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space8),
            Text(
              'Document limit reached',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              "You've reached 25 documents on the Free plan. Upgrade to Pro for unlimited storage.",
              style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuroraColors.coral,
                  foregroundColor: AuroraColors.yellow,
                ),
                child: const Text('See Premium Plans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AuroraColors.coralDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AuroraColors.coral,
                size: 32,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space8),
            Text('Upload failed', style: AuroraType.h3),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              message,
              style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AuroraSpacing.space8),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AuroraColors.coral,
                  minimumSize: const Size.fromHeight(56),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AuroraRadius.sm,
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: AuroraType.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.paper,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Animated upload icon ──────────────────────────────────────────────────────

class _AnimatedUploadIcon extends StatefulWidget {
  const _AnimatedUploadIcon();

  @override
  State<_AnimatedUploadIcon> createState() => _AnimatedUploadIconState();
}

class _AnimatedUploadIconState extends State<_AnimatedUploadIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: AuroraColors.ink,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.upload_rounded,
          color: AuroraColors.paper,
          size: 32,
        ),
      ),
    );
  }
}
