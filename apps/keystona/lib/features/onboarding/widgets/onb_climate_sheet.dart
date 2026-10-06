import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/aurora/aurora_button.dart';
import '../models/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import 'onb_parts.dart';
import 'onb_skeletons.dart';

/// OnbClimate (1.8): the climate found from the ZIP, shown as a sheet over
/// OnbProperty. Resolves to the [ClimateProfile] when the user taps "Looks
/// right", or null when it is dismissed.
abstract final class OnbClimateSheet {
  static Future<ClimateProfile?> show(
    BuildContext context, {
    required OnbAddress address,
  }) =>
      AuroraSheet.show<ClimateProfile>(
        context,
        height: AuroraSheetHeight.extra,
        child: _ClimateBody(address: address),
      );
}

class _ClimateBody extends ConsumerStatefulWidget {
  const _ClimateBody({required this.address});

  final OnbAddress address;

  @override
  ConsumerState<_ClimateBody> createState() => _ClimateBodyState();
}

class _ClimateBodyState extends ConsumerState<_ClimateBody> {
  late Future<ClimateProfile?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ClimateProfile?> _load() => ref.read(climateSourceProvider).lookup(
        zip: widget.address.zip,
        state: widget.address.state,
      );

  void _retry() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClimateProfile?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _ClimateSkeleton();
        }
        if (snap.hasError) {
          return _ClimateError(
            message:
                'Something went wrong. Check your connection and try again.',
            onRetry: _retry,
          );
        }
        final profile = snap.data;
        if (profile == null) {
          return _ClimateError(
            message:
                'We don’t have climate data for ZIP ${widget.address.zip} yet. Try again, or close this and check the address.',
            onRetry: _retry,
          );
        }
        return _ClimateContent(zip: widget.address.zip, profile: profile);
      },
    );
  }
}

/// Error state sized for a sheet body (no nested scroll view, unlike
/// [ErrorView]).
class _ClimateError extends StatelessWidget {
  const _ClimateError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      spacing: a.of(AuroraSpacing.space6),
      children: [
        Text(
          'We couldn’t find your climate',
          textAlign: TextAlign.center,
          style: AuroraSharedType.stateTitle,
        ),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AuroraSharedType.stateBody,
        ),
        SaveButton(label: 'Try again', onPressed: onRetry),
      ],
    );
  }
}

class _ClimateSkeleton extends StatelessWidget {
  const _ClimateSkeleton();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space7),
      children: const [OnbHeaderSkeleton(), OnbCardsSkeleton(count: 2)],
    );
  }
}

class _ClimateContent extends StatelessWidget {
  const _ClimateContent({required this.zip, required this.profile});

  final String zip;
  final ClimateProfile profile;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space7),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            Text(
              'Found from your ZIP · $zip'.toUpperCase(),
              style: AuroraOnbType.eyebrow,
            ),
            Semantics(
              header: true,
              child: Text(
                'Your home is in a ${profile.label} climate.',
                style: AuroraOnbType.sheetTitle,
              ),
            ),
          ],
        ),
        _ClimateScale(profile: profile),
        Text(profile.description, style: AuroraOnbType.climateBody),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            const OnbSectionHeader(title: 'So we’ll add'),
            OnbRowGroup(
              rows: [for (final r in profile.reminders) _ReminderRow(r)],
            ),
          ],
        ),
        Text(
          'Set by location, not editable · It only shapes which reminders you get'
              .toUpperCase(),
          style: AuroraType.helper,
        ),
        OnbCta(
          label: 'Looks right',
          onPressed: () => Navigator.of(context).pop(profile),
        ),
      ],
    );
  }
}

/// Zones 1-7 as segments, the user's zone filled.
class _ClimateScale extends StatelessWidget {
  const _ClimateScale({required this.profile});

  /// Zones drawn on the scale.
  static const int zones = 7;

  final ClimateProfile profile;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      label: 'Climate zone ${profile.zoneLabel}, between hot and cold',
      child: ExcludeSemantics(
        child: Column(
          spacing: a.of(AuroraSpacing.space3),
          children: [
            Row(
              spacing: a.of(AuroraSpacing.space1),
              children: [
                for (var z = 1; z <= zones; z++)
                  Expanded(
                    child: Column(
                      spacing: a.of(AuroraSpacing.space2),
                      children: [
                        Container(
                          height: a.of(AuroraOnbSizes.climateBar),
                          decoration: BoxDecoration(
                            color: z == profile.zone
                                ? AuroraColors.ink
                                : AuroraColors.paper,
                            borderRadius: AuroraRadius.bar,
                            border: z == profile.zone
                                ? null
                                : Border.all(
                                    color: AuroraColors.inkBorderStrong,
                                    width: AuroraBorders.regular,
                                  ),
                          ),
                        ),
                        Text(
                          z == profile.zone ? profile.zoneLabel : '$z',
                          style: AuroraOnbType.scaleNumber.copyWith(
                            color: z == profile.zone
                                ? AuroraColors.ink
                                : AuroraColors.inkPlaceholder,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HOT', style: AuroraType.meta),
                Text('ZONE ${profile.zoneLabel}', style: AuroraType.meta),
                Text('COLD', style: AuroraType.meta),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow(this.reminder);

  final ClimateReminder reminder;

  static IconData _icon(ClimateGlyph g) => switch (g) {
        ClimateGlyph.freeze => Icons.ac_unit,
        ClimateGlyph.heat => Icons.wb_sunny_outlined,
        ClimateGlyph.moisture => Icons.water_drop_outlined,
        ClimateGlyph.storm => Icons.thunderstorm_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraOnbSizes.climateRowMinHeight),
      ),
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space4,
        ),
        child: Row(
          spacing: a.of(AuroraSpacing.space5),
          children: [
            Icon(
              _icon(reminder.glyph),
              size: a.of(AuroraOnbSizes.climateGlyph),
              color: AuroraColors.cobalt,
            ),
            Expanded(
              child: Text(reminder.title, style: AuroraOnbType.climateRow),
            ),
            Flexible(
              child: Text(
                reminder.cadence.toUpperCase(),
                textAlign: TextAlign.end,
                style: AuroraType.meta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
