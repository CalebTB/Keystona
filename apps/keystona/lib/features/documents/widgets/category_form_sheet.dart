import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/document_category.dart';
import '../providers/document_categories_provider.dart';

// ── Icon catalog ──────────────────────────────────────────────────────────────

/// Maps icon name strings (stored in DB) to Flutter [IconData].
///
/// The string key is what is persisted to Supabase; the [IconData] value is
/// used only for display. Add new icons here and they will appear in the picker.
abstract final class CategoryIcons {
  static const Map<String, IconData> all = {
    'document': Icons.description_outlined,
    'home': Icons.home_outlined,
    'shield': Icons.shield_outlined,
    'wrench': Icons.handyman_outlined,
    'dollar': Icons.attach_money,
    'car': Icons.directions_car_outlined,
    'tree': Icons.park_outlined,
    'fire': Icons.local_fire_department_outlined,
    'droplet': Icons.water_drop_outlined,
    'bolt': Icons.bolt_outlined,
    'camera': Icons.photo_camera_outlined,
    'folder': Icons.folder_outlined,
    'star': Icons.star_outline,
    'heart': Icons.favorite_outline,
    'lock': Icons.lock_outline,
    'key': Icons.key_outlined,
    'phone': Icons.phone_outlined,
    'calendar': Icons.calendar_today_outlined,
    'tag': Icons.label_outline,
    'archive': Icons.inventory_2_outlined,
    'clipboard': Icons.assignment_outlined,
    'scroll': Icons.description_outlined,
  };

  /// Returns the [IconData] for [key], falling back to [Icons.folder_outlined].
  static IconData forKey(String key) => all[key] ?? Icons.folder_outlined;
}

// ── Color catalog ─────────────────────────────────────────────────────────────

/// 12 preset hex colors available for custom categories.
const List<String> kCategoryColors = [
  '#1565C0', // blue
  '#0097A7', // teal
  '#388E3C', // green
  '#F57C00', // orange
  '#D32F2F', // red
  '#7B1FA2', // purple
  '#C9A84C', // gold
  '#1A2B4A', // navy
  '#795548', // brown
  '#546E7A', // slate
  '#E91E63', // pink
  '#607D8B', // blue-gray
];

// ── Sheet ─────────────────────────────────────────────────────────────────────

/// Shows [CategoryFormSheet] and returns true if the operation succeeded.
///
/// Pass [existing] to pre-fill the form for an edit. Omit it for a create.
Future<bool> showCategoryFormSheet(
  BuildContext context, {
  DocumentCategory? existing,
}) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  bool? result;

  if (isIOS) {
    result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (_) => CategoryFormSheet(existing: existing),
    );
  } else {
    result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (_) => CategoryFormSheet(existing: existing),
    );
  }

  return result ?? false;
}

/// Bottom sheet for creating or editing a custom document category.
///
/// Displays a name text field, an icon picker, and a color swatch grid.
/// On save, calls [DocumentCategoriesNotifier.create] or [updateCategory].
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.existing});

  /// Pre-fills the form when editing an existing category.
  final DocumentCategory? existing;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _loading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?.name ?? '',
    );
    _selectedIcon = widget.existing?.icon ?? CategoryIcons.all.keys.first;
    _selectedColor = widget.existing?.color ?? kCategoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    if (name.length > 50) {
      setState(() => _nameError = 'Name must be 50 characters or fewer');
      return;
    }
    setState(() {
      _nameError = null;
      _loading = true;
    });

    try {
      final notifier = ref.read(documentCategoriesProvider.notifier);
      if (_isEdit) {
        await notifier.updateCategory(
          widget.existing!.id,
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
        );
      } else {
        await notifier.create(
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
        );
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Failed to update category.' : 'Failed to create category.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final title = _isEdit ? 'Edit Category' : 'New Category';

    if (isIOS) {
      return _IOSSheet(
        title: title,
        nameController: _nameController,
        nameError: _nameError,
        selectedIcon: _selectedIcon,
        selectedColor: _selectedColor,
        loading: _loading,
        onIconSelected: (icon) => setState(() => _selectedIcon = icon),
        onColorSelected: (color) => setState(() => _selectedColor = color),
        onSubmit: _submit,
        onCancel: () => Navigator.of(context, rootNavigator: true).pop(false),
      );
    }

    return _AndroidSheet(
      title: title,
      nameController: _nameController,
      nameError: _nameError,
      selectedIcon: _selectedIcon,
      selectedColor: _selectedColor,
      loading: _loading,
      onIconSelected: (icon) => setState(() => _selectedIcon = icon),
      onColorSelected: (color) => setState(() => _selectedColor = color),
      onSubmit: _submit,
    );
  }
}

// ── iOS variant ───────────────────────────────────────────────────────────────

class _IOSSheet extends StatelessWidget {
  const _IOSSheet({
    required this.title,
    required this.nameController,
    required this.nameError,
    required this.selectedIcon,
    required this.selectedColor,
    required this.loading,
    required this.onIconSelected,
    required this.onColorSelected,
    required this.onSubmit,
    required this.onCancel,
  });

  final String title;
  final TextEditingController nameController;
  final String? nameError;
  final String selectedIcon;
  final String selectedColor;
  final bool loading;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<String> onColorSelected;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    // Material wrapper is required: TextField (in _FormBody) needs a Material
    // ancestor — showCupertinoModalPopup provides only a Cupertino context.
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.systemGroupedBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Header row
                  Padding(
                    padding: AppPadding.screenHorizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: loading ? null : onCancel,
                          child: const Text('Cancel'),
                        ),
                        Text(title, style: AppTextStyles.h4),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: loading ? null : onSubmit,
                          child: loading
                              ? const CupertinoActivityIndicator()
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.md),

                  Padding(
                    padding: AppPadding.screenHorizontal,
                    child: _FormBody(
                      nameController: nameController,
                      nameError: nameError,
                      selectedIcon: selectedIcon,
                      selectedColor: selectedColor,
                      onIconSelected: onIconSelected,
                      onColorSelected: onColorSelected,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Android variant ───────────────────────────────────────────────────────────

class _AndroidSheet extends StatelessWidget {
  const _AndroidSheet({
    required this.title,
    required this.nameController,
    required this.nameError,
    required this.selectedIcon,
    required this.selectedColor,
    required this.loading,
    required this.onIconSelected,
    required this.onColorSelected,
    required this.onSubmit,
  });

  final String title;
  final TextEditingController nameController;
  final String? nameError;
  final String selectedIcon;
  final String selectedColor;
  final bool loading;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<String> onColorSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppSizes.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          Padding(
            padding: AppPadding.screenHorizontal,
            child: Row(
              children: [
                Text(title, style: AppTextStyles.h3),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          Padding(
            padding: AppPadding.screenHorizontal,
            child: _FormBody(
              nameController: nameController,
              nameError: nameError,
              selectedIcon: selectedIcon,
              selectedColor: selectedColor,
              onIconSelected: onIconSelected,
              onColorSelected: onColorSelected,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          Padding(
            padding: AppPadding.screenHorizontal,
            child: SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: FilledButton(
                onPressed: loading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textInverse,
                        ),
                      )
                    : Text(
                        'Save',
                        style: AppTextStyles.button
                            .copyWith(color: AppColors.textInverse),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.nameController,
    required this.nameError,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
    required this.onColorSelected,
  });

  final TextEditingController nameController;
  final String? nameError;
  final String selectedIcon;
  final String selectedColor;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        Text('Name', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSizes.xs),
        TextField(
          controller: nameController,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Pool & Spa',
            errorText: nameError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            counterStyle: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Icon picker
        Text('Icon', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSizes.sm),
        _IconPicker(
          selected: selectedIcon,
          onSelected: onIconSelected,
        ),
        const SizedBox(height: AppSizes.md),

        // Color picker
        Text('Color', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSizes.sm),
        _ColorPicker(
          selected: selectedColor,
          onSelected: onColorSelected,
        ),
      ],
    );
  }
}

// ── Icon picker ───────────────────────────────────────────────────────────────

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: CategoryIcons.all.entries.map((entry) {
          final isSelected = entry.key == selected;
          return GestureDetector(
            onTap: () => onSelected(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: AppSizes.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepNavy : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(
                  color: isSelected ? AppColors.deepNavy : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                entry.value,
                size: AppSizes.iconMd,
                color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Color picker ──────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static Color _fromHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: kCategoryColors.map((hex) {
        final isSelected = hex == selected;
        return GestureDetector(
          onTap: () => onSelected(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _fromHex(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.deepNavy : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _fromHex(hex).withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
