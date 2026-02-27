import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Pre-built [TextStyle] constants for the Keystona design system.
///
/// Headlines use **Outfit**. Body, labels, and captions use
/// **Plus Jakarta Sans**. All styles default to [AppColors.textPrimary].
///
/// Import this class in every widget instead of constructing raw [TextStyle]
/// instances inline.
abstract final class AppTextStyles {
  // ─── Display ────────────────────────────────────────────────────────────────

  /// Outfit Bold 32px — hero numbers, splash screens, large feature titles.
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Outfit Bold 28px — section hero headings.
  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ─── Headlines ──────────────────────────────────────────────────────────────

  /// Outfit Bold 24px — screen titles, primary card headings.
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Outfit SemiBold 20px — section headings, modal titles.
  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Outfit SemiBold 18px — card headers, list group titles.
  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Outfit SemiBold 16px — sub-section headings, dialog titles.
  static TextStyle get h4 => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ─── Body ───────────────────────────────────────────────────────────────────

  /// Plus Jakarta Sans Regular 16px — primary reading text.
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Plus Jakarta Sans Regular 14px — standard body, list items.
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Plus Jakarta Sans Regular 12px — secondary body, helper text.
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Plus Jakarta Sans SemiBold 16px — emphasized body content.
  static TextStyle get bodyLargeSemibold => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Plus Jakarta Sans SemiBold 14px — emphasized secondary body.
  static TextStyle get bodyMediumSemibold => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ─── Labels ─────────────────────────────────────────────────────────────────

  /// Plus Jakarta Sans Medium 14px — form labels, input labels.
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Plus Jakarta Sans Medium 12px — chip labels, secondary labels.
  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  /// Plus Jakarta Sans Medium 11px — tab labels, badge text, micro labels.
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  // ─── Caption ────────────────────────────────────────────────────────────────

  /// Plus Jakarta Sans Regular 11px — timestamps, metadata, fine print.
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ─── Button ─────────────────────────────────────────────────────────────────

  /// Plus Jakarta Sans SemiBold 15px — all button labels.
  ///
  /// Includes 0.3 letter-spacing for improved legibility at small sizes.
  static TextStyle get button => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );
}
