import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
          padding: const EdgeInsets.all(AuroraSpacing.screenPadH)
              .copyWith(top: AuroraSpacing.space10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export your data', style: AuroraType.h1),
              const SizedBox(height: AuroraSpacing.space3),
              Text(
                'Download a copy of everything Keystona stores about your home — documents, tasks, systems, and more.',
                style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              ),
              const SizedBox(height: AuroraSpacing.space10),

              _ExportItem(
                icon: CupertinoIcons.doc_text,
                color: AuroraColors.cobalt,
                title: 'Documents',
                subtitle: 'All uploaded files and metadata',
              ),
              const SizedBox(height: AuroraSpacing.space2),
              _ExportItem(
                icon: CupertinoIcons.wrench,
                color: AuroraColors.lime,
                title: 'Maintenance tasks',
                subtitle: 'History and completion records',
              ),
              const SizedBox(height: AuroraSpacing.space2),
              _ExportItem(
                icon: CupertinoIcons.house,
                color: AuroraColors.coral,
                title: 'Home profile',
                subtitle: 'Property details, systems, appliances',
              ),

              const SizedBox(height: AuroraSpacing.space10),

              GestureDetector(
                onTap: _exporting ? null : _requestExport,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _exporting
                        ? AuroraColors.cobalt.withValues(alpha: 0.5)
                        : AuroraColors.cobalt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _exporting
                      ? const Center(
                          child: CupertinoActivityIndicator(color: Colors.white))
                      : Text(
                          'Request export',
                          textAlign: TextAlign.center,
                          style: AuroraType.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AuroraSpacing.space7),
              Text(
                'You\'ll receive an email with a download link within 24 hours.',
                style: AuroraType.bodySm.copyWith(color: AuroraColors.inkTertiary),
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
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
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
              Text(
                title,
                style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
