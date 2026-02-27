# HomeTrack — Dashboard State Variations

**Version:** 1.0  
**Date:** February 23, 2026  
**Status:** Active — Living Document  
**Author:** Caleb (Founder & Product Owner)  
**Cross-references:** Dashboard Spec, Health Score Algorithm, Empty States Catalog, Error Handling Guide

---

## 1. Overview

The Home tab dashboard is not a single static layout — it adapts based on the user's data, engagement level, and home status. This document defines every meaningful state the dashboard can be in, what the user sees in each state, and the rules that govern transitions between states.

### 1.1 Why This Document Exists

A developer building the Home tab needs to know what happens when:
- A brand new user opens the app for the first time
- A power user has a perfect score with nothing to do
- A neglectful user has 8 overdue tasks
- A user returns after 2 months away
- A user is offline

Without this spec, the developer will guess — and guesses lead to inconsistent experiences.

### 1.2 Design Principles

- **The dashboard is visually stable.** The hero card background never changes color. The layout doesn't shift dramatically between states. The score number changes color, but the surrounding structure stays the same.
- **Data speaks, chrome doesn't.** The dashboard conveys urgency through content (overdue counts, attention cards, urgent banners) not through visual alarm (no red backgrounds, no flashing elements).
- **No seasonal theming.** Seasonal context is handled by the weather/seasonal meta tag and the Insights engine. The dashboard does not show seasonal banners, themed backgrounds, or quarterly promotions.
- **No celebration for perfection.** A score of 100 is displayed normally. The reward for a perfect score is a clean, calm dashboard with nothing to act on.

---

## 2. State Definitions

The dashboard has 8 defined states. A user is always in exactly one primary state, though some states can overlap (e.g., a user can be in "Active — Healthy" and also be a returning user).

| # | State | Condition | Frequency |
|---|-------|-----------|-----------|
| 1 | Day One — Pre-Onboarding | Property just created, setup checklist not started | Once per property |
| 2 | Day One — Mid-Onboarding | Setup checklist partially completed | Temporary |
| 3 | Post-Onboarding — Sparse Data | Checklist complete/dismissed but minimal data entered | Common in first weeks |
| 4 | Active — Healthy | Score ≥71, 0 overdue items | Ideal steady state |
| 5 | Active — Needs Attention | Score 40–70, 1+ overdue items | Common |
| 6 | Active — At Risk | Score <40, multiple overdue items | Concerning |
| 7 | Returning User | Last app open was 30+ days ago | Re-engagement |
| 8 | Offline | No network connectivity | Situational |

---

## 3. State Details

### 3.1 State 1: Day One — Pre-Onboarding

**Condition:** Property exists, onboarding setup checklist is visible, no steps completed.

**What the user sees:**

| Section | State |
|---------|-------|
| Greeting | "Good morning, [Name]" / subtitle: "Let's set up your home" |
| Health Score Hero | All rings at 0%. Center shows "—". Seasonal meta tag visible. Momentum shows "✓ 0/0 this month". |
| Quick Actions | Visible and functional |
| Setup Checklist Card | Prominent card with 4 steps, all unchecked. Replaces Insights, Urgent Banner, Coming Up, and Completed sections. |
| Insights | Hidden (replaced by checklist) |
| Urgent Banner | Hidden (replaced by checklist) |
| Coming Up | Hidden (replaced by checklist) |
| Completed | Hidden (replaced by checklist) |

**Transition out:** User completes or skips any checklist step → State 2. User dismisses checklist entirely → State 3.

---

### 3.2 State 2: Day One — Mid-Onboarding

**Condition:** Setup checklist is visible with 1–3 steps completed/skipped, but not all steps done and checklist not dismissed.

**What the user sees:**

| Section | State |
|---------|-------|
| Greeting | "Good morning, [Name]" / subtitle: "Let's set up your home" (unchanged until checklist is done) |
| Health Score Hero | Rings begin filling based on completed steps. Center still shows "—" (under 30 days). |
| Quick Actions | Visible and functional |
| Setup Checklist Card | Shows progress — completed steps have green checkmarks, skipped steps have gray indicators. Remaining steps are prominent. |
| Insights | Hidden (replaced by checklist) |
| Urgent Banner | Hidden (replaced by checklist) |
| Coming Up | Hidden (replaced by checklist) |
| Completed | Hidden (replaced by checklist) |

**Ring behavior during onboarding:**
- User adds systems → Maintenance ring may remain low (no tasks completed yet, but tasks are now generated)
- User uploads a document → Documents ring jumps (e.g., 1/3 baseline = ~27%)
- User sets up a shutoff → Emergency ring increases (e.g., 1 shutoff = ~20%)

Rings animate from their previous value to the new value when the user returns to the dashboard after completing a step.

**Transition out:** All 4 steps completed/skipped → checklist auto-collapses, State 3 or 4. User taps "Dismiss setup guide" → State 3.

---

### 3.3 State 3: Post-Onboarding — Sparse Data

**Condition:** Setup checklist is completed or dismissed, but the user has minimal data. Specifically: the user has completed onboarding but has fewer than 2 of the following: at least 1 system added, at least 1 document uploaded, at least 1 emergency shutoff documented.

This is the state where the user technically finished setup but didn't do much. The dashboard needs to gently encourage deeper engagement without nagging.

**What the user sees:**

| Section | State |
|---------|-------|
| Greeting | Normal time-based greeting / subtitle from priority hierarchy (likely generic: "Your home is looking good" or seasonal) |
| Health Score Hero | Rings show whatever data exists. Center shows "—" (still within first 30 days). |
| Quick Actions | Visible and functional |
| Setup Checklist Card | **Still visible** alongside normal sections. Shows remaining incomplete steps with encouraging copy. Located between Quick Actions and any data-driven sections. |
| Insights | Shown if any insight conditions are met (likely INS-004 "Emergency info incomplete" or INS-005 "Home maintenance paused") |
| Urgent Banner | Hidden (nothing overdue yet for a new user) |
| Coming Up | Shown if tasks exist (may have tasks if user added systems) |
| Completed | Hidden (no completions yet) |

**Key behavior:** The setup checklist card persists in this state, positioned between Quick Actions and the data-driven sections. It does NOT replace the data sections — it sits alongside them. This gives the user both the onboarding guidance and the real dashboard experience simultaneously.

**Transition out:** User completes remaining setup steps → checklist disappears. User gains 2+ of the 3 data milestones → checklist disappears. Alternatively, if 30+ days have passed since property creation, the checklist auto-dismisses (stop nagging).

---

### 3.4 State 4: Active — Healthy

**Condition:** Score ≥71 (green), 0 overdue items. This is the ideal steady state — the user is managing their home well.

**What the user sees:**

| Section | State |
|---------|-------|
| Greeting | Normal time-based greeting / subtitle from priority hierarchy. With 0 overdue and no active project, likely seasonal or generic: "Your home is looking good" |
| Health Score Hero | Rings filled to current values. Score number in **green**. Trend arrow shown (if past 30 days). |
| Quick Actions | Visible |
| Insights | Shown if any insight conditions are met (e.g., appliance nearing end of life, seasonal prep tasks) |
| Needs Attention Card | **Not shown** (0 overdue items) |
| Urgent Banner | Shown only if documents are expiring or emergency hub is incomplete. Otherwise hidden. |
| Coming Up | Shows next 5 tasks due in 30 days. May be hidden if nothing is due. |
| Completed | Shows tasks completed in last 7 days |

**This is the calmest version of the dashboard.** Minimal urgency indicators. The user may see only Greeting → Hero → Quick Actions → Coming Up → Completed on a good day.

---

### 3.5 State 5: Active — Needs Attention

**Condition:** 1+ overdue items exist. Score is typically 40–70 (amber) but could be any range — the trigger is overdue count, not score.

**What the user sees:**

| Section | State |
|---------|-------|
| Greeting | Subtitle reflects overdue: "3 tasks need attention" (or "HVAC filter is 3 days overdue" if only 1) |
| Health Score Hero | Rings reflect current scores. Score number in **amber** (40–70) or **red** (<40). |
| Quick Actions | Visible |
| Insights | Shown if conditions are met |
| Needs Attention Card | **Visible** — persistent, not dismissible. Positioned between Insights and Coming Up. |
| Urgent Banner | Also shown if additional urgent items exist (expiring docs, incomplete emergency). Auto-cycles as normal. |
| Coming Up | Shows next 5 upcoming tasks (forward-looking only — overdue items are in the Needs Attention card) |
| Completed | Shows recent completions |

**Needs Attention Card specification:**

```
┌─────────────────────────────────────────┐
│  ⚠ 3 tasks overdue                     │  ← Red left border, warning icon
│                                         │
│  HVAC filter change · 5 days overdue    │  ← Most urgent item shown
│  Gutter cleaning · 3 days overdue       │  ← Second most urgent
│  + 1 more                               │  ← Count of remaining
│                                         │
│          [ Review overdue tasks → ]     │  ← CTA: navigates to Tasks tab
│                                         │     filtered to "Overdue" status
└─────────────────────────────────────────┘
```

**Card display rules:**
- **Red left border** with warning triangle icon
- Shows up to **3 overdue items** inline, sorted by urgency score (same formula as Urgent Banner: `days_overdue × 2 + cost_impact / 100`)
- If more than 3 overdue items, shows "+ X more" below the listed items
- CTA button: "Review overdue tasks →" navigates to the Tasks tab filtered to show only overdue items
- **Not dismissible.** The card is present every time the dashboard loads as long as overdue items exist.
- **Tapping the card background** (not just the CTA) also navigates to the filtered overdue Tasks view
- The card disappears immediately when the last overdue item is resolved

**Relationship to Urgent Banner:** The Needs Attention card handles overdue tasks exclusively. The Urgent Banner handles other urgent items (expiring documents, incomplete emergency setup). Both can be visible simultaneously — the Needs Attention card appears above the Urgent Banner in the scroll order.

---

### 3.6 State 6: Active — At Risk

**Condition:** Score <40 (red). This typically means multiple overdue items, missing documents, and/or incomplete emergency setup.

**What the user sees:**

Identical layout to State 5 (Needs Attention), but with these differences:

| Element | Change from State 5 |
|---------|---------------------|
| Score number | Displayed in **red** |
| Greeting subtitle | More direct: "Your home needs attention — 8 tasks overdue" |
| Needs Attention Card | Likely showing 3+ items with "+ X more" |
| Insights | Likely multiple active insights (incomplete emergency, expired insurance, etc.) |
| Urgent Banner | Likely cycling through multiple items |

**The dashboard does NOT change its visual structure at this level.** No red backgrounds, no alarm UI. The urgency is communicated through the volume of content: more insight cards, a fuller Needs Attention card, more urgent banner items. The dashboard stays calm; the data signals the problem.

---

### 3.7 State 7: Returning User (30+ Days Away)

**Condition:** The user's last app open was 30+ days ago. This is detected by comparing the current timestamp to a stored `last_app_open` timestamp in the user profile.

**What the user sees:**

The dashboard is **structurally identical** to whatever state the user's data puts them in (likely State 5 or 6, since tasks have been piling up). The only special treatment is the **greeting subtitle**:

| Overdue Count | Subtitle |
|---------------|----------|
| 0 tasks came due | "Welcome back! Your home is in good shape." |
| 1–3 tasks | "Welcome back — 3 tasks came due while you were away" |
| 4+ tasks | "Welcome back — [X] tasks need your attention" |

**Rules:**
- The "Welcome back" subtitle **replaces** the normal subtitle priority hierarchy for the first session only. On the next app open, the subtitle returns to normal priority (overdue → project → seasonal → generic).
- The returning user state is a one-time overlay — it does not persist across sessions.
- "While you were away" tasks are calculated as tasks whose due dates fall between the last app open and now.
- The Needs Attention card, Urgent Banner, and all other sections behave normally based on current data.

**Detection:**
```
is_returning_user = (NOW() - last_app_open) > 30 days
tasks_due_while_away = COUNT(tasks WHERE due_date BETWEEN last_app_open AND NOW() AND status = 'overdue')
```

After the dashboard loads, `last_app_open` is updated to the current timestamp.

---

### 3.8 State 8: Offline

**Condition:** Device has no network connectivity when the app opens or loses connectivity during use.

**What the user sees:**

| Section | State |
|---------|-------|
| Offline Banner | Persistent amber banner at top: "You're offline — Emergency Hub is still available" |
| Greeting | Shows cached data from last successful fetch |
| Health Score Hero | Shows cached score and rings from last fetch. No "stale data" indicator — the score doesn't change that fast. |
| Quick Actions | "Scan Doc" and "Add Task" are **disabled** (grayed out, tap shows snackbar: "Connect to internet to use this feature"). "Emergency" button is **active** (Emergency Hub works offline). |
| All other sections | Show cached data from last fetch. Pull-to-refresh shows error snackbar: "No internet connection. Try again when connected." |

**Transition:** When connectivity is restored, the offline banner disappears, disabled buttons re-enable, and a silent background refresh updates all dashboard data.

---

## 4. Section Visibility Matrix

This matrix shows which sections are visible in each state. ✓ = visible, ✗ = hidden, ● = conditional (depends on data).

| Section | State 1 | State 2 | State 3 | State 4 | State 5 | State 6 | State 7 | State 8 |
|---------|---------|---------|---------|---------|---------|---------|---------|---------|
| Greeting | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Health Score Hero | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Quick Actions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Partial |
| Setup Checklist | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Insights | ✗ | ✗ | ● | ● | ● | ● | ● | ● |
| Needs Attention | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ | ● | ● |
| Urgent Banner | ✗ | ✗ | ✗ | ● | ● | ● | ● | ● |
| Coming Up | ✗ | ✗ | ● | ● | ● | ● | ● | ● |
| Completed | ✗ | ✗ | ● | ● | ● | ● | ● | ● |

**Notes:**
- States 1 & 2: Checklist replaces all data-driven sections
- State 3: Checklist is visible alongside data-driven sections
- States 4–7: Normal data-driven behavior; sections show/hide based on whether they have content
- State 8: Shows cached versions of whatever the last state was

---

## 5. Hero Card Adaptation Rules

The hero card maintains a **stable visual structure** across all states. Only specific elements change:

### 5.1 What NEVER Changes

- Hero card background color (always the standard card background — never tints red/amber/green)
- Ring position and sizing (outer/middle/inner always in the same place)
- Ring colors (Maintenance = green, Documents = gold, Emergency = blue — these represent the pillars, not the score health)
- Layout structure (address → rings → legend → meta tags)
- Meta tag positions

### 5.2 What DOES Change

| Element | Adaptation Rule |
|---------|----------------|
| **Score number color** | Green (71–100), Amber (40–70), Red (0–39) |
| **Score number vs. dash** | Shows "—" for first 30 days, number after |
| **Ring fill levels** | Animate to current pillar sub-scores |
| **Micro-explanations** | Text updates to reflect current percentages (e.g., "80% on track" → "45% needs work") |
| **Momentum tag** | Updates to reflect rolling 30-day ratio |
| **Seasonal/weather tag** | Updates based on season or live weather (v1.5) |
| **Trend arrow** | Shows after 30 days. Green ↑ / Gray → / Red ↓ |

### 5.3 Micro-Explanation Tone

The micro-explanations next to the ring legend adapt their tone based on the pillar score:

| Score Range | Tone | Example |
|-------------|------|---------|
| 80–100 | Positive | "92% on track" |
| 60–79 | Encouraging | "68% — getting there" |
| 40–59 | Motivating | "45% — room to improve" |
| 0–39 | Direct | "22% — needs attention" |

These are soft labels — they don't use alarming language. Even "needs attention" is factual, not panicked.

---

## 6. Greeting Subtitle Logic

The greeting subtitle is the most dynamic text element on the dashboard. Here is the complete priority hierarchy including all states:

| Priority | Condition | Subtitle | State(s) |
|----------|-----------|----------|----------|
| 0 (highest) | Returning user, first session | "Welcome back — X tasks came due while you were away" | 7 |
| 1 | Onboarding not complete | "Let's set up your home" | 1, 2 |
| 2 | Overdue items exist (1 item) | "[Task name] is [X] days overdue" | 5, 6 |
| 3 | Overdue items exist (2+ items) | "[X] tasks need attention" | 5, 6 |
| 4 | Active project in progress | "[Project name] is [X]% complete" | 4, 5 |
| 5 | Seasonal context | "Spring prep season — [X] tasks on deck" | 3, 4 |
| 6 (lowest) | Generic fallback | "Your home is looking good" | 3, 4 |

**Rules:**
- First matching condition wins. The system evaluates from priority 0 down.
- Priority 0 (returning user) is a **one-time override** — it only applies to the first session after a 30+ day absence.
- Priority 4 (active project) shows the **most recently updated** project if multiple exist.
- Priority 5 (seasonal) is based on climate zone + current month, and only triggers if seasonal tasks actually exist for the property.
- Priority 6 (generic) only triggers when the score is >70, nothing is overdue, no active project, and no seasonal tasks.

---

## 7. Needs Attention Card vs. Urgent Banner

These two components serve different purposes and can appear simultaneously:

| Attribute | Needs Attention Card | Urgent Banner |
|-----------|---------------------|---------------|
| **What it shows** | Overdue maintenance tasks only | Expiring documents, incomplete emergency setup, onboarding reminders |
| **Trigger** | 1+ overdue tasks | Any non-task urgent condition met |
| **Position** | Between Insights and Coming Up | Between Needs Attention Card and Coming Up |
| **Dismissible?** | No — persists until all overdue tasks resolved | Yes — swipe to dismiss for current session, returns on next app open |
| **Content** | Lists up to 3 items with urgency details + count of remaining | Single item auto-cycling every 5 seconds |
| **Tap behavior** | Navigates to Tasks tab filtered to "Overdue" | Navigates to detail screen of currently displayed item |
| **Visual treatment** | Red left border, warning icon, card background | Colored left border (red/amber/blue based on type), pulsing dot |

**When both are visible:** The scroll order is: Insights → Needs Attention Card → Urgent Banner → Coming Up. The Needs Attention card is always above the Urgent Banner because overdue tasks are a higher priority signal than expiring documents.

**When only one is needed:** If there are overdue tasks but no expiring docs or incomplete emergency, only the Needs Attention card shows. If there are no overdue tasks but documents are expiring, only the Urgent Banner shows.

---

## 8. Setup Checklist Persistence Rules

The setup checklist card has specific rules about when it appears and disappears:

| Rule | Behavior |
|------|----------|
| Initial appearance | Immediately after property creation, on first dashboard load |
| During onboarding (States 1–2) | Replaces all data-driven sections |
| Post-onboarding sparse data (State 3) | Sits alongside data-driven sections |
| All steps completed | Checklist collapses with a brief "Setup complete!" animation, then disappears permanently |
| User taps "Dismiss setup guide" | Checklist disappears permanently |
| User dismisses but has <2 data milestones | Checklist still disappears — respect the user's choice |
| 30+ days since property creation | Checklist auto-dismisses if still visible (stop nagging) |
| Checklist dismissed, user goes to State 5/6 | Checklist does NOT reappear — it's a one-time onboarding tool |

**Data milestones** (used for State 3 detection):
1. At least 1 system added
2. At least 1 document uploaded
3. At least 1 emergency shutoff documented

When the user has 2+ of these 3 milestones AND has completed/dismissed the checklist, they transition to State 4+ (data-driven states).

---

## 9. State Transition Diagram

```
                    ┌─────────────┐
                    │  State 1    │
                    │  Day One    │
                    │  Pre-Setup  │
                    └──────┬──────┘
                           │ any step started
                           ▼
                    ┌─────────────┐
                    │  State 2    │
                    │  Day One    │
                    │  Mid-Setup  │
                    └──────┬──────┘
                           │ checklist complete/dismissed
                           ▼
                    ┌─────────────┐
                    │  State 3    │
                    │  Post-Setup │◄──── checklist still shown alongside
                    │  Sparse     │      data sections
                    └──────┬──────┘
                           │ 2+ data milestones OR 30 days elapsed
                           ▼
              ┌────────────┼────────────┐
              ▼            ▼            ▼
       ┌────────────┐┌────────────┐┌────────────┐
       │  State 4   ││  State 5   ││  State 6   │
       │  Healthy   ││  Needs     ││  At Risk   │
       │  Score≥71  ││  Attention ││  Score<40  │
       │  0 overdue ││  1+overdue ││  Many      │
       └────────────┘└────────────┘└────────────┘
              ▲            ▲            ▲
              └────────────┼────────────┘
                           │ users move between 4/5/6
                           │ based on task completion
                           │ and overdue resolution

       State 7 (Returning): overlays on top of 4/5/6 for first session
       State 8 (Offline): overlays on top of any state when disconnected
```

---

## 10. Implementation Checklist

For the developer building the Home tab, verify each state:

- [ ] **State 1:** Hero at 0% with "—", checklist replaces data sections, greeting says "Let's set up your home"
- [ ] **State 2:** Rings animate when returning from setup steps, checklist shows progress
- [ ] **State 3:** Checklist visible alongside Insights/Coming Up, auto-dismisses at 30 days
- [ ] **State 4:** Clean dashboard, score in green, no Needs Attention card, sections hide when empty
- [ ] **State 5:** Needs Attention card visible and not dismissible, greeting shows overdue count, score in amber
- [ ] **State 6:** Same as State 5 but score in red, greeting more direct
- [ ] **State 7:** "Welcome back" subtitle on first session, tasks-due-while-away count calculated correctly
- [ ] **State 8:** Offline banner visible, Scan/Add Task disabled, Emergency enabled, cached data shown
- [ ] Needs Attention card shows up to 3 items + count, taps to filtered Tasks view
- [ ] Needs Attention card and Urgent Banner can appear simultaneously in correct order
- [ ] Hero card background never changes color
- [ ] Score number color matches threshold (green/amber/red)
- [ ] Micro-explanations adapt tone based on pillar score
- [ ] Setup checklist auto-dismisses at 30 days if still visible
- [ ] Returning user detection compares last_app_open timestamp correctly
- [ ] State transitions happen seamlessly on pull-to-refresh and app open

---

## 11. Cross-References

| Topic | Document | Section |
|-------|----------|---------|
| Dashboard section specifications | Dashboard Spec | Section 4 |
| Onboarding setup checklist | Dashboard Spec | Section 11 |
| Health score thresholds & colors | Health Score Algorithm | Section 1.2 |
| Score calculation for each pillar | Health Score Algorithm | Sections 3–5 |
| Trend arrow calculation | Health Score Algorithm | Section 6 |
| First-30-days threshold | Health Score Algorithm | Section 7 |
| Empty states for all screens | Empty States Catalog | All sections |
| Urgent Banner priority formula | Dashboard Spec | Section 9 |
| Offline behavior | Error Handling Guide | Section 5 |
| Skeleton loading states | Error Handling Guide | Section 3 |

---

*End of Dashboard State Variations*  
*HomeTrack (Keystona) — Version 1.0 — February 2026*
