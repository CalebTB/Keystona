import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/label_scanner_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A camera button that scans an appliance/system label and returns the
/// extracted data via [onResult]. Shows a confirmation sheet before calling
/// [onResult] so the user can review what was found.
///
/// Drop this widget anywhere in a form and wire [onResult] to fill controllers.
class ScanLabelButton extends StatefulWidget {
  const ScanLabelButton({
    super.key,
    required this.onResult,
    this.isAppliance = false,
  });

  final void Function(LabelScanResult result) onResult;
  final bool isAppliance;

  @override
  State<ScanLabelButton> createState() => _ScanLabelButtonState();
}

class _ScanLabelButtonState extends State<ScanLabelButton> {
  bool _scanning = false;

  Future<void> _scan(ImageSource source) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (photo == null || !mounted) return;

    setState(() => _scanning = true);
    try {
      final result = await LabelScannerService.scanImage(
        photo,
        isAppliance: widget.isAppliance,
      );
      if (!mounted) return;

      if (result.isEmpty) {
        _showError("Couldn't read any info from that label. Try a clearer photo.");
        return;
      }

      await _showConfirmationSheet(result);
    } catch (_) {
      if (mounted) {
        _showError("Something went wrong. Check your connection and try again.");
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _showConfirmationSheet(LabelScanResult result) async {
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (_) => _ScanResultSheet(result: result),
    );
    if (confirmed == true && mounted) {
      widget.onResult(result);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSourcePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Scan Label'),
        message: const Text(
            'Point the camera at the appliance or system label.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _scan(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _scan(ImageSource.gallery);
            },
            child: const Text('Choose from Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _scanning ? null : _showSourcePicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.deepNavy.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: _scanning
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Reading label...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    size: 18,
                    color: AppColors.deepNavy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan Label',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.deepNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Confirmation sheet ─────────────────────────────────────────────────────────

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({required this.result});

  final LabelScanResult result;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.olive.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: AppColors.olive, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Label scanned',
                            style: AppTextStyles.bodyMediumSemibold),
                        Text(
                          '${result.fieldCount} field${result.fieldCount == 1 ? '' : 's'} found',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Column(
                  children: [
                    if (result.brand != null)
                      _ResultRow(label: 'Brand', value: result.brand!),
                    if (result.name != null)
                      _ResultRow(label: 'Type', value: result.name!),
                    if (result.category != null)
                      _ResultRow(label: 'Category', value: result.category!),
                    if (result.modelNumber != null)
                      _ResultRow(label: 'Model', value: result.modelNumber!),
                    if (result.serialNumber != null)
                      _ResultRow(
                          label: 'Serial', value: result.serialNumber!),
                    if (result.manufactureDate != null)
                      _ResultRow(
                          label: 'Mfg Date', value: result.manufactureDate!),
                    if (result.estimatedLifespanYears != null)
                      _ResultRow(
                          label: 'Lifespan',
                          value: '~${result.estimatedLifespanYears} years'),
                    if (result.estimatedReplacementCostUsd != null)
                      _ResultRow(
                          label: 'Est. Cost',
                          value:
                              '\$${result.estimatedReplacementCostUsd}'),
                    if (result.notes != null)
                      _ResultRow(label: 'Notes', value: result.notes!),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.transparent,
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true)
                                .pop(false),
                        child: Text(
                          'Try Again',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: AppColors.deepNavy,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true)
                                .pop(true),
                        child: Text(
                          'Fill Form',
                          style: AppTextStyles.bodyMediumSemibold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.monoLabel.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
