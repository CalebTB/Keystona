# HomeTrack — Health Score Algorithm Specification

**Version:** 1.0  
**Date:** February 23, 2026  
**Status:** Active — Living Document  
**Author:** Caleb (Founder & Product Owner)  
**Cross-references:** Dashboard Spec (Section 5), API Contract (Section 9.9), Sprint Plan (Section 2.6)

---

## 1. Overview

The Home Health Score is a composite 0–100 metric displayed as three concentric rings on the dashboard hero card. It answers a single question: "How well am I taking care of my home?" The score is designed to motivate action without creating anxiety — it should feel like a fitness tracker for your house, not a credit score.

### 1.1 Design Principles

- **Honest but encouraging:** The score reflects reality but is framed to motivate improvement, not punish.
- **Actionable:** Every point lost can be traced to a specific action the user can take to recover it.
- **Stable:** The score shouldn't swing wildly day-to-day. Changes should be meaningful and tied to real actions.
- **Fair:** Users are only scored on things relevant to their home. Dismissed/not-applicable tasks are excluded entirely.

### 1.2 Score Display

| State | Display |
|-------|---------|
| First 30 days after property creation | Rings animate based on available data, center shows "—" instead of a number |
| After 30 days | Numeric score (0–100) displayed in ring center |
| Score 71–100 | Green color treatment |
| Score 40–70 | Amber color treatment |
| Score 0–39 | Red color treatment |

---

## 2. Composite Score

The composite score is a fixed weighted average of three pillar sub-scores:

```
composite_score = (maintenance_score × 0.50) + (documents_score × 0.30) + (emergency_score × 0.20)
```

| Pillar | Weight | Ring Position | Ring Color | Rationale |
|--------|--------|--------------|------------|-----------|
| Maintenance | 50% | Outer ring | Green (#6BCB8B) | Core daily engagement — most tasks, most variability |
| Documents | 30% | Middle ring | Gold (#C9A84C) | Important but less frequently changing |
| Emergency | 20% | Inner ring | Blue (#4A90D9) | Setup-once — high initial impact, then stable |

**Weights are fixed** for all users across all tiers. They are not configurable.

**Rounding:** The composite score is rounded to the nearest integer for display. Pillar sub-scores are calculated as floats and only rounded at the composite level.

---

## 3. Maintenance Pillar (50% weight)

### 3.1 Overview

The Maintenance score measures how consistently the user completes relevant maintenance tasks on time. It uses a **rolling 12-month window** — only tasks that were due within the last 365 days are considered.

### 3.2 Task States

Each task within the 12-month window falls into one of four states:

| State | Definition | Score Impact |
|-------|-----------|-------------|
| **Completed on time** | Marked complete on or before the due date | Full credit (+1 to numerator) |
| **Completed late** | Marked complete after the due date | Partial credit (+0.5 to numerator) |
| **Skipped** | User explicitly skipped with a reason | Neutral (excluded from both numerator AND denominator) |
| **Overdue** | Past due date, not yet completed/skipped/dismissed | Penalty (0 to numerator, +1 to denominator, plus active penalty) |
| **Dismissed (not applicable)** | User opted out — task doesn't apply to their home | Excluded entirely (not counted in any calculation) |

### 3.3 Formula

```
base_ratio = completed_points / total_relevant_tasks

Where:
  completed_points = (tasks_completed_on_time × 1.0) + (tasks_completed_late × 0.5)
  total_relevant_tasks = tasks_completed_on_time + tasks_completed_late + tasks_overdue
  
  (Skipped and dismissed tasks are excluded from both numerator and denominator)

overdue_penalty = overdue_count × 5  (each overdue task reduces score by 5 points)

maintenance_score = max(0, (base_ratio × 100) - overdue_penalty)
```

### 3.4 Walkthrough Example

A user has had 20 relevant tasks due in the last 12 months:
- 14 completed on time → 14.0 points
- 3 completed late → 1.5 points
- 2 currently overdue → 0 points
- 1 skipped → excluded

Calculation:
```
total_relevant_tasks = 14 + 3 + 2 = 19  (skipped excluded)
completed_points = 14.0 + 1.5 = 15.5
base_ratio = 15.5 / 19 = 0.8158
overdue_penalty = 2 × 5 = 10

maintenance_score = max(0, (0.8158 × 100) - 10) = max(0, 71.58) = 71.58
```

Maintenance ring displays at ~72%.

### 3.5 Key Behaviors

- **Overdue tasks hurt indefinitely.** Each overdue task applies a flat 5-point penalty until resolved. A user with 10 overdue tasks loses 50 points before the ratio even matters. This is intentional — it creates urgency to resolve overdue items.
- **Linear penalty, not accelerating.** A task 1 day overdue has the same 5-point penalty as a task 90 days overdue. The urgency to resolve comes from the cumulative count, not escalating individual penalties.
- **Skipped is neutral.** Skipping a task with a reason is a legitimate action (e.g., "contractor handled this during annual service"). It doesn't help the score but doesn't hurt it either.
- **Late completion gets half credit.** Completing a task late is better than not completing it at all, but worse than on-time. This incentivizes timely action while not making late completers feel the effort was wasted.
- **12-month rolling window prevents permanent damage.** A bad month 11 months ago is about to fall off the window. The score naturally recovers over time as long as the user stays current.
- **Dismissed tasks vanish from the math.** If a user opts out of gutter cleaning because they don't have gutters, it's as if the task never existed. This prevents irrelevant tasks from tanking scores.

### 3.6 Edge Cases

| Scenario | Behavior |
|----------|----------|
| New user, 0 tasks due in 12 months | maintenance_score = 100 (no tasks to fail on = perfect by default) |
| User dismissed ALL tasks | maintenance_score = 100 (no relevant tasks = perfect) |
| All tasks overdue, none completed | base_ratio = 0, overdue_penalty = count × 5, score = max(0, 0 - penalty) = 0 |
| User completes 1 of 1 task on time | base_ratio = 1.0, no penalty, score = 100 |

---

## 4. Documents Pillar (30% weight)

### 4.1 Overview

The Documents score measures how complete and current the user's document vault is relative to a baseline set of expected categories. Unlike Maintenance (which is ratio-based), Documents is primarily a **completeness checklist** with an expiration modifier.

### 4.2 Baseline Expected Categories

Every property is expected to have these three document categories uploaded:

| Category | Why It's Expected |
|----------|------------------|
| Homeowner's insurance | Required for mortgage, critical for claims |
| Mortgage/deed | Proof of ownership, refinance reference |
| Property tax records | Annual obligation, tax deduction reference |

Each baseline category contributes equally to the documents score.

### 4.3 Formula

```
baseline_completion = uploaded_baseline_categories / 3

Where:
  uploaded_baseline_categories = count of baseline categories with at least 1 document uploaded
  (0, 1, 2, or 3)

expiration_penalty = insurance_expired_penalty

Where:
  insurance_expired_penalty:
    - 0 if homeowner's insurance is not expired
    - 0 if homeowner's insurance expired ≤ 30 days ago (grace period)
    - 15 if homeowner's insurance expired > 30 days ago

bonus_points = min(20, additional_document_count × 4)

Where:
  additional_document_count = total documents uploaded beyond the 3 baseline categories
  (e.g., appliance warranties, home warranty, inspection reports, manuals)
  Each additional document adds 4 points, capped at 20 bonus points (5 extra docs max impact)

documents_score = max(0, (baseline_completion × 80) + bonus_points - expiration_penalty)
```

### 4.4 Walkthrough Example

A user has uploaded:
- Homeowner's insurance (current, not expired) ✓
- Mortgage documents ✓
- Property tax records ✓
- 3 appliance warranties (bonus)

Calculation:
```
baseline_completion = 3/3 = 1.0
expiration_penalty = 0  (insurance is current)
bonus_points = min(20, 3 × 4) = 12

documents_score = max(0, (1.0 × 80) + 12 - 0) = 92
```

### 4.5 Another Example (Missing docs + expired insurance)

A user has uploaded:
- Homeowner's insurance (expired 45 days ago) ✓ but expired
- No mortgage/deed
- No property tax records
- 1 appliance warranty (bonus)

Calculation:
```
baseline_completion = 1/3 = 0.333
expiration_penalty = 15  (insurance expired > 30 days)
bonus_points = min(20, 1 × 4) = 4

documents_score = max(0, (0.333 × 80) + 4 - 15) = max(0, 26.67 + 4 - 15) = 15.67
```

### 4.6 Key Behaviors

- **Only homeowner's insurance penalizes on expiry.** Other document types (mortgage, tax records, warranties) do not have expiration-based penalties. Their expirations may trigger Insight cards on the dashboard but don't affect the score.
- **30-day grace period.** Insurance expiring doesn't immediately penalize. Users get 30 days to renew and upload the new policy.
- **Bonus points reward over-achievers.** Users who upload beyond the baseline (warranties, manuals, inspection reports) get up to 20 bonus points. This incentivizes deeper engagement with the document vault.
- **80-point ceiling from baseline alone.** A user who uploads all 3 baseline categories but nothing extra scores 80. The bonus system encourages going further to reach 100.
- **15-point penalty is significant but not catastrophic.** Expired insurance drops the score noticeably — enough to change the ring color from green to amber — but doesn't destroy the entire pillar score.

### 4.7 Edge Cases

| Scenario | Behavior |
|----------|----------|
| New user, 0 documents | documents_score = 0 |
| All 3 baseline + 5 bonus docs, nothing expired | (1.0 × 80) + 20 - 0 = 100 |
| Only insurance uploaded, not expired | (0.333 × 80) + 0 - 0 = 26.67 |
| All baseline uploaded, insurance expired 60 days | (1.0 × 80) + 0 - 15 = 65 |

---

## 5. Emergency Pillar (20% weight)

### 5.1 Overview

The Emergency score measures how prepared the user is for a home emergency. It's primarily a **setup completeness score** — once configured, it tends to stay stable. The score uses weighted components, with utility shutoffs worth more than contacts or insurance (because shutoff knowledge can prevent catastrophic damage).

### 5.2 Component Weights

| Component | Weight | What It Measures |
|-----------|--------|-----------------|
| Utility Shutoffs | 60% | Are all 3 shutoffs documented? (water, gas, electrical) |
| Emergency Contacts | 25% | Has the user added emergency contacts? |
| Insurance Info | 15% | Has the user entered insurance quick-reference data? |

### 5.3 Formula

```
shutoff_score = (completed_shutoffs / 3) × 100

Where:
  completed_shutoffs = number of shutoffs fully documented (location + photo + instructions)
  Each shutoff (water, gas, electrical) is weighted equally (each worth 1/3)
  A shutoff is "fully documented" when it has: location description AND at least 1 photo

contact_score:
  - 0 contacts added → 0
  - 1 contact added → 50
  - 2 contacts added → 75
  - 3+ contacts added → 100

insurance_score:
  - No insurance info entered → 0
  - At least 1 policy with policy number + carrier + claims phone → 100

emergency_score = (shutoff_score × 0.60) + (contact_score × 0.25) + (insurance_score × 0.15)
```

### 5.4 Walkthrough Example

A user has:
- Water shutoff documented with photo ✓
- Gas shutoff documented with photo ✓
- Electrical panel NOT documented ✗
- 2 emergency contacts added
- Insurance info entered with policy number + carrier + claims phone ✓

Calculation:
```
shutoff_score = (2/3) × 100 = 66.67
contact_score = 75  (2 contacts)
insurance_score = 100  (complete)

emergency_score = (66.67 × 0.60) + (75 × 0.25) + (100 × 0.15)
                = 40.0 + 18.75 + 15.0
                = 73.75
```

### 5.5 Key Behaviors

- **Shutoffs are binary per type.** Each shutoff is either fully documented or not — there's no partial credit for "started but didn't add a photo."
- **"Fully documented" requires location + photo.** Just entering a text description isn't enough. The photo is critical because in an emergency, someone unfamiliar with the house needs visual guidance.
- **Contact scoring incentivizes multiple contacts.** One contact gets you halfway. Three gets you full credit. This encourages adding backup contacts (plumber + electrician + HVAC at minimum).
- **Insurance scoring is binary.** Either you have at least one policy with the essential fields or you don't. We don't penalize for not having flood/earthquake insurance (not applicable everywhere).
- **Score is stable once set up.** Unlike Maintenance (which fluctuates monthly), Emergency tends to be "set it and forget it." Users configure it once during onboarding, and the score stays high.

### 5.6 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Nothing set up | emergency_score = 0 |
| All shutoffs + 3 contacts + insurance | (100 × 0.60) + (100 × 0.25) + (100 × 0.15) = 100 |
| Only shutoffs complete, nothing else | (100 × 0.60) + (0 × 0.25) + (0 × 0.15) = 60 |
| Only contacts and insurance, no shutoffs | (0 × 0.60) + (100 × 0.25) + (100 × 0.15) = 40 |

---

## 6. Trend Arrow

### 6.1 Calculation

The trend compares the **composite score from the last 30 days** against the **composite score from the prior 30 days** (days 31–60).

```
current_period_score  = composite score calculated using only data from the last 30 days
previous_period_score = composite score calculated using only data from days 31–60

delta = current_period_score - previous_period_score
```

### 6.2 Display Rules

| Delta | Arrow | Label |
|-------|-------|-------|
| delta > +5 | ↑ Green | Improving |
| delta between -5 and +5 | → Gray | Stable |
| delta < -5 | ↓ Red | Declining |

**The ±5 threshold prevents noise.** Small fluctuations (one task completed a day earlier or later) don't trigger trend changes. Only meaningful shifts in behavior surface as trend movements.

### 6.3 Edge Cases

| Scenario | Behavior |
|----------|----------|
| User is within first 30 days (no previous period) | No trend arrow displayed |
| User is between 30–60 days (partial previous period) | Calculate with available data; if previous period has < 5 data points, show no trend arrow |
| User had 0 tasks in previous period, 5 completed in current | Treat previous as 100 (no tasks = perfect), calculate delta normally |

### 6.4 Trend and Pillar Interaction

The trend is calculated on the **composite score only**, not per-pillar. Individual pillar trends may be added in a future version but are not part of v1.0.

---

## 7. Score Threshold (First 30 Days)

### 7.1 Behavior

For the first 30 days after a property is created, the dashboard hero shows:
- **Rings:** Animate and fill based on available data (even if sparse). If the user uploaded 2 of 3 baseline documents, the Documents ring shows ~53%. If they set up 2 shutoffs, the Emergency ring shows proportionally.
- **Center display:** Shows "—" (em dash) instead of a numeric score.
- **No trend arrow** during this period.

### 7.2 Transition

On day 31 (or next app open after day 30), the "—" transitions to the numeric composite score with a count-up animation (0 → actual score over ~1 second). This is a small celebratory moment — "Here's how your home is doing after your first month."

### 7.3 Rationale

Showing a numeric score too early creates two problems:
1. **Artificially low scores discourage new users.** A user who uploaded one document and completed zero tasks (because none were due yet) would see a score of 10, which feels like failure.
2. **Scores with tiny denominators are misleading.** 1 completed task out of 1 due = 100, which is technically correct but doesn't mean the user has a healthy home management habit.

The 30-day window gives enough time for tasks to come due, documents to be uploaded, and emergency info to be configured — producing a score that's meaningful.

---

## 8. Composite Score Examples

### 8.1 Healthy Home (Score: 85)

```
Maintenance: 14/16 on time, 1 late, 1 overdue
  base_ratio = (14 + 0.5) / 16 = 0.906
  penalty = 1 × 5 = 5
  maintenance_score = (0.906 × 100) - 5 = 85.6

Documents: All 3 baseline + 2 bonus, nothing expired
  documents_score = (1.0 × 80) + 8 - 0 = 88

Emergency: All shutoffs + 2 contacts + insurance
  emergency_score = (100 × 0.60) + (75 × 0.25) + (100 × 0.15) = 93.75

Composite = (85.6 × 0.50) + (88 × 0.30) + (93.75 × 0.20)
          = 42.8 + 26.4 + 18.75 = 87.95 → displays as 88
```

### 8.2 Needs Work (Score: 52)

```
Maintenance: 8/15 on time, 2 late, 5 overdue
  base_ratio = (8 + 1.0) / 15 = 0.60
  penalty = 5 × 5 = 25
  maintenance_score = max(0, (0.60 × 100) - 25) = 35

Documents: 2/3 baseline, 0 bonus, nothing expired
  documents_score = (0.667 × 80) + 0 - 0 = 53.33

Emergency: All shutoffs + 3 contacts, no insurance
  emergency_score = (100 × 0.60) + (100 × 0.25) + (0 × 0.15) = 85

Composite = (35 × 0.50) + (53.33 × 0.30) + (85 × 0.20)
          = 17.5 + 16.0 + 17.0 = 50.5 → displays as 51
```

### 8.3 At Risk (Score: 18)

```
Maintenance: 2/10 on time, 0 late, 8 overdue
  base_ratio = 2 / 10 = 0.20
  penalty = 8 × 5 = 40
  maintenance_score = max(0, (0.20 × 100) - 40) = max(0, -20) = 0

Documents: 1/3 baseline, insurance expired 60 days
  documents_score = max(0, (0.333 × 80) + 0 - 15) = 11.67

Emergency: 1 shutoff only, no contacts, no insurance
  emergency_score = (33.33 × 0.60) + (0 × 0.25) + (0 × 0.15) = 20

Composite = (0 × 0.50) + (11.67 × 0.30) + (20 × 0.20)
          = 0 + 3.5 + 4.0 = 7.5 → displays as 8
```

### 8.4 Perfect Score (Score: 100)

```
Maintenance: 20/20 on time, 0 late, 0 overdue
  maintenance_score = (1.0 × 100) - 0 = 100

Documents: All 3 baseline + 5 bonus, nothing expired
  documents_score = (1.0 × 80) + 20 - 0 = 100

Emergency: All shutoffs + 3 contacts + insurance
  emergency_score = (100 × 0.60) + (100 × 0.25) + (100 × 0.15) = 100

Composite = (100 × 0.50) + (100 × 0.30) + (100 × 0.20) = 100
```

---

## 9. API Contract Update

### 9.1 Current State

The existing API Contract (Section 9.9) defines:

```typescript
rpc('get_home_health_score', { p_property_id }) → {
  score: number,        // 0-100
  total_tasks: number,
  completed_on_time: number,
  overdue: number,
  skipped: number,
  upcoming_this_month: number,
  trend: string         // 'improving' | 'stable' | 'declining'
}
```

### 9.2 Required Update

The RPC must be expanded to support the three-pillar breakdown:

```typescript
rpc('get_home_health_score', { p_property_id }) → {
  // Composite
  composite_score: number | null,   // null if within first 30 days
  score_available: boolean,         // false if within first 30 days
  property_created_at: string,      // ISO date — client uses this to determine threshold
  
  // Pillar breakdown
  maintenance: {
    score: number,                  // 0-100
    completed_on_time: number,
    completed_late: number,
    overdue: number,
    skipped: number,
    total_relevant: number,         // denominator (excludes skipped + dismissed)
    window_months: 12               // rolling window used
  },
  documents: {
    score: number,                  // 0-100
    baseline_uploaded: number,      // 0-3
    baseline_total: 3,
    bonus_documents: number,        // count of additional docs
    insurance_expired: boolean,
    insurance_grace_period: boolean  // true if expired ≤ 30 days
  },
  emergency: {
    score: number,                  // 0-100
    shutoffs_complete: number,      // 0-3
    contacts_count: number,
    insurance_entered: boolean
  },
  
  // Trend
  trend: string | null,             // 'improving' | 'stable' | 'declining' | null (< 30 days)
  trend_delta: number | null,       // raw delta for debugging/display
  
  // Momentum (for hero meta tag)
  momentum: {
    completed_30d: number,
    total_30d: number
  }
}
```

### 9.3 Implementation Notes

- The RPC should be a single Postgres function that calculates all values server-side to minimize round trips.
- The 12-month rolling window for Maintenance uses `due_date >= NOW() - INTERVAL '12 months'`.
- Dismissed tasks are filtered by `status = 'dismissed' AND dismiss_reason = 'not_applicable'`.
- The trend calculation requires running the composite formula twice: once for the last 30 days and once for days 31–60. This can be done within the same function.
- The `score_available` boolean lets the client decide whether to show "—" or the numeric score without duplicating date logic.

---

## 10. Cross-References

| Topic | Document | Section |
|-------|----------|---------|
| Dashboard display of health score | Dashboard Spec | Section 4.2 |
| Score color thresholds | Dashboard Spec | Section 4.2 |
| Task relevance & opt-out model | Dashboard Spec | Section 6 |
| Overdue resolution flow | Dashboard Spec | Section 6.4 |
| Momentum tag calculation | Dashboard Spec | Section 4.2 |
| Task completion API | API Contract | Section 9.4–9.6 |
| Current health score RPC | API Contract | Section 9.9 |
| Health Score widget implementation | Sprint Plan | Section 2.6 |
| Document categories | API Contract | Section 6 |
| Emergency Hub data model | API Contract | Section 10 |

---

*End of Health Score Algorithm Specification*  
*HomeTrack (Keystona) — Version 1.0 — February 2026*
