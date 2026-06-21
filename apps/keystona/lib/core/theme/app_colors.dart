import 'package:flutter/material.dart';

import 'aurora_colors.dart';

/// Bridge layer — maps all v1 "warm editorial" token names to Aurora v2 values.
///
/// Every token here forwards to [AuroraColors]. During the screen-by-screen
/// migration, callers switch directly to AuroraColors; this file is deleted
/// once all feature screens are updated.
abstract final class AppColors {
  // ─── Surfaces ───────────────────────────────────────────────────────────────

  static const Color warmOffWhite = AuroraColors.paper;
  static const Color surface = AuroraColors.paper;
  static const Color cardBackground = AuroraColors.paper;
  static const Color warmFill = AuroraColors.butter;
  static const Color warmInset = AuroraColors.butter;
  static const Color surfaceVariant = AuroraColors.butter;

  // ─── Primary brand dark ──────────────────────────────────────────────────────

  static const Color deepNavy = AuroraColors.ink;

  // ─── Primary accent ──────────────────────────────────────────────────────────

  static const Color accent = AuroraColors.coral;
  static const Color accentDim = AuroraColors.coralDim;
  static const Color accentOverlay = AuroraColors.coralDim;

  // ─── Semantic accents ────────────────────────────────────────────────────────

  /// v1 olive → Aurora lime (complete hue shift; intentional)
  static const Color olive = AuroraColors.lime;
  static const Color oliveLight = AuroraColors.lime;
  static const Color oliveDim = AuroraColors.limeDim;

  /// v1 slate → Aurora cobalt
  static const Color slate = AuroraColors.cobalt;
  static const Color slateDim = AuroraColors.cobaltDim;

  /// v1 sand / amber → Aurora yellow
  static const Color sand = AuroraColors.yellow;
  static const Color sandDim = AuroraColors.yellowDim;
  static const Color sandAmber = AuroraColors.yellowDeep;
  static const Color goldAccent = AuroraColors.yellow;
  static const Color amber = AuroraColors.yellow;
  static const Color amberDim = AuroraColors.yellowDim;

  /// v1 plum → deprecated; reassigned to cobalt
  static const Color plum = AuroraColors.cobalt;
  static const Color plumDim = AuroraColors.cobaltDim;

  /// v1 teal → deprecated; reassigned to cobalt
  static const Color teal = AuroraColors.cobalt;
  static const Color tealDim = AuroraColors.cobaltDim;

  // ─── Status colors ───────────────────────────────────────────────────────────

  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);

  static const Color success = AuroraColors.limeDeep;
  static const Color successLight = AuroraColors.limeDim;

  static const Color warning = AuroraColors.yellow;
  static const Color warningLight = AuroraColors.yellowDim;

  static const Color info = AuroraColors.cobalt;
  static const Color infoLight = AuroraColors.cobaltDim;

  // ─── Task status ─────────────────────────────────────────────────────────────

  static const Color statusOverdue = AuroraColors.coral;
  static const Color statusDueToday = AuroraColors.yellow;
  static const Color statusDueSoon = AuroraColors.yellow;
  static const Color statusScheduled = AuroraColors.cobalt;
  static const Color statusCompleted = AuroraColors.limeDeep;

  // ─── Health score ────────────────────────────────────────────────────────────

  static const Color healthGood = AuroraColors.scoreGreen;
  static const Color healthFair = AuroraColors.scoreGold;
  static const Color healthPoor = AuroraColors.coral;

  // ─── Neutral scale (ink-based, replacing warm grays) ─────────────────────────

  static const Color gray50 = Color(0xFFF8F8FA);
  static const Color gray100 = AuroraColors.butter;
  static const Color gray200 = Color(0xFFEEEDF2);
  static const Color gray300 = Color(0xFFE0DFEA);
  static const Color gray400 = Color(0xFFC4C3D0);
  static const Color gray500 = Color(0xFF9D9BB0);
  static const Color gray600 = Color(0xFF6B6980);
  static const Color gray700 = Color(0xFF3D3C55);
  static const Color gray800 = Color(0xFF1E1D38);
  static const Color gray900 = AuroraColors.ink;

  // ─── Text ────────────────────────────────────────────────────────────────────

  static const Color textPrimary = AuroraColors.ink;
  static const Color textSecondary = AuroraColors.inkSecondary;
  static const Color textTertiary = AuroraColors.inkTertiary;
  static const Color textDisabled = AuroraColors.inkTertiary;

  /// White text on dark/coral surfaces.
  static const Color textInverse = Color(0xFFFFFFFF);

  // ─── Borders ─────────────────────────────────────────────────────────────────

  static const Color border = AuroraColors.inkBorder;
  static const Color borderStrong = AuroraColors.inkBorderStrong;
  static const Color divider = AuroraColors.inkBorder;

  // ─── Seasonal / forest (deprecated — mapped to ink palette) ──────────────────

  static const Color forestGreen = AuroraColors.ink;
  static const Color forestGreenLight = AuroraColors.cobalt;

  // ─── Contractor story (ink-based) ────────────────────────────────────────────

  static const Color contractorCardBg = AuroraColors.ink;
  static const Color contractorBlockBg = Color(0xFF0E1530);
  static const Color contractorCardBorder = Color(0xFF141D3B);
  static const Color contractorAvatarBg = Color(0xFF2D3A6B);
  static const Color contractorLeadBg = AuroraColors.cobaltDim;
  static const Color contractorStatLabel = AuroraColors.inkSecondary;
  static const Color contractorMuted = AuroraColors.inkTertiary;

  // ─── Photo / media overlays (intentional exceptions — pure black) ─────────────

  static const Color photoOverlayTint = Color(0xCC000000);
  static const Color photoGridOverlayPair = Color(0x80000000);
  static const Color photoGridOverlayLink = Color(0x66000000);
  static const Color photoGridOverlayGradient = Color(0xCC000000);
  static const Color photoGridCaptionText = Color(0xEBFFFFFF);
  static const Color photoPlaceholder = AuroraColors.butter;

  // ─── Shadows ─────────────────────────────────────────────────────────────────

  static const Color shadowXs = Color(0x0A071238); // ink 4%
  static const Color shadowSm = Color(0x0D071238); // ink 5%
  static const Color shadowMd = Color(0x14000000);
  static const Color darkTrack = Color(0x14FFFFFF);
  static const Color fabShadow = Color(0x59FF3B62); // coral 35%

  // ─── Photo type badges (updated to Aurora palette) ────────────────────────────

  static const Color photoBadgeBeforeBg = AuroraColors.cobaltDim;
  static const Color photoBadgeBeforeFg = AuroraColors.cobaltDeep;
  static const Color photoBadgeAfterBg = AuroraColors.limeDim;
  static const Color photoBadgeAfterFg = AuroraColors.limeDeep;
  static const Color photoBadgeProgressBg = AuroraColors.yellowDim;
  static const Color photoBadgeProgressFg = AuroraColors.yellowDeep;
  static const Color photoBadgeInspirationBg = AuroraColors.coralDim;
  static const Color photoBadgeInspirationFg = AuroraColors.coralDeep;
  static const Color photoBadgeOtherBg = AuroraColors.butter;
  static const Color photoBadgeOtherFg = AuroraColors.inkSecondary;

  // ─── File type icon backgrounds ───────────────────────────────────────────────

  static const Color fileTypePdfBg = AuroraColors.coralDim;
  static const Color fileTypeImageBg = AuroraColors.limeDim;
  static const Color fileTypeHeicBg = AuroraColors.cobaltDim;
  static const Color fileTypeDocBg = AuroraColors.cobaltDim;

  // ─── App-specific ─────────────────────────────────────────────────────────────

  static const Color paywallGradientMid = AuroraColors.cobalt;
  static const Color avatarGradientStart = AuroraColors.coral;

  /// iOS system success green — completion animations only.
  static const Color iosSuccessGreen = Color(0xFF34C759);

  static const Color overdueTaskBg = AuroraColors.coralDim;
  static const Color overdueTaskBorder = AuroraColors.coral;

  static const Color trialBannerBg = AuroraColors.yellowDim;
  static const Color trialBannerText = AuroraColors.yellowDeep;

  static const Color uploadSuccessBg = AuroraColors.limeDim;

  static const Color navHairline = AuroraColors.inkBorder;
  static const Color navBarBg = Color(0xEBFFFFFF); // paper 92%

  // ─── Dark hero (now ink-based, not warm brown) ────────────────────────────────

  static const Color darkBackground = AuroraColors.ink;
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0x8CFFFFFF); // white 55%
  static const Color darkTextTertiary = Color(0x59FFFFFF); // white 35%
  static const Color darkBorder = Color(0x1AFFFFFF); // white 10%
}
