import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
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
      context,
      "Export requested — you'll receive an email shortly.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.screenPadH,
          ).copyWith(top: AuroraSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ────────────────────────────────────────
              const _SectionHeader(
                dot: AuroraColors.cobalt,
                label: 'YOUR DATA',
              ),
              const SizedBox(height: AuroraSpacing.space3),

              Text(
                'Download a copy of everything Keystona stores about your home — documents, tasks, systems, and more.',
                style: AuroraType.body.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),

              const SizedBox(height: AuroraSpacing.space8),

              // ── Export items ──────────────────────────────────────────
              _ExportItem(
                iconBg: AuroraColors.cobaltDim,
                iconColor: AuroraColors.cobalt,
                icon: CupertinoIcons.doc_text,
                title: 'Documents',
                subtitle: 'All uploaded files and metadata',
              ),
              const SizedBox(height: AuroraSpacing.space3),
              _ExportItem(
                iconBg: AuroraColors.limeDim,
                iconColor: AuroraColors.limeDeep,
                icon: CupertinoIcons.wrench,
                title: 'Maintenance tasks',
                subtitle: 'History and completion records',
              ),
              const SizedBox(height: AuroraSpacing.space3),
              _ExportItem(
                iconBg: AuroraColors.coralDim,
                iconColor: AuroraColors.coral,
                icon: CupertinoIcons.house,
                title: 'Home profile',
                subtitle: 'Property details, systems, appliances',
              ),

              const SizedBox(height: AuroraSpacing.space10),

              // ── CTA: cobalt SaveButton ────────────────────────────────
              SaveButton(
                label: 'Request export',
                onPressed: _exporting ? null : _requestExport,
                loading: _exporting,
                expand: true,
              ),

              const SizedBox(height: AuroraSpacing.space7),

              Text(
                "You'll receive an email with a download link within 24 hours.",
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.inkTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header — dot + label ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.dot, required this.label});

  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: AuroraType.label),
      ],
    );
  }
}

// ── Export item tile ──────────────────────────────────────────────────────────

class _ExportItem extends StatelessWidget {
  const _ExportItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.lg,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AuroraRadius.sm,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AuroraType.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
