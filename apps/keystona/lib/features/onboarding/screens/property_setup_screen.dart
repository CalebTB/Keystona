import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../core/widgets/loading_skeleton_card.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onb_climate_sheet.dart';
import '../widgets/onb_parts.dart';
import '../widgets/onb_property_widgets.dart';
import '../widgets/onb_scaffold.dart';

/// OnbProperty (1.7): address, kind of home, year built and size. Continue
/// opens the climate sheet (OnbClimate); "Looks right" saves the property and
/// moves on to the free month.
class PropertySetupScreen extends ConsumerStatefulWidget {
  const PropertySetupScreen({super.key});

  /// Oldest year built accepted (exclusive).
  static const int oldestYear = 1700;

  /// Digits in a year.
  static const int yearDigits = 4;

  @override
  ConsumerState<PropertySetupScreen> createState() =>
      _PropertySetupScreenState();
}

class _PropertySetupScreenState extends ConsumerState<PropertySetupScreen> {
  final _address = TextEditingController();
  final _year = TextEditingController();
  final _sqft = TextEditingController();
  final _thousands = NumberFormat.decimalPattern('en_US');

  Timer? _debounce;
  List<OnbAddress> _suggestions = const [];
  OnbAddress? _picked;
  HomeKind _kind = HomeKind.singleFamily;
  bool _lookingUp = false;
  bool _lookupFailed = false;
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _address.dispose();
    _year.dispose();
    _sqft.dispose();
    super.dispose();
  }

  // ── Address ─────────────────────────────────────────────────────────────────

  void _onAddressChanged(String text) {
    _debounce?.cancel();
    setState(() {
      _picked = null;
      _prefilled = false;
      _lookupFailed = false;
      _suggestions = const [];
      _lookingUp = text.trim().isNotEmpty;
    });
    _debounce = Timer(AuroraDurations.searchDebounce, () => _lookUp(text));
  }

  Future<void> _lookUp(String text) async {
    final source = ref.read(addressSourceProvider);
    try {
      final found = await source.suggest(text);
      if (!mounted || text != _address.text) return;
      setState(() {
        _suggestions = found;
        _lookingUp = false;
      });
    } catch (_) {
      if (!mounted || text != _address.text) return;
      setState(() {
        _lookingUp = false;
        _lookupFailed = true;
      });
    }
  }

  void _pick(OnbAddress address) {
    _address.text = address.street;
    if (address.yearBuilt != null) _year.text = '${address.yearBuilt}';
    if (address.squareFeet != null) {
      _sqft.text = _thousands.format(address.squareFeet);
    }
    setState(() {
      _picked = address;
      _suggestions = const [];
      _prefilled = address.hasRecords;
    });
  }

  // ── Fields ──────────────────────────────────────────────────────────────────

  int get _maxYear => ref.read(onboardingClockProvider)().year;

  bool get _yearOk {
    final text = _year.text.trim();
    if (text.isEmpty) return true;
    final value = int.tryParse(text);
    return RegExp('^\\d{${PropertySetupScreen.yearDigits}}\$').hasMatch(text) &&
        value != null &&
        value > PropertySetupScreen.oldestYear &&
        value <= _maxYear;
  }

  bool get _ready => _picked != null && _yearOk;

  int? get _yearValue => int.tryParse(_year.text.trim());

  int? get _sqftValue =>
      int.tryParse(_sqft.text.replaceAll(RegExp(r'[^0-9]'), ''));

  String get _fillNote {
    if (!_yearOk) return 'That year looks off — 4 digits, like 1998';
    if (_prefilled) return 'Pre-filled · change it if it’s wrong';
    return 'Not sure? A guess is fine — you can change it later';
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboardingPersona);
    }
  }

  Future<void> _continue() async {
    final address = _picked;
    if (address == null || !_ready) return;
    var draft = OnbPropertyDraft(
      address: address,
      kind: _kind,
      yearBuilt: _yearValue,
      squareFeet: _sqftValue,
    );
    final repository = ref.read(onboardingRepositoryProvider);
    final draftNotifier = ref.read(onbPropertyDraftProvider.notifier);
    final progress = ref.read(onboardingProgressProvider.notifier);

    final climate = await OnbClimateSheet.show(context, address: address);
    if (climate == null || !mounted) return;
    draft = draft.withClimate(climate);

    setState(() => _saving = true);
    try {
      await repository.saveProperty(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(
        context,
        'Could not save your home. Please try again.',
      );
      return;
    }
    draftNotifier.set(draft);
    await progress.reachStage(OnbStage.trial);
    if (!mounted) return;
    setState(() => _saving = false);
    context.go(AppRoutes.onboardingTrial);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return OnbScaffold(
      step: 2,
      onBack: _back,
      content: [
        const OnbHeader(
          title: 'Tell us about your home.',
          subtitle:
              'The age and size shape your reminders — a 1998 roof needs different care than a new one.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space2),
          children: [
            OnbAddressField(
              controller: _address,
              picked: _picked != null,
              onChanged: _onAddressChanged,
            ),
            if (_lookingUp)
              LoadingSkeletonCard(height: a.of(AuroraOnbSizes.skeletonRowHeight))
            else if (_suggestions.isNotEmpty)
              OnbSuggestionList(suggestions: _suggestions, onPick: _pick)
            else if (_lookupFailed)
              Text(
                'Could not look that up. Keep typing to try again.'
                    .toUpperCase(),
                style: AuroraType.helper,
              )
            else if (_picked != null)
              Text(
                [
                  '${_picked!.city} · ${_picked!.zip}',
                  if (_prefilled) 'We found year built and size in public records',
                ].join(' · ').toUpperCase(),
                style: AuroraType.helper,
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            Text('KIND OF HOME', style: AuroraType.label),
            Semantics(
              container: true,
              label: 'Kind of home',
              child: _KindGrid(
                selected: _kind,
                onPick: (k) => setState(() => _kind = k),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: a.of(AuroraSpacing.space3),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: a.of(AuroraSpacing.space4),
              children: [
                Expanded(
                  child: AuroraTextField(
                    label: 'Year built',
                    controller: _year,
                    hintText: '1998',
                    keyboardType: TextInputType.number,
                    maxLength: PropertySetupScreen.yearDigits,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: AuroraTextField(
                    label: 'Square feet',
                    controller: _sqft,
                    hintText: '2,000',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            Text(_fillNote.toUpperCase(), style: AuroraType.helper),
          ],
        ),
      ],
      footer: [
        OnbCta(
          label: 'Continue',
          onPressed: _ready && !_saving ? _continue : null,
          loading: _saving,
        ),
      ],
    );
  }
}

/// The 2x2 grid of kinds.
class _KindGrid extends StatelessWidget {
  const _KindGrid({required this.selected, required this.onPick});

  final HomeKind selected;
  final ValueChanged<HomeKind> onPick;

  /// Tiles per row.
  static const int columns = 2;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final kinds = HomeKind.values;
    return Column(
      spacing: a.of(AuroraSpacing.space3),
      children: [
        for (var i = 0; i < kinds.length; i += columns)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: a.of(AuroraSpacing.space3),
              children: [
                for (final k in kinds.skip(i).take(columns))
                  Expanded(
                    child: OnbTypeTile(
                      label: k.label,
                      selected: k == selected,
                      onTap: () => onPick(k),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
