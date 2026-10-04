import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';


/// Maps contractor roles to accent colors for avatars and badges.
///
/// Covers roles from [ContractorRoles.all] and common emergency-contact
/// categories. Falls back to [const Color(0xFF9D9BB0)] for unknown keys.
const Map<String, Color> _kRoleColors = {
  'general_contractor': AuroraColors.ink,
  'electrician':        AuroraColors.yellow,
  'plumber':            AuroraColors.cobalt,
  'hvac':               AuroraColors.lime,
  'painter':            Color(0xFF6B6980),
  'carpenter':          AuroraColors.yellow,
  'roofer':             AuroraColors.ink,
  'landscaper':         AuroraColors.lime,
  'tile':               AuroraColors.cobalt,
  'tiler':              AuroraColors.cobalt,
  'flooring':           Color(0xFF6B6980),
  'designer':           AuroraColors.yellow,
  'architect':          AuroraColors.ink,
  // Emergency contact categories.
  'plumbing':           AuroraColors.cobalt,
  'electrical':         AuroraColors.yellow,
  'hvac_replacement':   AuroraColors.lime,
  'roofing':            AuroraColors.ink,
  'other':              Color(0xFF9D9BB0),
};

/// Returns the role color for a contractor.
///
/// Checks [role] first, then [category] as a fallback.
/// Returns [const Color(0xFF9D9BB0)] when neither maps to a known key.
Color contractorRoleColor(String? role, [String? category]) {
  if (role != null && _kRoleColors.containsKey(role)) {
    return _kRoleColors[role]!;
  }
  if (category != null && _kRoleColors.containsKey(category)) {
    return _kRoleColors[category]!;
  }
  return const Color(0xFF9D9BB0);
}
