import 'package:flutter/material.dart';

/// Spacing, sizing, and layout constants for the Keystona design system.
///
/// Built on a 4px base grid. All spacing values are multiples of 4.
/// Import this class — never hardcode numeric size values in widgets.
abstract final class AppSizes {
  // ─── Spacing ────────────────────────────────────────────────────────────────

  /// 4px — micro gaps, icon-to-label spacing.
  static const double xs = 4;

  /// 8px — tight internal padding, inline gaps.
  static const double sm = 8;

  /// 16px — standard card and screen padding.
  static const double md = 16;

  /// 24px — section spacing, generous card gaps.
  static const double lg = 24;

  /// 32px — large structural gaps between sections.
  static const double xl = 32;

  /// 48px — hero spacing, empty state illustration gaps.
  static const double xxl = 48;

  // ─── Border Radii ───────────────────────────────────────────────────────────

  /// 8px — buttons, chips, input fields, small cards.
  static const double radiusSm = 8;

  /// 12px — standard cards, bottom sheets.
  static const double radiusMd = 12;

  /// 16px — large cards, modal sheets.
  static const double radiusLg = 16;

  /// 24px — pill badges, large rounded containers.
  static const double radiusXl = 24;

  /// 999px — fully circular / pill shapes.
  static const double radiusFull = 999;

  // ─── Standard Paddings ──────────────────────────────────────────────────────

  /// Horizontal and vertical screen edge padding (16px).
  static const double screenPadding = 16;

  /// Internal card content padding (16px).
  static const double cardPadding = 16;

  /// Vertical space between major page sections (24px).
  static const double sectionSpacing = 24;

  // ─── Icon Sizes ─────────────────────────────────────────────────────────────

  /// 16px — inline icons next to text, badge icons.
  static const double iconSm = 16;

  /// 24px — standard toolbar, list, and button icons.
  static const double iconMd = 24;

  /// 32px — section header icons, featured list icons.
  static const double iconLg = 32;

  /// 48px — empty state illustrations, onboarding icons.
  static const double iconXl = 48;

  // ─── Component Heights ──────────────────────────────────────────────────────

  /// 52px — all primary and secondary button heights.
  static const double buttonHeight = 52;

  /// 52px — text input and dropdown field height.
  static const double inputHeight = 52;

  /// 60px — bottom navigation bar height (excludes safe area).
  static const double bottomNavHeight = 60;

  /// 56px — app bar / navigation bar height.
  static const double appBarHeight = 56;

  /// 72px — minimum card height for list tiles and summary rows.
  static const double cardMinHeight = 72;
}

/// Pre-built [BorderRadius] helpers referencing [AppSizes] radii.
///
/// Use these instead of calling [BorderRadius.circular] with raw values.
abstract final class AppRadius {
  /// 8px circular radius — buttons, inputs, small surfaces.
  static final BorderRadius sm = BorderRadius.circular(AppSizes.radiusSm);

  /// 12px circular radius — standard cards and sheets.
  static final BorderRadius md = BorderRadius.circular(AppSizes.radiusMd);

  /// 16px circular radius — large cards, modals.
  static final BorderRadius lg = BorderRadius.circular(AppSizes.radiusLg);

  /// 24px circular radius — pill containers, large badges.
  static final BorderRadius xl = BorderRadius.circular(AppSizes.radiusXl);
}

/// Pre-built [EdgeInsets] helpers referencing [AppSizes] spacing.
///
/// Use these instead of constructing [EdgeInsets] inline in widgets.
abstract final class AppPadding {
  /// All-sides screen padding (16px).
  static const EdgeInsets screen = EdgeInsets.all(AppSizes.screenPadding);

  /// Horizontal-only screen padding (16px left/right).
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: AppSizes.screenPadding);

  /// All-sides card internal padding (16px).
  static const EdgeInsets card = EdgeInsets.all(AppSizes.cardPadding);

  /// Button content padding — 24px horizontal, 16px vertical.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSizes.lg,
    vertical: AppSizes.md,
  );
}
