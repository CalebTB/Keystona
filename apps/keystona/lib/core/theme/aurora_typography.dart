import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aurora_colors.dart';

/// Aurora Design System v2.0 — typography.
///
/// Inter for everything. JetBrains Mono for labels, dates, numbers.
/// No serif. No display font. Color carries personality; type stays neutral.
///
/// All label/labelSm callers MUST call `.toUpperCase()` on their text content —
/// Flutter has no native textTransform, so uppercase is applied at the call site.
abstract final class AuroraType {
  // ─── Inter — body, headings, buttons ────────────────────────────────────────

  /// 46px 800 −1.8px — score hero number.
  static TextStyle get displayXl => GoogleFonts.inter(
        fontSize: 46,
        fontWeight: FontWeight.w800,
        height: 0.9,
        letterSpacing: -1.8,
        color: AuroraColors.ink,
      );

  /// 36px 800 −1.2px — item count headers, big callouts.
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.2,
        color: AuroraColors.ink,
      );

  /// 22px 700 −0.7px — screen greeting, screen title.
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -0.7,
        color: AuroraColors.ink,
      );

  /// 18px 600 −0.4px — section headings within a screen.
  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.4,
        color: AuroraColors.ink,
      );

  /// 15px 700 −0.3px — card titles, list-item primary names.
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
        color: AuroraColors.ink,
      );

  /// 14px 400 — body copy emphasis.
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.ink,
      );

  /// 13px 400 — default body copy.
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AuroraColors.ink,
      );

  /// 12px 400 — captions, secondary descriptions.
  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AuroraColors.ink,
      );

  // ─── JetBrains Mono — labels, eyebrows, numbers ─────────────────────────────

  /// 10px 500 +1.2px — mono eyebrow/label. ALWAYS render uppercase at call site.
  static TextStyle get label => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 1.2,
        color: AuroraColors.inkSecondary,
      );

  /// 9px 600 +0.8px — micro-labels (status chips). ALWAYS uppercase at call site.
  static TextStyle get labelSm => GoogleFonts.jetBrainsMono(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.8,
        color: AuroraColors.inkSecondary,
      );

  /// 13px 600 — all inline numbers (dates, counts, prices).
  static TextStyle get number => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AuroraColors.ink,
      );
}
