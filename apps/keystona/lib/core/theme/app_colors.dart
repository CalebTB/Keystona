import 'package:flutter/material.dart';

/// Keystona semantic color palette — Editorial Warm design system.
///
/// Every color in the app must reference a constant from this class.
/// Never hardcode hex values in widgets or theme files.
abstract final class AppColors {
  // ─── Brand Surfaces ─────────────────────────────────────────────────────────

  /// App scaffold background — warm off-white. #F3F0EB
  static const Color warmOffWhite = Color(0xFFF3F0EB);

  /// Card backgrounds — pure white. #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);

  /// Alias for [surface] used in card widgets. #FFFFFF
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Inset backgrounds, section dividers, secondary fills. #E9E4DC
  static const Color warmFill = Color(0xFFE9E4DC);

  /// Deeper insets, progress bar tracks, toggle-off states. #E2DDD4
  static const Color warmInset = Color(0xFFE2DDD4);

  /// Alias for [warmFill] used in older widgets. #E9E4DC
  static const Color surfaceVariant = Color(0xFFE9E4DC);

  // ─── Primary Brand Dark ─────────────────────────────────────────────────────

  /// Dark warm brown — dark hero blocks, property header backgrounds, nav text.
  /// #2A2420  (replaces old navy blue in all dark-surface contexts)
  static const Color deepNavy = Color(0xFF2A2420);

  // ─── Primary Accent ──────────────────────────────────────────────────────────

  /// Terracotta — primary CTA, active tab indicator, overdue states. #B85638
  static const Color accent = Color(0xFFB85638);

  /// Dim fill for terracotta accent (≈7% opacity). #12B85638
  static const Color accentDim = Color(0x12B85638);

  // ─── Semantic Accents ────────────────────────────────────────────────────────

  /// Olive — success, completion, healthy states, secondary CTAs. #5A7050
  static const Color olive = Color(0xFF5A7050);

  /// Olive Light — score fills, positive indicators on dark backgrounds. #82A876
  static const Color oliveLight = Color(0xFF82A876);

  /// Olive dim (≈7% opacity). #125A7050
  static const Color oliveDim = Color(0x125A7050);

  /// Slate — information, scheduled states, project indicators. #506A80
  static const Color slate = Color(0xFF506A80);

  /// Slate dim (≈7% opacity). #12506A80
  static const Color slateDim = Color(0x12506A80);

  /// Sand — aging/warning states, financial indicators, premium badge. #B8A060
  static const Color sand = Color(0xFFB8A060);

  /// Sand dim (≈8% opacity). #14B8A060
  static const Color sandDim = Color(0x14B8A060);

  /// Gold Accent alias → maps to [sand] for backward compatibility. #B8A060
  static const Color goldAccent = Color(0xFFB8A060);

  /// Plum — insurance, document type indicators, manuals. #7B5E7B
  static const Color plum = Color(0xFF7B5E7B);

  /// Plum dim (≈7% opacity). #127B5E7B
  static const Color plumDim = Color(0x127B5E7B);

  /// Teal — plumbing, water-related, financial documents. #4A8078
  static const Color teal = Color(0xFF4A8078);

  /// Teal dim (≈7% opacity). #124A8078
  static const Color tealDim = Color(0x124A8078);

  /// Amber — gas-related, warranty badges, favorite indicators. #B8923D
  static const Color amber = Color(0xFFB8923D);

  /// Amber dim (≈8% opacity). #14B8923D
  static const Color amberDim = Color(0x14B8923D);

  // ─── Status Colors ──────────────────────────────────────────────────────────

  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Success → olive. #5A7050
  static const Color success = Color(0xFF5A7050);

  /// Success light → olive dim.
  static const Color successLight = Color(0x125A7050);

  /// Warning → amber. #B8923D
  static const Color warning = Color(0xFFB8923D);

  /// Warning light → amber dim.
  static const Color warningLight = Color(0x14B8923D);

  /// Info → slate. #506A80
  static const Color info = Color(0xFF506A80);

  /// Info light → slate dim.
  static const Color infoLight = Color(0x12506A80);

  // ─── Task Status ────────────────────────────────────────────────────────────

  /// Overdue — terracotta accent.
  static const Color statusOverdue = Color(0xFFB85638);

  /// Due today — amber.
  static const Color statusDueToday = Color(0xFFB8923D);

  /// Due soon (≤7 days) — sand.
  static const Color statusDueSoon = Color(0xFFB8A060);

  /// Scheduled (future) — slate.
  static const Color statusScheduled = Color(0xFF506A80);

  /// Completed — olive.
  static const Color statusCompleted = Color(0xFF5A7050);

  // ─── Health Score ───────────────────────────────────────────────────────────

  /// Good (71–100) — olive.
  static const Color healthGood = Color(0xFF5A7050);

  /// Fair (40–70) — sand.
  static const Color healthFair = Color(0xFFB8A060);

  /// Poor (0–39) — accent/terracotta.
  static const Color healthPoor = Color(0xFFB85638);

  // ─── Neutral Scale (warm-tinted grays) ──────────────────────────────────────

  static const Color gray50  = Color(0xFFFBF9F6);
  static const Color gray100 = Color(0xFFF5F1EB);
  static const Color gray200 = Color(0xFFEDE8E0);
  static const Color gray300 = Color(0xFFDDD7CE);
  static const Color gray400 = Color(0xFFCBC4B8);
  static const Color gray500 = Color(0xFF9E9488);
  static const Color gray600 = Color(0xFF6B6058);
  static const Color gray700 = Color(0xFF4A3F36);
  static const Color gray800 = Color(0xFF352C24);
  static const Color gray900 = Color(0xFF2A2420);

  // ─── Text ───────────────────────────────────────────────────────────────────

  /// Primary text — warm near-black. #2A2420
  static const Color textPrimary = Color(0xFF2A2420);

  /// Secondary text — warm medium brown. #6B6058
  static const Color textSecondary = Color(0xFF6B6058);

  /// Tertiary text — labels, metadata, timestamps, placeholders. #3D3830
  static const Color textTertiary = Color(0xFF3D3830);

  /// Disabled text.
  static const Color textDisabled = Color(0xFFCBC4B8);

  /// Inverse text — used on dark hero blocks. #F3F0EB
  static const Color textInverse = Color(0xFFF3F0EB);

  // ─── Borders ────────────────────────────────────────────────────────────────

  /// Default card and field border. #DDD7CE
  static const Color border = Color(0xFFDDD7CE);

  /// Emphasized border — hover / active states. #CBC4B8
  static const Color borderStrong = Color(0xFFCBC4B8);

  /// List dividers — slightly lighter than border. #E9E4DC
  static const Color divider = Color(0xFFE9E4DC);

  // ─── Dark Hero Block ────────────────────────────────────────────────────────

  /// Dark hero block background (= textPrimary). #2A2420
  static const Color darkBackground = Color(0xFF2A2420);

  /// Primary text on dark backgrounds. #F3F0EB
  static const Color darkText = Color(0xFFF3F0EB);

  /// Secondary text on dark backgrounds (45% opacity). rgba(243,240,235,0.45)
  static const Color darkTextSecondary = Color(0x73F3F0EB);

  /// Tertiary text on dark backgrounds (35% opacity). rgba(243,240,235,0.35)
  static const Color darkTextTertiary = Color(0x59F3F0EB);

  /// Subtle border on dark backgrounds (6% opacity).
  static const Color darkBorder = Color(0x0FFFFFFF);
}
