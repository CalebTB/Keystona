import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../models/project_photo.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AuroraSheet.topRadius(context),
          ),
          padding: EdgeInsets.all(AuroraSpacing.screenPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle.
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AuroraSpacing.space7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DFEA),
                    borderRadius:
                        BorderRadius.circular(999.0),
                  ),
                ),
              ),

              Text('Photo Type', style: AuroraType.h3),
              const SizedBox(height: AuroraSpacing.space7),

              Wrap(
                spacing: AuroraSpacing.space3,
                runSpacing: AuroraSpacing.space3,
                children: PhotoTypes.all.map((t) {
                  final selected = _type == t.value;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AuroraSpacing.space7,
                          vertical: AuroraSpacing.space3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AuroraColors.ink
                            : AuroraColors.paper,
                        borderRadius:
                            BorderRadius.circular(999.0),
                        border: Border.all(
                          color: selected
                              ? AuroraColors.ink
                              : AuroraColors.inkBorder,
                        ),
                      ),
                      child: Text(
                        t.label,
                        style: AuroraType.label.copyWith(
                          color: selected
                              ? Colors.white
                              : AuroraColors.ink,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AuroraSpacing.space7),

              Text(
                'Room / Area (optional)',
                style: AuroraType.bodySm
                    .copyWith(color: AuroraColors.inkSecondary),
              ),
              const SizedBox(height: AuroraSpacing.space1),
              TextField(
                controller: _roomCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Master Bathroom',
                  hintStyle: AuroraType.body
                      .copyWith(color: AuroraColors.inkTertiary),
                  border: OutlineInputBorder(
                    borderRadius: AuroraRadius.md,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space7,
                    vertical: AuroraSpacing.space3,
                  ),
                  isDense: true,
                ),
              ),

              const SizedBox(height: AuroraSpacing.space9),
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
                    backgroundColor: AuroraColors.ink,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: AuroraSpacing.space7),
            ],
          ),
        ),
      ),
    );
  }
}
