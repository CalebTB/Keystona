import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
      backgroundColor: AuroraColors.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              color: AuroraColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AuroraSpacing.space3),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuroraColors.inkBorder,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space7,
                    vertical: AuroraSpacing.space7,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Link Policy Document',
                          style: AuroraType.h3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(null),
                        child: Text(
                          'Cancel',
                          style: AuroraType.body.copyWith(
                            color: AuroraColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AuroraColors.inkBorder),
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
        padding: EdgeInsets.all(AuroraSpacing.space10),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space9),
        child: Center(
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final docs = _docs ?? [];
    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space9),
        child: Center(
          child: Text(
            'No PDF documents yet. Upload your policy as a PDF to link it here.',
            textAlign: TextAlign.center,
            style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: docs.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AuroraColors.inkBorder),
      itemBuilder: (_, i) {
        final doc = docs[i];
        return ListTile(
          leading: const Icon(
            Icons.picture_as_pdf_outlined,
            color: AuroraColors.ink,
          ),
          title: Text(
            doc['name'] as String,
            style: AuroraType.body,
          ),
          onTap: () => Navigator.of(context, rootNavigator: true).pop(
            (id: doc['id'] as String, name: doc['name'] as String),
          ),
        );
      },
    );
  }
}
