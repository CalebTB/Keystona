import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/supabase_service.dart';

Future<({String id, String name})?> showDocumentLinkPicker(
  BuildContext context,
) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  if (isIOS) {
    return showCupertinoModalPopup<({String id, String name})?>(
      context: context,
      builder: (_) => const _DocumentPickerSheet(),
    );
  } else {
    return showModalBottomSheet<({String id, String name})?>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => const _DocumentPickerSheet(),
    );
  }
}

class _DocumentPickerSheet extends StatefulWidget {
  const _DocumentPickerSheet();

  @override
  State<_DocumentPickerSheet> createState() => _DocumentPickerSheetState();
}

class _DocumentPickerSheetState extends State<_DocumentPickerSheet> {
  List<Map<String, dynamic>>? _docs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final propertyRow = await SupabaseService.client
          .from('properties')
          .select('id')
          .eq('user_id', user.id)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (propertyRow == null) {
        if (mounted) setState(() { _docs = []; _loading = false; });
        return;
      }
      final rows = await SupabaseService.client
          .from('documents')
          .select('id, name')
          .eq('property_id', propertyRow['id'] as String)
          .eq('mime_type', 'application/pdf')
          .isFilter('deleted_at', null)
          .order('name');
      if (mounted) {
        setState(() {
          _docs = (rows as List<dynamic>).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = "Couldn't load documents.";
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.sm),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Link Policy Document',
                          style: AppTextStyles.h3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(null),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Center(
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final docs = _docs ?? [];
    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Center(
          child: Text(
            'No PDF documents yet. Upload your policy as a PDF to link it here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: docs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final doc = docs[i];
        return ListTile(
          leading: const Icon(
            Icons.picture_as_pdf_outlined,
            color: AppColors.deepNavy,
          ),
          title: Text(
            doc['name'] as String,
            style: AppTextStyles.bodyMedium,
          ),
          onTap: () => Navigator.of(context, rootNavigator: true).pop(
            (id: doc['id'] as String, name: doc['name'] as String),
          ),
        );
      },
    );
  }
}
