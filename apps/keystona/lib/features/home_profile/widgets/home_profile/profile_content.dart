import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../maintenance/models/home_health_score.dart';
import '../../home_profile_copy.dart';
import '../../lifespan/lifespan_reading.dart';
import '../../models/home_profile_overview.dart';
import '../../models/item_ref.dart';
import '../home_common/home_item_icons.dart';
import '../home_common/link_section_header.dart';
import '../shared/item_key_value_card.dart';
import '../shared/lifespan_colors.dart';
import 'home_health_section.dart';
import 'lifespan_callout.dart';
import 'next_five_years_card.dart';
import 'profile_actions.dart';
import 'profile_cover.dart';
import 'profile_header.dart';
import 'profile_systems_section.dart';

/// The Home profile once the property has loaded: cover, header, the lifespan
/// callout, health, systems, the five-year forecast and the property card.
class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.overview,
    required this.actions,
    this.health,
    this.aroundMeta,
  });

  final HomeProfileOverview overview;
  final ProfileActions actions;

  /// The maintenance score; null hides the section.
  final HomeHealthScore? health;
  final String? aroundMeta;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final property = overview.property;
    final data = overview.lifespan;
    final worst = data.worst;
    final rows = HomeProfileCopy.propertyRows(property);
    final score = health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space9),
      children: [
        ProfileCover(photoUrl: overview.exteriorPhotoSignedUrl),
        ProfileHeader(
          eyebrow: HomeProfileCopy.eyebrow(property),
          address: property.addressLine1,
          facts: HomeProfileCopy.facts(property),
        ),
        if (worst != null)
          LifespanCallout(
            icon: HomeItemIcons.forCategory(worst.category),
            title: HomeProfileCopy.calloutTitle(worst),
            sub: HomeProfileCopy.calloutSub(worst, data.forecast),
            accent: worst.reading.band == LifespanBand.past
                ? AuroraColors.coral
                : AuroraColors.amber,
            subColor: worst.reading.textColor,
            onTap: actions.onLifespan,
          ),
        if (score != null && score.totalTasks > 0)
          HomeHealthSection(
            score: score.score,
            completed: score.completed,
            total: score.totalTasks,
            onTap: actions.onTasks,
          ),
        ProfileSystemsSection(
          systems: data.forKind(ItemKind.system),
          applianceCount: overview.applianceCount,
          agingCount: data.agingSystems,
          aroundMeta: aroundMeta,
          onOpenSystem: actions.onOpenSystem,
          onAllSystems: actions.onAllSystems,
          onAppliances: actions.onAppliances,
          onScan: actions.onScan,
          onAround: actions.onAround,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            LinkSectionHeader(
              title: HomeProfileCopy.nextFive,
              linkLabel: HomeProfileCopy.howLong,
              onLink: actions.onLifespan,
            ),
            NextFiveYearsCard(
              forecast: data.forecast,
              onTap: actions.onLifespan,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            LinkSectionHeader(
              title: HomeProfileCopy.theProperty,
              linkLabel: HomeProfileCopy.edit,
              onLink: actions.onEdit,
            ),
            if (rows.isNotEmpty) ItemKeyValueCard(rows: rows),
          ],
        ),
      ],
    );
  }
}
