import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Aurora kit tokens for the sign-in screens (splash, welcome, sign up, check
/// your email, log in, forgot password). Sizes are logical px at the 390 pt
/// reference width and are read through `context.aurora`.

/// Colors that only the sign-in screens use.
abstract final class AuroraAuthColors {
  /// Sign in with Apple button fill (Apple brand: black).
  static const Color appleFill = Color(0xFF000000);

  /// Sign in with Google button label (Google brand: near-black).
  static const Color googleLabel = Color(0xFF1F1F1F);

  /// Grid lines on the coral splash. (white 0.14)
  static const Color gridOnCoral = Color(0x24FFFFFF);

  /// Grid lines on paper (welcome backdrop, check-email tile). (coral 0.12)
  static const Color gridOnPaper = Color(0x1FFF3B62);

  /// Splash tagline. (white 0.80)
  static const Color onCoralTagline = Color(0xCCFFFFFF);

  /// Splash progress track. (white 0.30)
  static const Color onCoralTrack = Color(0x4DFFFFFF);

  /// Splash logo tile lift. (ink 0.22)
  static const Color logoShadow = Color(0x38071238);

  /// Outline of the check-email tile. (coral 0.35)
  static const Color coralOutline = Color(0x59FF3B62);
}

/// Sizes that only the sign-in screens use.
abstract final class AuroraAuthSizes {
  /// Splash logo tile edge, glyph and corner radius.
  static const double splashTile = 96;
  static const double splashGlyph = 64;
  static const double splashTileRadius = 26;

  /// Splash progress bar.
  static const double splashBarWidth = 120;
  static const double splashBarHeight = 3;

  /// Auth button minimum height (kit: 52) — a minimum, never fixed.
  static const double buttonHeight = 52;

  /// Splash progress bar fill (kit frame: 45%).
  static const double splashBarFill = 0.45;

  /// Splash progress bar distance from the bottom edge.
  static const double splashBarBottom = 72;

  /// Splash logo lift.
  static const double splashShadowBlur = 40;
  static const double splashShadowOffset = 18;

  /// Distance between grid lines on splash and welcome.
  static const double gridCell = 22;

  /// Distance between grid lines on the check-email tile.
  static const double tileGridCell = 11;

  /// Grid line thickness.
  static const double gridLine = 1;

  /// Welcome wordmark glyph.
  static const double wordmarkGlyph = 30;

  /// Welcome backdrop height as a share of the screen height (470 / 844).
  static const double welcomeGridFraction = 0.56;

  /// Where the welcome grid starts to fade out, as a share of its height.
  static const double welcomeGridFadeStart = 0.55;

  /// Where the splash grid fades out, as a share of the screen radius.
  static const double splashGridFadeStart = 0.2;
  static const double splashGridFadeEnd = 0.75;

  /// Check-email tile edge, radius and envelope glyph.
  static const double checkTile = 88;
  static const double checkTileRadius = 24;
  static const double checkGlyph = 40;

  /// Gap above the check-email tile (kit: 72).
  static const double checkTop = 72;

  /// Gap between the check-email tile and its title block.
  static const double checkGap = 22;

  /// Back chevron glyph.
  static const double backGlyph = 22;

  /// Password rule bullet and the check inside it.
  static const double ruleDot = 16;
  static const double ruleCheck = 10;

  /// Status check bubble on the "sent" states.
  static const double sentBubble = 20;
  static const double sentBubbleLg = 22;
  static const double sentCheck = 11;

  /// Info glyph on the forgot-password hint.
  static const double hintGlyph = 18;

  /// Page padding: left/right, top (under the status bar) and bottom.
  static const double pagePadH = 24;
  static const double pagePadTop = 8;
  static const double pagePadBottom = 34;

  /// Gap between the sections of a page (header, form, actions).
  static const double sectionGap = 22;

  /// Gap between the title and its sub copy.
  static const double titleGap = 8;

  /// Gap between stacked fields.
  static const double fieldGap = 16;

  /// Gap between stacked buttons.
  static const double buttonGap = 12;

  /// Gap above the welcome wordmark (under the status bar).
  static const double welcomeTop = 32;

  /// Vertical centre of the splash logo block (share of the screen height).
  static const double splashFocusY = 0.45;
}

/// Timing for the sign-in screens.
abstract final class AuroraAuthTiming {
  /// How long the splash holds before moving on to welcome.
  static const Duration splashHold = Duration(milliseconds: 1800);

  /// Seconds before "Resend email" is offered again.
  static const int resendCooldownSeconds = 60;

  /// One tick of the resend countdown.
  static const Duration tick = Duration(seconds: 1);
}

/// Geometry of the Keystona mark in its 40 x 40 view box (kit SVG).
abstract final class AuroraLogoGeometry {
  static const double viewBox = 40;

  /// Keystone body: M9 6 h22 l-5 28 h-12 z.
  static const double topLeftX = 9;
  static const double topY = 6;
  static const double topRightX = 31;
  static const double bottomRightX = 26;
  static const double bottomY = 34;
  static const double bottomLeftX = 14;

  /// Bar: M16 16 h8, stroke 2.6.
  static const double barStartX = 16;
  static const double barEndX = 24;
  static const double barY = 16;
  static const double barStroke = 2.6;
}

/// Type styles that only the sign-in screens use.
abstract final class AuroraAuthType {
  /// 28/800 -0.9 — screen title on sign up, log in, forgot, check email.
  static TextStyle get title => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.9,
        color: AuroraColors.ink,
      );

  /// 16/600 — auth button label.
  static TextStyle get button => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AuroraColors.ink,
      );

  /// 11/500 coral-deep, sentence case — field error under an input.
  static TextStyle get fieldError => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AuroraColors.coralDeep,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// 34/800 -1.2 — welcome headline.
  static TextStyle get hero => const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.2,
        color: AuroraColors.ink,
      );

  /// 16/400 — welcome sub copy.
  static TextStyle get heroBody => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AuroraColors.inkSubtle,
      );

  /// 15/400 — sub copy under a screen title.
  static TextStyle get subtitle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AuroraColors.inkSubtle,
      );

  /// 22/800 -0.6 — welcome wordmark.
  static TextStyle get wordmark => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AuroraColors.ink,
      );

  /// 34/800 -1 — splash wordmark.
  static TextStyle get splashWordmark => const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: AuroraColors.paper,
      );

  /// 10.5/700 +2 — splash tagline. Uppercase in the copy.
  static TextStyle get splashTagline => const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AuroraAuthColors.onCoralTagline,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// 15/400 — "Already have an account?" and similar prompts.
  static TextStyle get prompt => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AuroraColors.inkSubtle,
      );

  /// 15/600 coral-deep — inline link next to a prompt.
  static TextStyle get link => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AuroraColors.coralDeep,
      );

  /// 14/600 coral-deep — "Forgot password?".
  static TextStyle get linkSm => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuroraColors.coralDeep,
      );

  /// 15/600 ink 60% — quiet text action ("Use a different email").
  static TextStyle get quiet => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AuroraColors.inkSubtle,
      );

  /// 14/600 ink 60% — Show / Hide on the password field.
  static TextStyle get reveal => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AuroraColors.inkSubtle,
      );

  /// 13/400 — password rule row.
  static TextStyle get rule => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: AuroraColors.inkSecondary,
      );

  /// 10/500 +0.3 — "By continuing you agree" legal line.
  static TextStyle get legal => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0.3,
        color: AuroraColors.inkSecondary,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  /// 15/600 — status message inside a "sent" card.
  static TextStyle get sentTitle => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AuroraColors.ink,
      );

  /// 14/400 — status body inside a "sent" card.
  static TextStyle get sentBody => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AuroraColors.inkSubtle,
      );
}
