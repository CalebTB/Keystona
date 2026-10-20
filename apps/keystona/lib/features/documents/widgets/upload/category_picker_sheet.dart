import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/upgrade_sheet.dart';
import '../../../../services/providers/service_providers.dart';
import '../../models/document_category.dart';
import '../../providers/document_categories_provider.dart';
import '../../providers/documents_provider.dart';
import 'category_picker_row.dart';

/// The "Category" sheet (kit: DocCategory): search, the standard categories,
/// the user's own, and a way to manage them.
///
/// Resolves to the chosen category when the user taps Done, or null when they
/// cancel.
abstract final class CategoryPickerSheet {
  static Future<DocumentCategory?> show(
    BuildContext context, {
    required List<DocumentCategory> categories,
    required String? selectedId,
  }) {
    final selection = ValueNotifier<String?>(selectedId);
    return AuroraSheet.show<DocumentCategory>(
      context,
      title: 'Category',
      confirmLabel: 'Done',
      height: AuroraSheetHeight.extra,
      onConfirm: () {
        DocumentCategory? chosen;
        for (final c in categories) {
          if (c.id == selection.value) chosen = c;
        }
        Navigator.of(context).pop(chosen);
      },
      child: _CategoryPickerBody(selection: selection),
    ).whenComplete(selection.dispose);
  }
}

class _CategoryPickerBody extends ConsumerStatefulWidget {
  const _CategoryPickerBody({required this.selection});

  final ValueNotifier<String?> selection;

  @override
  ConsumerState<_CategoryPickerBody> createState() =>
      _CategoryPickerBodyState();
}

class _CategoryPickerBodyState extends ConsumerState<_CategoryPickerBody> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _newCategory() async {
    if (!ref.read(isPremiumProvider)) {
      await UpgradeSheet.show(
        context,
        config: const UpgradeSheetConfig(
          headline: 'Unlock your own categories',
          reason: 'Premium lets you add categories of your own.',
          features: ['Your own categories', 'Unlimited document storage'],
          triggerKey: 'custom_category',
        ),
      );
      return;
    }
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutes.documentsCategories);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final categories = ref.watch(documentCategoriesProvider).value ?? const [];
    final counts = ref.watch(documentCategoryCountsProvider).value ?? const {};
    final q = _query.text.trim().toLowerCase();
    bool matches(DocumentCategory c) =>
        q.isEmpty || c.name.toLowerCase().contains(q);
    final standard = categories.where((c) => c.isSystem && matches(c)).toList();
    final yours = categories.where((c) => !c.isSystem && matches(c)).toList();

    return ValueListenableBuilder<String?>(
      valueListenable: widget.selection,
      builder: (context, selected, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBox(controller: _query, onChanged: (_) => setState(() {})),
          if (standard.isNotEmpty)
            _Group(title: 'Standard', rows: _rows(standard, counts, selected)),
          if (yours.isNotEmpty)
            _Group(
              title: 'Yours',
              trailing: AuroraPressable(
                semanticLabel: 'Manage categories',
                enforceTouchTarget: true,
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(AppRoutes.documentsCategories);
                },
                child: Text(
                  'Manage',
                  style: AuroraType.buttonSm.copyWith(
                    color: AuroraColors.cobalt,
                  ),
                ),
              ),
              rows: _rows(yours, counts, selected),
            ),
          SizedBox(height: a.of(AuroraSpacing.space7)),
          _NewCategoryRow(onTap: _newCategory),
        ],
      ),
    );
  }

  List<Widget> _rows(
    List<DocumentCategory> list,
    Map<String, int> counts,
    String? selected,
  ) => [
    for (var i = 0; i < list.length; i++)
      CategoryPickerRow(
        category: list[i],
        docCount: counts[list[i].id] ?? 0,
        selected: list[i].id == selected,
        showDivider: i < list.length - 1,
        onTap: () => widget.selection.value = list[i].id,
      ),
  ];
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows, this.trailing});

  final String title;
  final Widget? trailing;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: a.of(AuroraSpacing.space9)),
        Row(
          children: [
            Expanded(child: Text(title.toUpperCase(), style: AuroraType.label)),
            ?trailing,
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Container(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _NewCategoryRow extends StatelessWidget {
  const _NewCategoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'New category',
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add,
              size: a.of(AuroraIconSizes.lg),
              color: AuroraColors.ink,
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Text('New category', style: AuroraType.rowTitle),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Text(
              '★ PREMIUM',
              style: AuroraType.labelSm.copyWith(color: AuroraColors.coralDeep),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraFieldBox(
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: a.of(AuroraIconSizes.lg),
            color: AuroraColors.inkHelper,
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AuroraType.input,
              cursorColor: AuroraColors.cobalt,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Find a category',
                hintStyle: AuroraType.input.copyWith(
                  color: AuroraColors.inkPlaceholder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
