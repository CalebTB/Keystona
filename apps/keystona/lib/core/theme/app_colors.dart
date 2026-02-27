import 'package:flutter/material.dart';

/// Keystona semantic color palette.
///
/// Every color in the app must reference a constant from this class.
/// Never hardcode hex values in widgets or theme files.
abstract final class AppColors {
  // ─── Brand ──────────────────────────────────────────────────────────────────
  static const Color deepNavy = Color(0xFF1A2B4A);
  static const Color goldAccent = Color(0xFFC9A84C);
  static const Color warmOffWhite = Color(0xFFFAF8F5);

  // ─── Status ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);

  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);

  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── Task Status ────────────────────────────────────────────────────────────
  /// Task is overdue — past due date and not completed.
  static const Color statusOverdue = Color(0xFFD32F2F);

  /// Task is due today.
  static const Color statusDueToday = Color(0xFFF57C00);

  /// Task is due within the next 7 days.
  static const Color statusDueSoon = Color(0xFFFFC107);

  /// Task is scheduled for a future date beyond 7 days.
  static const Color statusScheduled = Color(0xFF1976D2);

  /// Task has been completed.
  static const Color statusCompleted = Color(0xFF388E3C);

  // ─── Health Score ───────────────────────────────────────────────────────────
  /// Home Health Score 71–100: good standing.
  static const Color healthGood = Color(0xFF388E3C);

  /// Home Health Score 40–70: fair standing, needs attention.
  static const Color healthFair = Color(0xFFFFC107);

  /// Home Health Score 0–39: poor standing, urgent action needed.
  static const Color healthPoor = Color(0xFFD32F2F);

  // ─── Gray Scale ─────────────────────────────────────────────────────────────
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // ─── Text ───────────────────────────────────────────────────────────────────
  /// Primary text — near-black for headings and high-emphasis body.
  static const Color textPrimary = Color(0xFF1C1C1E);

  /// Secondary text — medium gray for subtitles, captions, hints.
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Disabled text — light gray for inactive or disabled UI.
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// Inverse text — white for use on dark backgrounds.
  static const Color textInverse = Color(0xFFFFFFFF);

  // ─── Surface ────────────────────────────────────────────────────────────────
  /// Primary surface — pure white for cards and sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// Variant surface — very light gray for secondary containers.
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Standard border — light gray for card and input borders.
  static const Color border = Color(0xFFE0E0E0);

  /// Divider — slightly lighter than border for list separators.
  static const Color divider = Color(0xFFEEEEEE);
}
