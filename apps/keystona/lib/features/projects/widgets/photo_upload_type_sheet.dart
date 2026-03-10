import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_photo.dart';

/// Shows a platform-adaptive sheet for selecting photo type and optional room tag.
///
/// Returns `({String photoType, String? roomTag})` or `null` if cancelled.
Future<({String photoType, String? roomTag})?> showPhotoUploadTypeSheet(
    BuildContext context) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  if (isIOS) {
    return showCupertinoModalPopup<({String photoType, String? roomTag})?>(
      context: context,
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: _TypeSheet(),
      ),
    );
  }
  return showModalBottomSheet<({String photoType, String? roomTag})?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TypeSheet(),
  );
}

class _TypeSheet extends StatefulWidget {
  @override
  State<_TypeSheet> createState() => _TypeSheetState();
}

class _TypeSheetState extends State<_TypeSheet> {
  String _type = 'progress';
  final _roomCtrl = TextEditingController();

  @override
  void dispose() {
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      child: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: AppPadding.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle.
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),

              Text('Photo Type', style: AppTextStyles.h3),
              const SizedBox(height: AppSizes.md),

              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: PhotoTypes.all.map((t) {
                  final selected = _type == t.value;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.deepNavy
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                          color: selected
                              ? AppColors.deepNavy
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        t.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSizes.md),

              Text(
                'Room / Area (optional)',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: _roomCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Master Bathroom',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.gray400),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  isDense: true,
                ),
              ),

              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .pop((
                    photoType: _type,
                    roomTag: _roomCtrl.text.trim().isEmpty
                        ? null
                        : _roomCtrl.text.trim(),
                  )),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepNavy,
                    padding: AppPadding.button,
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
