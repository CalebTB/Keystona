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

  /// Sand Amber — darker sand, budget overages, equipment category. #9B7E3E
  static const Color sandAmber = Color(0xFF9B7E3E);

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

  // ─── Seasonal Hero ──────────────────────────────────────────────────────────

  /// Deep forest green — Seasonal view hero card background. #2A3D28
  static const Color forestGreen = Color(0xFF2A3D28);

  /// Muted olive — Seasonal hero text/icon overlays. #4A6B3C
  static const Color forestGreenLight = Color(0xFF4A6B3C);

  // ─── Contractor Story Card ───────────────────────────────────────────────────

  /// Dark sage green — Contractor story card hero section background. #3D5040
  static const Color contractorCardBg = Color(0xFF3D5040);

  /// Contractor skeleton inner block bg — slightly lighter sage. #2E3D30
  static const Color contractorBlockBg = Color(0xFF2E3D30);

  /// Darker sage — Contractor story card border. #2A3830
  static const Color contractorCardBorder = Color(0xFF2A3830);

  /// Mid sage — Contractor avatar circle background. #4E6452
  static const Color contractorAvatarBg = Color(0xFF4E6452);

  /// Light sage — LEAD badge fill. #B8C9B0
  static const Color contractorLeadBg = Color(0xFFB8C9B0);

  /// Green-tinted label text inside stat cells. #6B7E6D
  static const Color contractorStatLabel = Color(0xFF6B7E6D);

  /// Muted sage — subtitle metadata on dark green header. #8CA88E
  static const Color contractorMuted = Color(0xFF8CA88E);

  // ─── Photo / Media Overlays ─────────────────────────────────────────────────

  /// Near-black darken tint for cover photo overlays (80% opacity). #CC1A1410
  static const Color photoOverlayTint = Color(0xCC1A1410);

  // ─── Const Shadows / Overlays ───────────────────────────────────────────────

  /// Card box shadow — deepNavy at 4% opacity. Use in const BoxShadow. #0A2A2420
  static const Color shadowXs = Color(0x0A2A2420);

  /// Card hover shadow — deepNavy at 5% opacity. Use in const BoxShadow. #0D2A2420
  static const Color shadowSm = Color(0x0D2A2420);

  /// Elevated card shadow — neutral black at 8% opacity. #14000000
  static const Color shadowMd = Color(0x14000000);

  /// Progress track on dark backgrounds — white at 8% opacity. #14FFFFFF
  static const Color darkTrack = Color(0x14FFFFFF);

  /// Accent surface overlay — accent at 15% opacity (upgrade button bg). #26B85638
  static const Color accentOverlay = Color(0x26B85638);

  // ─── Photo Type Badges ───────────────────────────────────────────────────────

  /// "Before" badge bg — light steel-blue tint. #E3EAF5
  static const Color photoBadgeBeforeBg    = Color(0xFFE3EAF5);
  /// "Before" badge fg — pre-rebrand steel navy (intentionally blue). #1A2B4A
  static const Color photoBadgeBeforeFg    = Color(0xFF1A2B4A);
  /// "After" badge bg — light green tint. #E8F5E9
  static const Color photoBadgeAfterBg     = Color(0xFFE8F5E9);
  /// "After" badge fg — forest green. #2E7D32
  static const Color photoBadgeAfterFg     = Color(0xFF2E7D32);
  /// "Progress" badge bg — warm amber tint. #FFF8E1
  static const Color photoBadgeProgressBg  = Color(0xFFFFF8E1);
  /// "Inspiration" badge bg — lavender tint. #F3E5F5
  static const Color photoBadgeInspirationBg = Color(0xFFF3E5F5);
  /// "Inspiration" badge fg — vivid purple. #7B1FA2
  static const Color photoBadgeInspirationFg = Color(0xFF7B1FA2);
  /// Fallback badge bg — neutral light gray. #F5F5F5
  static const Color photoBadgeOtherBg     = Color(0xFFF5F5F5);
  /// Fallback badge fg — neutral gray text. #616161
  static const Color photoBadgeOtherFg     = Color(0xFF616161);

  // ─── File Type Icon Backgrounds ──────────────────────────────────────────────

  /// PDF icon bg — light terracotta tint. #F0E0DC
  static const Color fileTypePdfBg   = Color(0xFFF0E0DC);
  /// JPG/PNG icon bg — light olive tint. #E0E8D8
  static const Color fileTypeImageBg = Color(0xFFE0E8D8);
  /// HEIC icon bg — light plum tint. #E8D8E0
  static const Color fileTypeHeicBg  = Color(0xFFE8D8E0);
  /// DOCX icon bg — light slate tint. #D8E0E8
  static const Color fileTypeDocBg   = Color(0xFFD8E0E8);

  // ─── Photo Grid / Image Overlays ─────────────────────────────────────────────

  /// Photo grid pair-link icon bg — black 50%. #80000000
  static const Color photoGridOverlayPair     = Color(0x80000000);
  /// Photo grid add-link icon bg — black 40%. #66000000
  static const Color photoGridOverlayLink     = Color(0x66000000);
  /// Photo grid caption gradient bottom stop — black 80%. #CC000000
  static const Color photoGridOverlayGradient = Color(0xCC000000);
  /// Photo grid caption text — white 92%. #EBFFFFFF
  static const Color photoGridCaptionText     = Color(0xEBFFFFFF);
  /// Loading placeholder for photo tiles. #D0C8BC
  static const Color photoPlaceholder         = Color(0xFFD0C8BC);

  // ─── App-specific Unique Colors ───────────────────────────────────────────────

  /// Paywall gradient midpoint — blue-navy blend. #2C3E60
  static const Color paywallGradientMid = Color(0xFF2C3E60);
  /// Account avatar gradient start — warm terracotta-salmon. #D4715A
  static const Color avatarGradientStart = Color(0xFFD4715A);
  /// iOS system success green — completion animations only. #34C759
  static const Color iosSuccessGreen = Color(0xFF34C759);
  /// Overdue task card background — sand at 6% opacity. #0EC9A84C
  static const Color overdueTaskBg = Color(0x0EC9A84C);
  /// Overdue task card border — sand at 19% opacity. #30C9A84C
  static const Color overdueTaskBorder = Color(0x30C9A84C);

  /// FAB box shadow — navy at 20% opacity for floating action buttons. #331A2B4A
  static const Color fabShadow = Color(0x331A2B4A);

  /// Trial banner background — soft golden yellow. #FFF3CD
  static const Color trialBannerBg = Color(0xFFFFF3CD);

  /// Trial banner text/icon — dark golden. #856404
  static const Color trialBannerText = Color(0xFF856404);

  /// Upload success icon circle background — warm amber tint. #FFF8E7
  static const Color uploadSuccessBg = Color(0xFFFFF8E7);

  /// Hairline border on frosted nav bar — pure black at 6% opacity. #0F000000
  static const Color navHairline = Color(0x0F000000);

  /// Frosted nav bar background — warm off-white at 92% opacity. #EBF6F2ED
  static const Color navBarBg = Color(0xEBF6F2ED);

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
