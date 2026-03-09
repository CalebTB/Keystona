import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_budget_item.dart';
import '../providers/project_budget_provider.dart';

/// Full-screen form for creating or editing a budget line item.
///
/// - Create mode: [existingItem] = null
/// - Edit mode: [existingItem] is provided
///
/// Pops with the item ID (String) on successful save.
class BudgetItemFormScreen extends ConsumerStatefulWidget {
  const BudgetItemFormScreen({
    super.key,
    required this.projectId,
    this.existingItem,
  });

  final String projectId;
  final ProjectBudgetItem? existingItem;

  @override
  ConsumerState<BudgetItemFormScreen> createState() =>
      _BudgetItemFormScreenState();
}

class _BudgetItemFormScreenState extends ConsumerState<BudgetItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _estimatedCtrl;
  late final TextEditingController _actualCtrl;
  late final TextEditingController _vendorCtrl;

  late String _category;
  late bool _isPaid;
  bool _saving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _estimatedCtrl = TextEditingController(
      text: item != null ? item.estimatedCost.toStringAsFixed(2) : '',
    );
    _actualCtrl = TextEditingController(
      text: item != null && item.actualCost > 0
          ? item.actualCost.toStringAsFixed(2)
          : '',
    );
    _vendorCtrl = TextEditingController(text: item?.vendor ?? '');
    _category = item?.category ?? BudgetCategories.all.first;
    _isPaid = item?.isPaid ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _estimatedCtrl.dispose();
    _actualCtrl.dispose();
    _vendorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCategoryIOS() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Category'),
        actions: BudgetCategories.all
            .map((c) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _category = c);
                    Navigator.of(ctx, rootNavigator: true).pop();
                  },
                  child: Text(
                    c.budgetCategoryLabel,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _category == c
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                      fontWeight: _category == c
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier =
        ref.read(projectBudgetProvider(widget.projectId).notifier);

    try {
      final estimated =
          double.tryParse(_estimatedCtrl.text.trim()) ?? 0;
      final actual = double.tryParse(_actualCtrl.text.trim()) ?? 0;
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'estimated_cost': estimated,
        'actual_cost': actual,
        'is_paid': _isPaid,
        if (_vendorCtrl.text.trim().isNotEmpty)
          'vendor': _vendorCtrl.text.trim(),
      };

      String id;
      if (_isEditing) {
        await notifier.updateItem(widget.existingItem!.id, data);
        id = widget.existingItem!.id;
      } else {
        id = await notifier.createItem(data);
      }

      if (!mounted) return;
      context.pop(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(
          context, 'Could not save item. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS() : _buildAndroid();
  }

  Widget _buildIOS() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => context.pop(),
        ),
        middle: Text(_isEditing ? 'Edit Item' : 'Add Item'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    color: _saving
                        ? CupertinoColors.inactiveGray
                        : CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _FormBody(
          formKey: _formKey,
          nameCtrl: _nameCtrl,
          estimatedCtrl: _estimatedCtrl,
          actualCtrl: _actualCtrl,
          vendorCtrl: _vendorCtrl,
          category: _category,
          isPaid: _isPaid,
          isIOS: true,
          onPickCategoryIOS: _pickCategoryIOS,
          onCategoryChanged: (v) =>
              setState(() => _category = v ?? BudgetCategories.all.first),
          onIsPaidChanged: (v) => setState(() => _isPaid = v ?? false),
        ),
      ),
    );
  }

  Widget _buildAndroid() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppSizes.sm),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: _FormBody(
        formKey: _formKey,
        nameCtrl: _nameCtrl,
        estimatedCtrl: _estimatedCtrl,
        actualCtrl: _actualCtrl,
        vendorCtrl: _vendorCtrl,
        category: _category,
        isPaid: _isPaid,
        isIOS: false,
        onPickCategoryIOS: _pickCategoryIOS,
        onCategoryChanged: (v) =>
            setState(() => _category = v ?? BudgetCategories.all.first),
        onIsPaidChanged: (v) => setState(() => _isPaid = v ?? false),
      ),
    );
  }
}

// ── Form body ─────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.nameCtrl,
    required this.estimatedCtrl,
    required this.actualCtrl,
    required this.vendorCtrl,
    required this.category,
    required this.isPaid,
    required this.isIOS,
    required this.onPickCategoryIOS,
    required this.onCategoryChanged,
    required this.onIsPaidChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController estimatedCtrl;
  final TextEditingController actualCtrl;
  final TextEditingController vendorCtrl;
  final String category;
  final bool isPaid;
  final bool isIOS;
  final VoidCallback onPickCategoryIOS;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool?> onIsPaidChanged;

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: AppPadding.screen,
        children: [
          _Label('Item name'),
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 100,
            decoration: _dec('e.g. Lumber, Plumber labor, Permit fee'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSizes.sm),

          _Label('Category'),
          if (isIOS)
            _TapRow(
              label: 'Category',
              value: category.budgetCategoryLabel,
              onTap: onPickCategoryIOS,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: _dec(''),
              onChanged: onCategoryChanged,
              items: BudgetCategories.all
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.budgetCategoryLabel)))
                  .toList(),
            ),
          const SizedBox(height: AppSizes.sm),

          _Label('Estimated cost'),
          TextFormField(
            controller: estimatedCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec('0.00'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Estimated cost is required';
              }
              if (double.tryParse(v.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.sm),

          _Label('Actual cost (optional)'),
          TextFormField(
            controller: actualCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec('0.00'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (double.tryParse(v.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.sm),

          _Label('Vendor (optional)'),
          TextFormField(
            controller: vendorCtrl,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            decoration: _dec('e.g. Home Depot, John the Plumber'),
          ),
          const SizedBox(height: AppSizes.xs),

          // Paid toggle.
          Row(
            children: [
              Expanded(
                child: Text('Mark as paid', style: AppTextStyles.bodyMedium),
              ),
              Switch(
                value: isPaid,
                onChanged: onIsPaidChanged,
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Text(
        text,
        style:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}
