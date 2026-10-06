/// Who is setting up Keystona (OnbPersona).
enum OnboardingPersona {
  owner,
  shopper;

  static OnboardingPersona? fromName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// Kind of home (OnbProperty). [value] is stored in `properties.property_type`.
enum HomeKind {
  singleFamily('single_family', 'Single-family'),
  townhouse('townhouse', 'Townhouse'),
  condo('condo', 'Condo'),
  manufactured('mobile', 'Manufactured');

  const HomeKind(this.value, this.label);

  final String value;
  final String label;

  static HomeKind? fromValue(String? value) {
    for (final k in values) {
      if (k.value == value) return k;
    }
    return null;
  }
}

/// Furthest onboarding step the user has reached (drives resume).
enum OnbStage {
  persona,
  property,
  trial,
  checklist;

  static OnbStage fromName(String? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return persona;
  }
}

/// A "do these first" step on OnbChecklist.
enum ChecklistStep { scan, shutoffs, document, household }

/// Plan shown on OnbTrial.
enum OnbPlan { yearly, monthly }

/// Persisted onboarding progress. Holds no address or other PII.
class OnboardingProgress {
  const OnboardingProgress({
    this.persona = OnboardingPersona.owner,
    this.stage = OnbStage.persona,
    this.trialStarted = false,
    this.doneSteps = const <ChecklistStep>{},
  });

  final OnboardingPersona? persona;
  final OnbStage stage;
  final bool trialStarted;
  final Set<ChecklistStep> doneSteps;

  OnboardingProgress copyWith({
    OnboardingPersona? persona,
    OnbStage? stage,
    bool? trialStarted,
    Set<ChecklistStep>? doneSteps,
  }) =>
      OnboardingProgress(
        persona: persona ?? this.persona,
        stage: stage ?? this.stage,
        trialStarted: trialStarted ?? this.trialStarted,
        doneSteps: doneSteps ?? this.doneSteps,
      );

  Map<String, Object?> toJson() => {
        'persona': persona?.name,
        'stage': stage.name,
        'trialStarted': trialStarted,
        'doneSteps': doneSteps.map((s) => s.name).toList(),
      };

  factory OnboardingProgress.fromJson(Map<String, Object?> json) {
    final done = <ChecklistStep>{};
    for (final raw in (json['doneSteps'] as List?) ?? const []) {
      for (final s in ChecklistStep.values) {
        if (s.name == raw) done.add(s);
      }
    }
    return OnboardingProgress(
      persona: OnboardingPersona.fromName(json['persona'] as String?),
      stage: OnbStage.fromName(json['stage'] as String?),
      trialStarted: json['trialStarted'] == true,
      doneSteps: done,
    );
  }
}

/// An address the user picked on OnbProperty.
class OnbAddress {
  const OnbAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    this.yearBuilt,
    this.squareFeet,
  });

  final String street;
  final String city;
  final String state;
  final String zip;

  /// Public-record values, when the address source has them.
  final int? yearBuilt;
  final int? squareFeet;

  bool get hasRecords => yearBuilt != null || squareFeet != null;
}

/// What OnbProperty collected, saved to `properties` after the climate sheet.
class OnbPropertyDraft {
  const OnbPropertyDraft({
    required this.address,
    required this.kind,
    this.yearBuilt,
    this.squareFeet,
    this.climate,
  });

  final OnbAddress address;
  final HomeKind kind;
  final int? yearBuilt;
  final int? squareFeet;
  final ClimateProfile? climate;

  OnbPropertyDraft withClimate(ClimateProfile? c) => OnbPropertyDraft(
        address: address,
        kind: kind,
        yearBuilt: yearBuilt,
        squareFeet: squareFeet,
        climate: c,
      );
}

/// The home card on OnbChecklist.
class OnbHomeSummary {
  const OnbHomeSummary({
    required this.street,
    this.kind,
    this.yearBuilt,
    this.squareFeet,
    this.climateZone,
    this.climateMoisture,
  });

  final String street;
  final HomeKind? kind;
  final int? yearBuilt;
  final int? squareFeet;
  final int? climateZone;
  final String? climateMoisture;
}

/// Glyph a climate reminder shows.
enum ClimateGlyph { freeze, heat, moisture, storm }

/// A reminder the climate adds.
class ClimateReminder {
  const ClimateReminder(this.title, this.cadence, this.glyph);

  final String title;

  /// Shown uppercase, e.g. "Every Nov".
  final String cadence;
  final ClimateGlyph glyph;
}

/// Climate found from a ZIP (OnbClimate).
class ClimateProfile {
  const ClimateProfile({
    required this.zone,
    required this.moisture,
    required this.label,
    required this.description,
    required this.reminders,
  });

  /// IECC zone 1-7. Stored in `properties.climate_zone`.
  final int zone;

  /// IECC moisture letter: A humid, B dry, C marine.
  final String moisture;

  /// "mixed-humid" in "Your home is in a mixed-humid climate."
  final String label;
  final String description;
  final List<ClimateReminder> reminders;

  String get zoneLabel => '$zone$moisture';
}
