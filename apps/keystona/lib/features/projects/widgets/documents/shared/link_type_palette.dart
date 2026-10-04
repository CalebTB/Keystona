import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';

import 'document_link_type.dart';

/// Single source of truth: link_type → (background, foreground) colors.
///
/// All link-type badge coloring flows through this class.
///
/// Colors follow the v1 → Aurora remapping in
/// `Keystona_Aurora_Design_System.md` §8. The v1 palette used nine accents
/// (teal, plum, slate, sand, terracotta…); Aurora deliberately collapses to
/// five, so `receipt`/`contract` now share cobalt and `permit`/`warranty`
/// share coral. Per §8: "The collapse is intentional — Aurora deliberately
/// uses fewer category colors to keep the system tight."
abstract final class LinkTypePalette {
  static ({Color background, Color foreground}) forType(
    DocumentLinkType type,
  ) =>
      switch (type) {
        // was v1 teal
        DocumentLinkType.receipt => (
          background: AuroraColors.cobaltDim,
          foreground: AuroraColors.cobalt,
        ),
        // was v1 terracotta accent
        DocumentLinkType.permit => (
          background: AuroraColors.coralDim,
          foreground: AuroraColors.coral,
        ),
        // was v1 slate
        DocumentLinkType.contract => (
          background: AuroraColors.cobaltDim,
          foreground: AuroraColors.cobalt,
        ),
        // was v1 sand
        DocumentLinkType.invoice => (
          background: AuroraColors.yellowDim,
          foreground: AuroraColors.yellowDeep,
        ),
        // was v1 plum (deprecated in Aurora — no direct equivalent)
        DocumentLinkType.warranty => (
          background: AuroraColors.coralDim,
          foreground: AuroraColors.coral,
        ),
        DocumentLinkType.general => (
          background: AuroraColors.butter,
          foreground: AuroraColors.inkSecondary,
        ),
      };
}
