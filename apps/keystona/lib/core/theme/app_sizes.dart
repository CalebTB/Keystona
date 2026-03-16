import 'package:flutter/material.dart';

/// Spacing, sizing, and layout constants for the Keystona Editorial Warm
/// design system.
///
/// Built on a 4px base grid. All spacing values are multiples of 4 (or close
/// to it). Import this class — never hardcode numeric size values in widgets.
abstract final class AppSizes {
  // ─── Spacing ────────────────────────────────────────────────────────────────

  /// 4px — micro gaps, icon-to-label spacing.
  static const double xs = 4;

  /// 8px — tight internal padding, inline gaps, inter-card gaps.
  static const double sm = 8;

  /// 16px — standard card internal padding.
  static const double md = 16;

  /// 24px — section spacing, generous card gaps.
  static const double lg = 24;

  /// 32px — large structural gaps between sections.
  static const double xl = 32;

  /// 48px — hero spacing, empty state illustration gaps.
  static const double xxl = 48;

  // ─── Border Radii ───────────────────────────────────────────────────────────

  /// 6px — badges, tags, small chips.
  static const double radiusXs = 6;

  /// 10px — small elements, inner chips, icon containers.
  static const double radiusSm = 10;

  /// 12px — buttons, inputs, inner cards.
  static const double radiusMd = 12;

  /// 14px — standard cards (the primary card radius).
  static const double radiusCard = 14;

  /// 16px — large cards, hero blocks.
  static const double radiusLg = 16;

  /// 20px — bottom sheet top corners, filter chips.
  static const double radiusXl = 20;

  /// 999px — fully circular / pill shapes.
  static const double radiusFull = 999;

  // ─── Standard Paddings ──────────────────────────────────────────────────────

  /// Horizontal screen edge padding — 22px (editorial warm spec).
  static const double screenPadding = 22;

  /// Internal card content padding — 14px.
  static const double cardPadding = 14;

  /// Vertical space between major page sections — 20px.
  static const double sectionSpacing = 20;

  /// Gap between cards in a list — 6px.
  static const double cardGap = 6;

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

  /// 48px — primary and secondary button heights.
  static const double buttonHeight = 48;

  /// 50px — text input and dropdown field height.
  static const double inputHeight = 50;

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
  /// 10px circular radius — small elements, inner chips.
  static final BorderRadius sm = BorderRadius.circular(AppSizes.radiusSm);

  /// 12px circular radius — buttons and inputs.
  static final BorderRadius md = BorderRadius.circular(AppSizes.radiusMd);

  /// 14px circular radius — standard cards (primary card radius).
  static final BorderRadius card = BorderRadius.circular(AppSizes.radiusCard);

  /// 16px circular radius — large cards, hero blocks.
  static final BorderRadius lg = BorderRadius.circular(AppSizes.radiusLg);

  /// 20px circular radius — bottom sheet corners, filter chips.
  static final BorderRadius xl = BorderRadius.circular(AppSizes.radiusXl);
}

/// Pre-built [EdgeInsets] helpers referencing [AppSizes] spacing.
///
/// Use these instead of constructing [EdgeInsets] inline in widgets.
abstract final class AppPadding {
  /// All-sides screen padding (22px).
  static const EdgeInsets screen =
      EdgeInsets.all(AppSizes.screenPadding);

  /// Horizontal-only screen padding (22px left/right).
  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: AppSizes.screenPadding);

  /// All-sides card internal padding (14px).
  static const EdgeInsets card = EdgeInsets.all(AppSizes.cardPadding);

  /// Button content padding — 20px horizontal, 14px vertical.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSizes.lg - 4, // 20px
    vertical: AppSizes.md - 2,   // 14px
  );
}
