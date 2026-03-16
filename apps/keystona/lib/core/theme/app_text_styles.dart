import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Pre-built [TextStyle] definitions for the Keystona Editorial Warm design
/// system.
///
/// **Font stack:**
/// - **Fraunces** (serif) — display and headlines
/// - **Inter** (sans-serif) — body, labels, UI text
/// - **IBM Plex Mono** — numbers, dates, data, section labels
///
/// All getters default to [AppColors.textPrimary].
/// Use `.copyWith(color: ...)` to override per-widget.
abstract final class AppTextStyles {
  // ─── Display — Fraunces ──────────────────────────────────────────────────────

  /// Fraunces 900 32px −1.2px — welcome screen title, hero numbers.
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      );

  /// Fraunces 800 28px −0.7px — screen titles ("Tasks", "Home Profile").
  static TextStyle get displayMedium => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: AppColors.textPrimary,
      );

  /// Fraunces 800 24px −0.6px — section hero titles, step labels.
  static TextStyle get displaySmall => GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      );

  // ─── Headlines — Fraunces ────────────────────────────────────────────────────

  /// Fraunces 700 18px −0.3px — card titles, section headers.
  static TextStyle get headlineMedium => GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  /// Fraunces 700 16px — inline titles (shutoff names, system names).
  static TextStyle get headlineSmall => GoogleFonts.fraunces(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      );

  // ─── Legacy headline aliases ─────────────────────────────────────────────────

  /// Alias for [displaySmall] — Fraunces 800 24px.
  static TextStyle get h1 => displaySmall;

  /// Alias for [headlineMedium] — Fraunces 700 18px.
  static TextStyle get h2 => headlineMedium;

  /// Alias for [headlineSmall] — Fraunces 700 16px.
  static TextStyle get h3 => headlineSmall;

  /// Alias for [titleSmall] — Inter 700 14px.
  static TextStyle get h4 => titleSmall;

  // ─── Titles — Inter ──────────────────────────────────────────────────────────

  /// Inter Bold 16px — navigation bar titles.
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Inter Bold 14px — card item titles, contact names.
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ─── Body — Inter ────────────────────────────────────────────────────────────

  /// Inter Regular 16px — primary reading text.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Inter Regular 14px — standard body, list items.
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Inter Medium 13px — task descriptions, instructions.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Inter SemiBold 16px — emphasized body content.
  static TextStyle get bodyLargeSemibold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Inter SemiBold 14px — emphasized secondary body.
  static TextStyle get bodyMediumSemibold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ─── Labels — Inter ──────────────────────────────────────────────────────────

  /// Inter SemiBold 13px — button labels, form labels.
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Inter SemiBold 12px — chip labels, secondary labels.
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Inter SemiBold 11px — tab labels, badge text, micro labels.
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Inter SemiBold 15px — button text (legacy alias).
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Inter Regular 11px — timestamps, metadata, fine print.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ─── Mono — IBM Plex Mono ────────────────────────────────────────────────────

  /// IBM Plex Mono Bold 16px +0.5px — score numbers, large data values.
  static TextStyle get monoDisplay => GoogleFonts.ibmPlexMono(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      );

  /// IBM Plex Mono SemiBold 11px — dates, costs, field values.
  static TextStyle get monoLabel => GoogleFonts.ibmPlexMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// IBM Plex Mono Bold 10px +1.2px — section labels (render UPPERCASE).
  static TextStyle get monoSection => GoogleFonts.ibmPlexMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textTertiary,
      );

  /// IBM Plex Mono Bold 9px +0.5px — tiny badges, confidence %, sync timestamps.
  static TextStyle get monoTiny => GoogleFonts.ibmPlexMono(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textTertiary,
      );
}
