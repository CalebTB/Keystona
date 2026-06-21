import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aurora_colors.dart';
import 'aurora_typography.dart';

/// Bridge layer — maps v1 AppTextStyles getter names to Aurora v2 type scale.
///
/// Font stack: Inter (everything) + JetBrains Mono (labels, numbers).
/// Fraunces and IBM Plex Mono have been removed.
///
/// Callers switch to AuroraType getters during screen migration; this file
/// is deleted once all feature screens are updated.
abstract final class AppTextStyles {
  // ─── Display (was Fraunces — now Inter) ─────────────────────────────────────

  /// Inter 800 36px −1.2px
  static TextStyle get displayLarge => AuroraType.displayLg;

  /// Inter 800 22px −0.7px
  static TextStyle get displayMedium => AuroraType.h1;

  /// Inter 800 22px −0.7px
  static TextStyle get displaySmall => AuroraType.h1;

  // ─── Headlines (was Fraunces — now Inter) ────────────────────────────────────

  /// Inter 600 18px −0.4px
  static TextStyle get headlineMedium => AuroraType.h2;

  /// Inter 700 15px −0.3px
  static TextStyle get headlineSmall => AuroraType.h3;

  // ─── Legacy aliases ──────────────────────────────────────────────────────────

  static TextStyle get h1 => AuroraType.h1;
  static TextStyle get h2 => AuroraType.h2;
  static TextStyle get h3 => AuroraType.h3;

  /// Inter 600 14px
  static TextStyle get h4 => titleSmall;

  // ─── Titles — Inter ──────────────────────────────────────────────────────────

  /// Inter 700 16px
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AuroraColors.ink,
      );

  /// Inter 700 14px
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AuroraColors.ink,
      );

  // ─── Body — Inter ────────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => AuroraType.bodyLg;
  static TextStyle get bodyMedium => AuroraType.body;
  static TextStyle get bodySmall => AuroraType.bodySm;

  /// Inter 600 14px
  static TextStyle get bodyLargeSemibold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  /// Inter 600 13px
  static TextStyle get bodyMediumSemibold => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  // ─── Labels — Inter ──────────────────────────────────────────────────────────

  /// Inter 600 13px
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  /// Inter 600 12px
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  /// Inter 600 10px
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  /// Inter 600 14px — button text
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  /// Inter 400 12px — timestamps, metadata, fine print
  static TextStyle get caption => AuroraType.bodySm.copyWith(
        color: AuroraColors.inkSecondary,
      );

  // ─── Mono (was IBM Plex Mono — now JetBrains Mono) ──────────────────────────

  /// JetBrains Mono 600 13px — score numbers, large data values.
  static TextStyle get monoDisplay => AuroraType.number;

  /// JetBrains Mono 500 10px — dates, counts, field values.
  static TextStyle get monoLabel => AuroraType.label;

  /// JetBrains Mono 500 10px +1.2px — section labels (render UPPERCASE).
  static TextStyle get monoSection => AuroraType.label;

  /// JetBrains Mono 600 9px — tiny badges, micro labels.
  static TextStyle get monoTiny => AuroraType.labelSm;
}
