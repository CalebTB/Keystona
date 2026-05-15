import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Maps contractor roles to accent colors for avatars and badges.
///
/// Covers roles from [ContractorRoles.all] and common emergency-contact
/// categories. Falls back to [AppColors.gray500] for unknown keys.
const Map<String, Color> _kRoleColors = {
  'general_contractor': AppColors.deepNavy,
  'electrician':        AppColors.goldAccent,
  'plumber':            AppColors.info,
  'hvac':               AppColors.success,
  'painter':            AppColors.gray600,
  'carpenter':          AppColors.warning,
  'roofer':             AppColors.deepNavy,
  'landscaper':         AppColors.success,
  'tile':               AppColors.info,
  'tiler':              AppColors.info,
  'flooring':           AppColors.gray600,
  'designer':           AppColors.goldAccent,
  'architect':          AppColors.deepNavy,
  // Emergency contact categories.
  'plumbing':           AppColors.info,
  'electrical':         AppColors.goldAccent,
  'hvac_replacement':   AppColors.success,
  'roofing':            AppColors.deepNavy,
  'other':              AppColors.gray500,
};

/// Returns the role color for a contractor.
///
/// Checks [role] first, then [category] as a fallback.
/// Returns [AppColors.gray500] when neither maps to a known key.
Color contractorRoleColor(String? role, [String? category]) {
  if (role != null && _kRoleColors.containsKey(role)) {
    return _kRoleColors[role]!;
  }
  if (category != null && _kRoleColors.containsKey(category)) {
    return _kRoleColors[category]!;
  }
  return AppColors.gray500;
}
