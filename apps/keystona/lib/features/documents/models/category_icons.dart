import 'package:flutter/material.dart';

/// Icon catalog for document categories.
///
/// The string key is what is persisted to Supabase; the [IconData] value is
/// used only for display. Add new icons here and they appear in the picker.
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
    'sun': Icons.wb_sunny_outlined,
    'pencil': Icons.edit_outlined,
  };

  /// The eight icons offered when making a category (kit: DocCategories).
  static const List<String> picker = [
    'folder',
    'sun',
    'droplet',
    'car',
    'pencil',
    'bolt',
    'shield',
    'home',
  ];

  /// Icon preselected for a new category.
  static const String defaultKey = 'pencil';

  /// Returns the [IconData] for [key], falling back to [Icons.folder_outlined].
  static IconData forKey(String key) => all[key] ?? Icons.folder_outlined;
}

/// Color stored with a custom category. The kit draws categories without a
/// color, but the column is required; every custom category gets ink.
const String kCustomCategoryColor = '#071238';
