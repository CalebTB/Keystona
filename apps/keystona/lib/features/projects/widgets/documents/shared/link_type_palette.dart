import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'document_link_type.dart';

// Local dim colors not yet in AppColors.
// Use inline constants to avoid touching app_colors.dart (parallel agent risk).
const Color _tealDim = Color(0x1A2C9C8E); // teal-ish at ~10% opacity
const Color _tealFg = Color(0xFF2C9C8E); // teal foreground
const Color _plumDim = Color(0x1A7B5EA8); // plum at ~10% opacity
const Color _plumFg = Color(0xFF7B5EA8); // plum foreground
const Color _slateDim = Color(0x1A5A7080); // slate at ~10% opacity
const Color _slateFg = Color(0xFF5A7080); // slate foreground
const Color _sandDim = Color(0x1AC49A48); // sand/amber at ~10% opacity
const Color _sandAmberFg = Color(0xFFC49A48); // sand amber foreground
const Color _accentDim = Color(0x1AB85638); // accent at ~10% opacity
const Color _accentFg = Color(0xFFB85638); // accent foreground

/// Single source of truth: link_type → (background, foreground) colors.
///
/// All link-type badge coloring flows through this class.
abstract final class LinkTypePalette {
  static ({Color background, Color foreground}) forType(
    DocumentLinkType type,
  ) =>
      switch (type) {
        DocumentLinkType.receipt => (
          background: _tealDim,
          foreground: _tealFg,
        ),
        DocumentLinkType.permit => (
          background: _accentDim,
          foreground: _accentFg,
        ),
        DocumentLinkType.contract => (
          background: _slateDim,
          foreground: _slateFg,
        ),
        DocumentLinkType.invoice => (
          background: _sandDim,
          foreground: _sandAmberFg,
        ),
        DocumentLinkType.warranty => (
          background: _plumDim,
          foreground: _plumFg,
        ),
        DocumentLinkType.general => (
          background: AppColors.surfaceVariant,
          foreground: AppColors.textSecondary,
        ),
      };
}
