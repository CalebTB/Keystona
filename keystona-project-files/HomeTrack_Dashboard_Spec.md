# HomeTrack — Home Screen & Dashboard Specification

**Version:** 1.0  
**Date:** February 23, 2026  
**Status:** Active — Living Document  
**Author:** Caleb (Founder & Product Owner)  
**Cross-references:** SRS, API Contract, Sprint Plan, Platform UI Guide, Error Handling Guide

---

## 1. Overview

The Home tab is the default landing screen and primary daily touchpoint for Keystona. It serves as a personalized command center that answers three questions at a glance: "How is my home doing?", "What needs my attention?", and "What's coming up?" Every element on this screen is designed to drive action — either completing a task, resolving an overdue item, or deepening engagement with the platform.

### 1.1 Design Principles

- **Action-oriented:** Every visible element is tappable and leads somewhere useful.
- **Honest about state:** The dashboard never hides problems. Overdue items, low scores, and urgent issues surface prominently.
- **Celebrates progress:** Completed tasks, improving scores, and streaks are visible to build habit loops.
- **Context-aware:** Greeting, subtitle, and content adapt to time of day, season, overdue items, active projects, and weather.
- **Scannable in 3 seconds:** A user glancing at their phone should understand their home's status without scrolling.

### 1.2 Reference Mockups

- `keystona-dashboard-v2.html` — Final production mockup with hybrid mid-section layout
- `keystona-dashboard-with-project.html` — Dashboard with active project card
- `keystona-multi-project-cards.html` — Multi-project carousel variant

---

## 2. App Launch & Data Behavior

### 2.1 Default Landing

The app always opens to the **Home tab** (dashboard). This is not configurable — the Home tab is the universal entry point regardless of where the user last was.

### 2.2 Data Freshness Strategy

- **On app open:** Always fetch fresh data from Supabase. The dashboard makes a single aggregated API call (or parallel calls) to populate all sections. Show skeleton loading state during fetch.
- **Pull-to-refresh:** Available at all times. User can pull down to force a fresh fetch after making changes elsewhere in the app (e.g., completing a task on the Tasks tab, uploading a document).
- **No background polling:** The dashboard does not auto-refresh on a timer. Data is fresh on open and on pull-to-refresh.
- **Offline state:** If the device has no connectivity on app open, show cached data from last successful fetch with an amber "Offline — data may be outdated" banner per Error Handling Guide Section 5. Emergency Hub data is always available offline via SQLite regardless.

### 2.3 Multi-Property Handling (Family Tier)

Users on the Family tier may have multiple properties. The Home tab shows one property at a time:

- **Default property:** The property marked as primary (set during onboarding or in Settings).
- **Property switcher:** A dropdown/picker accessible from the hero card header (next to the property address). Tapping the address or a chevron icon opens the switcher.
- **Per-property dashboard:** All dashboard data (health score, tasks, insights, urgent items) is scoped to the selected property. Switching properties triggers a fresh data fetch with skeleton loading.
- **Single property users:** No switcher is shown. The address displays without a dropdown affordance.

---

## 3. Section Layout & Order

The dashboard is a single vertically scrolling view. Sections appear in this fixed order:

| Order | Section | Visibility |
|-------|---------|------------|
| 1 | Greeting | Always |
| 2 | Health Score Hero | Always |
| 3 | Compact Quick Actions | Always |
| 4 | Insights | When insights exist (rule-based triggers) |
| 5 | Urgent Banner | When urgent items exist |
| 6 | Coming Up (Tasks) | When upcoming tasks exist within 30-day window |
| 7 | Completed | When tasks completed in last 7 days exist |

Sections with no data are hidden entirely (not shown as empty states) — the dashboard should feel clean, not barren. The exception is Day One onboarding state, which replaces sections 3–7 with a setup checklist card (see Section 11).

---

## 4. Section Specifications

### 4.1 Greeting

**Purpose:** Personalized welcome that provides immediate context about the home's status.

**Layout:**
- Line 1: Time-based greeting + user's first name (e.g., "Good morning, Caleb")
- Line 2: Contextual subtitle (single line, dynamic)

**Time-based greetings:**

| Time Range | Greeting |
|------------|----------|
| 5:00 AM – 11:59 AM | Good morning |
| 12:00 PM – 4:59 PM | Good afternoon |
| 5:00 PM – 9:59 PM | Good evening |
| 10:00 PM – 4:59 AM | Good evening |

**Subtitle priority hierarchy** (first matching condition wins):

| Priority | Condition | Example Subtitle |
|----------|-----------|------------------|
| 1 | Overdue items exist | "3 tasks need attention" |
| 2 | Active project in progress | "Bathroom reno is 58% complete" |
| 3 | Seasonal context | "Spring prep season — 3 tasks on deck" |
| 4 | Generic fallback | "Your home is looking good" |

**Rules:**
- If multiple overdue items exist, show count: "3 tasks need attention"
- If one overdue item, name it: "HVAC filter is 3 days overdue"
- Active project subtitle shows the most recently updated project
- Seasonal context is based on the property's climate zone and current month
- Generic fallback only appears when score is >70 and nothing is overdue

**Data required:** Overdue task count, active project name + progress, climate zone, current date/time, user first name.

---

### 4.2 Health Score Hero

**Purpose:** The most prominent element on the dashboard. Shows overall home health as three concentric rings with a central composite score, plus contextual meta tags.

**Layout:**
- Property address + type displayed at top (e.g., "1234 Oak Street" / "Single Family · 2,200 sqft · Built 1998")
- Settings gear icon in top-right corner (taps to Home Profile)
- Three concentric rings (Maintenance, Documents, Emergency) with animated draw-on-load
- Central composite score (0–100) in large text
- Ring legend with micro-explanations to the right of the rings
- Hero meta tags at bottom (momentum + weather pills)

**Tap behavior:** Tapping anywhere on the hero card (except the settings gear) navigates to the **Home Profile** screen (property systems & appliances). The settings gear also navigates to Home Profile.

**Ring breakdown:**

| Ring | Color | Data Source | What It Measures |
|------|-------|-------------|------------------|
| Maintenance (outer) | Green (#6BCB8B) | Task completion data | % of relevant tasks completed on time within rolling window |
| Documents (middle) | Gold (#C9A84C) | Document completeness | % of expected document categories uploaded + expiration status |
| Emergency (inner) | Blue (#4A90D9) | Emergency Hub setup | % of shutoffs documented + contacts added + insurance entered |

**Composite score:** Weighted average of the three rings. See Section 5 (Health Score Algorithm) for the full calculation. This is the number displayed in the center of the rings.

**Score color thresholds:**

| Score Range | Color | Meaning |
|-------------|-------|---------|
| 71–100 | Green | Healthy |
| 40–70 | Amber | Needs attention |
| 0–39 | Red | At risk |

**Micro-explanations** (displayed next to the legend):
- Maintenance: "80% on track" — brief, supportive
- Documents: "65% organized" — encouraging
- Emergency: "40% ready" — motivating without alarm

**Hero meta tags** (horizontal pills at bottom of hero card):

| Tag | Format | Source | Tap Behavior |
|-----|--------|--------|-------------|
| Momentum | "✓ 3/9 this month" (green pill) | Rolling 30-day task window | Navigates to Tasks tab |
| Weather | "☀️ 72° · Clear all week" (neutral pill) | Weather API (v1.5) or static placeholder (v1.0) | No action in v1.0; links to weather-relevant tasks in v1.5 |

**Momentum calculation:**
- Numerator: Tasks completed within the current rolling 30-day window
- Denominator: Total tasks that were due (or became due) within the current rolling 30-day window
- Overdue tasks from before the 30-day window are NOT included in the denominator — they are tracked separately in the overdue resolution flow (see Section 6)
- Example: If 9 tasks were due in the last 30 days and the user completed 3, it shows "✓ 3/9 this month"

**Weather tag (v1.0):**
- In MVP, weather data is not available (Weather API integration is v1.5 per SRS WA-001)
- **v1.0 behavior:** Show a static seasonal context tag instead (e.g., "🌱 Spring maintenance season" or "❄️ Winter prep time") based on climate zone + current month
- **v1.5 behavior:** Replace with live weather from NOAA/NWS API, showing temperature + brief forecast. Premium-only feature per SRS WA-007.

**Data required:** Property address, type, year_built, square_feet; health score breakdown (maintenance %, documents %, emergency %); composite score; task completion counts for rolling 30 days; weather data or seasonal context; climate zone.

**API gap note:** The current API Contract (Section 9.9) defines `get_home_health_score` returning a single 0–100 score based only on task completion. The dashboard requires an **expanded response** that breaks down scores per pillar (maintenance, documents, emergency). This RPC needs to be updated before dashboard implementation. See Section 5 for the proposed calculation.

---

### 4.3 Compact Quick Actions

**Purpose:** Three high-frequency actions available in a single tap from the dashboard.

**Layout:** Horizontal row of three pill-shaped buttons, each with icon + label side-by-side (not stacked). Compact form factor — approximately half the vertical height of traditional square action buttons.

| Action | Icon | Label | Tap Behavior |
|--------|------|-------|-------------|
| Scan Doc | Upload icon (navy) | "Scan" | Opens document upload picker (camera / photo library / files). This is NOT a direct camera launch — it presents source options. |
| Emergency | Warning triangle (red) | "Emergency" | Opens the full Emergency Hub screen. |
| Add Task | Wrench icon (gold) | "Add Task" | Opens the full task creation form (name, due date, category, recurrence, difficulty, DIY vs. pro, tools needed, supplies needed). This creates a **maintenance task**, not a project. |

**Rules:**
- Quick actions are always visible on the dashboard, including during onboarding (though "Add Task" may be less useful until task relevance review is complete)
- Emergency button uses red icon color to ensure it's visually distinct and findable under stress
- These are the same three actions regardless of dashboard state

---

### 4.4 Insights

**Purpose:** Proactive, contextual cards that explain WHY the health score is what it is and WHAT the user should do about it. Positioned directly after the hero to serve as the "so what?" for the score.

**Layout:** Horizontally scrollable row of insight cards. Each card is approximately 260px wide with a brief title, description, and a progress bar or status indicator.

**Generation (v1.0):** Rule-based triggers only. The system evaluates conditions against the user's property data and surfaces matching insights. AI-generated insights will be added in v1.5/v2.0.

**Rule-based trigger examples:**

| Trigger Condition | Insight Card |
|-------------------|-------------|
| Appliance/system age > 80% of expected lifespan | "Water heater reaching end of life — 12 years of 15-year lifespan" with progress bar |
| Seasonal prep tasks exist for current season | "Spring prep checklist — 3 of 7 tasks complete" with progress bar |
| Multiple documents expiring within 60 days | "2 documents expiring soon — review before renewal" |
| Emergency Hub < 50% complete | "Emergency info incomplete — set up shutoffs to be prepared" |
| No maintenance tasks completed in 30+ days | "Home maintenance paused — pick up where you left off" |
| First system/appliance nearing warranty expiration | "Dishwasher warranty expires in 45 days — schedule a checkup" |

**Display rules:**
- Show a maximum of **5 insight cards** at a time. If more than 5 conditions are met, show the 5 highest priority (based on urgency/impact).
- Insight cards are **not dismissible** by the user. They remain visible until the underlying condition resolves naturally (e.g., the user completes the spring prep tasks, uploads the expiring document, finishes emergency setup).
- If zero insight conditions are met, the entire Insights section is hidden from the dashboard.
- Tapping an insight card navigates to the relevant screen (e.g., tapping "Spring prep checklist" goes to the Tasks tab filtered to spring prep tasks; tapping "Water heater reaching end of life" goes to the appliance detail screen).

**Premium considerations:** In v1.0, all insights are available to all tiers. In v1.5+, AI-generated personalized insights (e.g., "Based on your home's age and location, consider...") may be gated to Premium/Family tiers.

**Data required:** System/appliance ages and expected lifespans, document expiration dates, emergency hub completion percentage, task completion history, seasonal task templates for current climate zone + season.

---

### 4.5 Urgent Banner

**Purpose:** A persistent, attention-grabbing banner that surfaces the most critical items requiring action. This is the dashboard's alarm system.

**Layout:** Full-width banner with colored left border, pulsing status dot, item description, and a tap target that navigates to the relevant detail screen.

**What triggers an urgent banner:**

| Trigger | Condition |
|---------|-----------|
| Overdue maintenance task | Task due date has passed and status is not completed/skipped/dismissed |
| Expiring document | Document expiration date is within 14 days |
| Incomplete emergency setup | Emergency Hub < 30% complete after 14+ days since onboarding |
| Incomplete onboarding | Setup checklist not dismissed and has incomplete steps after 7+ days |

**Multiple items — auto-cycle behavior:**
- When multiple urgent items exist, the banner auto-cycles through them on a timer (every 5 seconds).
- A subtle page indicator (dots) shows how many urgent items exist.
- Tapping the banner navigates to the detail screen for the currently displayed item.
- Tapping the page indicator dots (or a "View all" link) navigates to a filtered view on the Tasks tab showing all overdue/urgent items.

**Priority ranking (determines cycle order):**
The banner uses a **smart blend of overdue days + cost impact** to determine display order:

```
urgency_score = (days_overdue × 2) + (estimated_cost_impact / 100)
```

- `days_overdue`: Number of days past the due date (or days until expiration for documents). Higher = more urgent.
- `estimated_cost_impact`: The potential financial consequence of inaction, derived from task templates (e.g., "not changing HVAC filter" → $50 estimated impact; "roof not inspected" → $5,000 estimated impact). If no cost estimate exists, defaults to 0.
- Items are sorted by `urgency_score` descending (highest urgency displayed first in the cycle).

**Dismiss behavior:**
- The user can dismiss the banner (swipe right or tap X).
- Dismissing hides the banner **for the current session only**.
- On next app open, the banner returns if the underlying items are still unresolved.
- Dismissing the banner does NOT dismiss or resolve the underlying task/document — it only hides the banner temporarily.

**Visual styling:**
- Overdue tasks: Red left border, red pulsing dot
- Expiring documents: Amber left border, amber pulsing dot
- Incomplete emergency setup: Blue left border, blue pulsing dot

**Data required:** Overdue tasks with days overdue and cost estimates, documents within 14-day expiration window, emergency hub completion %, days since onboarding completion.

---

### 4.6 Coming Up (Tasks)

**Purpose:** Shows the user what maintenance tasks are due soon, providing a clear action list without needing to navigate away from the dashboard.

**Layout:** Vertical list of task cards, each showing: category icon, task name, due date (relative — "Tomorrow", "In 3 days", "Feb 28"), linked system/appliance name, and a dollar estimate tag if available.

**Display rules:**
- Show a maximum of **5 tasks**, then a "See all →" link.
- **Date range:** Next **30 days** from today. Only tasks with due dates within this window are shown.
- **Sort order:** Soonest due date first (ascending).
- Tasks due today appear with an amber "Today" badge.
- Overdue tasks do NOT appear in Coming Up — they appear in the Urgent Banner. Coming Up is forward-looking only.
- If a task belongs to an active project (e.g., "Bathroom Reno — select tile grout"), it shows a project tag pill with the project's color.

**"See all" behavior:** Tapping "See all →" switches the user to the **Tasks tab** (bottom nav tab switch), showing the full task list. The Tasks tab opens with default sorting (due date ascending).

**Task card tap behavior:** Tapping an individual task card opens the **Task Detail screen** (push navigation from the Home tab, not a tab switch).

**Empty state:** If no tasks exist within the 30-day window, this section is hidden entirely from the dashboard (not shown as an empty card).

**Data required:** Maintenance tasks for selected property with due dates within next 30 days, linked system/appliance names, project associations if any, cost estimates.

---

### 4.7 Completed

**Purpose:** Celebrates recent task completions to reinforce the habit loop and give a sense of progress.

**Layout:** Compact horizontal scroll of completed task items, each showing a green checkmark, task name, and completion date. Much smaller than the Coming Up cards — these are acknowledgments, not action items.

**Display rules:**
- Shows tasks completed within the **last 7 days**.
- Maximum of **10 items** in the scroll.
- If no tasks were completed in the last 7 days, this section is hidden.
- Most recently completed task appears first (leftmost).

**Tap behavior:** Tapping a completed task opens the Task Detail screen showing the completion record (date, who did it, cost, notes, photos).

**Data required:** Task completions for selected property within the last 7 days, with task names and completion dates.

---

## 5. Health Score Algorithm

**Note:** This section defines the dashboard's three-ring health score. The current API Contract (Section 9.9) only defines a single-score RPC based on task completion. The API contract needs to be updated to support this expanded calculation before dashboard implementation. This will be documented separately in the Health Score Algorithm spec (item #2 on the documentation roadmap).

### 5.1 Overview

The Health Score is a composite 0–100 score derived from three pillars, each represented as a ring on the hero card. Each pillar has its own 0–100 sub-score, and the composite is a weighted average.

### 5.2 Pillar Weights

| Pillar | Weight | Rationale |
|--------|--------|-----------|
| Maintenance | 50% | Core daily value — this is what users engage with most |
| Documents | 30% | Important but less frequently changing |
| Emergency | 20% | Setup-once feature — high initial impact, then stable |

**Composite score:** `(maintenance_score × 0.5) + (documents_score × 0.3) + (emergency_score × 0.2)`

### 5.3 Pillar Calculations (High-Level)

**Maintenance score:** Based on the ratio of tasks completed on time vs. total relevant tasks, with penalties for overdue items. Overdue tasks drag the score down indefinitely until resolved (completed, skipped, or dismissed as not applicable).

**Documents score:** Based on the percentage of expected document categories that have been uploaded, with bonus points for documents that have expiration dates tracked and penalties for expired/expiring documents.

**Emergency score:** Based on completion percentage of the Emergency Hub setup (3 shutoffs documented + contacts added + insurance entered). This is largely a binary/checklist score — either you've set things up or you haven't.

*Detailed formulas will be defined in the dedicated Health Score Algorithm document.*

---

## 6. Task Relevance & Overdue Resolution

### 6.1 Task Relevance Model

The maintenance task system is a **relevance checklist per property**. When a user sets up a property, the system generates tasks based on the property's systems, appliances, and climate zone. However, not all generated tasks apply to every home. Users can opt out of tasks that don't apply.

**Relevance is property-scoped:** Opt-outs are tied to the property, not the user. If a user transfers to a new property, all task relevance resets (see Section 6.3).

### 6.2 Opt-Out Timing

Users can opt out of irrelevant tasks at two points:

1. **During onboarding (bulk review):** After property setup and task generation, the onboarding flow includes a task relevance review step. Tasks are presented as **cards grouped by room/area** (Kitchen, Bathroom, Garage, Yard, Exterior, HVAC, Plumbing, Electrical, Safety, etc.). Users toggle off tasks that don't apply to their home. This is optional but recommended — the setup checklist card includes this step.

2. **Organically (anytime):** At any point, the user can dismiss a task as "not applicable to my home" from the task detail screen. This opts them out of that task for the current property.

### 6.3 Opt-Out Behavior

When a user opts out of a task:
- The task is marked as `dismissed` with reason `not_applicable` on the current property.
- The task no longer appears in the task list, Coming Up section, or contributes to the health score (it is excluded from both numerator and denominator).
- If the task is recurring, future occurrences are also suppressed for this property.
- The opt-out is **recoverable** — users can re-enable dismissed tasks from Settings → Maintenance Tasks → Dismissed Tasks.
- Opting out does NOT affect the task template — it only affects this property's instance.

### 6.4 Overdue Resolution

Tasks that are past their due date appear in the Urgent Banner and continue to negatively impact the health score indefinitely until resolved. The user has three resolution options:

1. **Complete:** Mark the task as done (quick complete or detailed complete with cost/notes/photos). Task moves to Completed section. If recurring, next occurrence is scheduled.
2. **Skip:** Mark as skipped with a reason. Task is resolved but counts as "skipped" in health score history. If recurring, next occurrence is scheduled.
3. **Dismiss (Not Applicable):** Remove the task as irrelevant to this home. Task is opted out per Section 6.3. Health score recalculates excluding this task.

**Resolution UI:** Tapping an overdue item (from the Urgent Banner or any task list) opens the Task Detail screen. The detail screen prominently shows "Complete", "Skip", and "Doesn't Apply" action buttons when the task is overdue.

### 6.5 Rolling 30-Day Window

The momentum tag in the hero card uses a rolling 30-day window:
- Only tasks with due dates within the last 30 days are counted.
- Tasks that aged past the 30-day window without being resolved are NOT included in the momentum count — but they still appear as overdue in the Urgent Banner and still drag the health score down.
- This prevents the momentum tag from becoming depressingly large denominators (e.g., "3/47 this month" if someone ignored tasks for a year).

---

## 7. Property Transfer

When a user moves to a new home and sets up a new property:

### 7.1 What Resets (Full Reset)

- **All maintenance tasks:** Task relevance resets completely. New tasks are generated based on the new property's systems, appliances, and climate zone. Old opt-outs do not carry forward.
- **Health score:** Resets to the onboarding state (0% with encouraging copy).
- **Home Profile:** New property data (address, specs, systems, appliances).
- **Emergency Hub:** Reset to empty — new shutoff locations, new contacts needed.

### 7.2 What Can Transfer (User Chooses Item-by-Item)

During the property transfer flow, the user is presented with a list of items from their previous property and can select which ones to bring forward:

| Transferable Category | Examples |
|-----------------------|---------|
| Appliance records + warranties | Refrigerator warranty, washer/dryer manual (if physically moving the appliance) |
| Personal documents (IDs, tax records) | Driver's license, tax returns, identity documents |
| Emergency contacts | Plumber, electrician, HVAC tech, general contractor (if using the same providers) |

**Not transferable:** Insurance policies (these are property-specific and must be re-entered), utility shutoff documentation, property-specific systems.

**Transfer UI:** A checklist screen where each item from the old property is listed with a checkbox. User selects what to bring. Unselected items remain associated with the old property (if retained) or are archived.

---

## 8. Weather Integration

### 8.1 v1.0 (MVP) — Seasonal Context Tag

Weather API integration is deferred to v1.5 per SRS (WA-001 through WA-007). In MVP, the weather position in the hero meta tags shows a **static seasonal context** based on the property's IECC climate zone and the current month.

**Seasonal tag mapping:**

| Season/Month | Climate Zones 1-3 (Hot) | Climate Zones 4-5 (Mixed) | Climate Zones 6-8 (Cold) |
|-------------|------------------------|--------------------------|-------------------------|
| Dec–Feb | "🌤 Mild winter season" | "❄️ Winter prep time" | "❄️ Deep winter — protect pipes" |
| Mar–May | "☀️ Spring maintenance season" | "🌱 Spring prep season" | "🌱 Thaw season — check for damage" |
| Jun–Aug | "🔥 Peak cooling season" | "☀️ Summer maintenance season" | "☀️ Summer project season" |
| Sep–Nov | "🌤 Storm prep season" | "🍂 Fall prep season" | "🍂 Winterize before first freeze" |

**Tap behavior (v1.0):** No action. Tag is display-only.

### 8.2 v1.5 — Live Weather

- Replace seasonal tag with live temperature + brief forecast from NOAA/NWS API.
- Format: "☀️ 72° · Clear all week" or "🌧 58° · Rain tomorrow"
- Tap navigates to a weather detail view showing weather-relevant tasks (e.g., "Rain expected — check gutters").
- Premium-only feature per SRS WA-007.

---

## 9. Urgent Banner Priority Formula

The banner uses a composite urgency score to determine display order when auto-cycling:

```
urgency_score = (days_overdue × 2) + (estimated_cost_impact / 100)
```

### 9.1 Examples

| Item | Days Overdue | Cost Impact | Urgency Score |
|------|-------------|-------------|---------------|
| HVAC filter change | 3 days | $50 | (3 × 2) + (50/100) = 6.5 |
| Roof inspection | 1 day | $5,000 | (1 × 2) + (5000/100) = 52 |
| Expiring insurance doc | 7 days until expiry | $0 | (7 × 2) + 0 = 14 |
| Gutter cleaning | 15 days | $200 | (15 × 2) + (200/100) = 32 |

**Result:** Cycle order would be: Roof inspection (52) → Gutter cleaning (32) → Expiring insurance (14) → HVAC filter (6.5)

### 9.2 Cost Impact Sources

- **System-generated tasks:** Cost impact is defined in the task template (pre-populated based on national averages for consequences of neglect).
- **User-created tasks:** Cost impact defaults to $0 unless the user manually sets an estimate.
- **Document expiration:** Cost impact defaults to $0 (inconvenience, not direct cost). May be overridden if the document type has known consequences (e.g., expired homeowner's insurance → catastrophic risk, manually flagged).

### 9.3 Cycle Timing

- Each item displays for **5 seconds** before transitioning to the next.
- Transition: Crossfade (200ms fade out, 200ms fade in).
- Cycle loops continuously while the banner is visible.
- If the user taps the banner during a transition, the currently visible item's detail screen opens.

---

## 10. Insights Engine (v1.0 — Rule-Based)

### 10.1 Trigger Rules

Each rule is evaluated on dashboard load. If the condition is met, the insight card is generated. Cards are sorted by a static priority weight.

| Rule ID | Condition | Card Title | Priority |
|---------|-----------|------------|----------|
| INS-001 | Any system/appliance age > 80% of expected lifespan | "[Name] reaching end of life" | 1 (highest) |
| INS-002 | Any document expiring within 60 days | "[Count] documents expiring soon" | 2 |
| INS-003 | Seasonal prep tasks exist and are incomplete | "[Season] prep checklist — [x] of [y] complete" | 3 |
| INS-004 | Emergency Hub < 50% complete | "Emergency info incomplete" | 4 |
| INS-005 | No tasks completed in 30+ days | "Home maintenance paused" | 5 |
| INS-006 | System/appliance warranty expiring within 90 days | "[Name] warranty expires in [x] days" | 6 |
| INS-007 | 3+ tasks completed this week | "Great week — [x] tasks done!" | 7 (celebration) |

### 10.2 Display Rules

- Maximum 5 cards visible at once. If >5 conditions are met, show the 5 with highest priority (lowest priority number).
- Cards are not dismissible. They disappear when the underlying condition resolves.
- Celebration cards (INS-007) are included in the max-5 limit and have lowest priority — they only show if there's room after higher-priority insights.
- Each card shows: icon, title, description (1–2 lines), and a progress bar or status indicator where applicable.
- Tapping a card navigates to the relevant detail screen.

### 10.3 v1.5+ Enhancement

AI-generated insights will supplement rule-based triggers, analyzing patterns across the user's home data to surface personalized recommendations. These may be gated to Premium/Family tiers.

---

## 11. Day One — Onboarding Dashboard

### 11.1 Overview

After completing the initial onboarding flow (account creation → property setup), the user lands on the Home tab for the first time. Instead of showing empty sections, the dashboard displays a **setup checklist card** that replaces the normal dashboard content (sections 4–7) until the checklist is completed or explicitly dismissed.

### 11.2 What's Visible on Day One

| Element | State |
|---------|-------|
| Greeting | "Good morning, [Name]" with subtitle "Let's set up your home" |
| Health Score Hero | Rings at 0% with all tracks empty. Score shows "0" with encouraging copy: "Let's build your score!" |
| Quick Actions | Visible and functional (Scan / Emergency / Add Task) |
| Setup Checklist Card | **Replaces** Insights, Urgent Banner, Coming Up, and Completed sections |

### 11.3 Setup Checklist Card

A prominent card showing 4 setup steps as a vertical checklist. Each step has a title, brief description, an icon, and a completion checkmark.

| Step | Title | Description | Navigates To |
|------|-------|-------------|-------------|
| 1 | Add your home systems | "Tell us what's in your home — HVAC, water heater, roof, and more" | Home Profile → Add Systems flow |
| 2 | Review your maintenance tasks | "We've generated tasks for your home — confirm what applies" | Task relevance review screen (card-based by room/area) |
| 3 | Upload your first document | "Scan or upload a warranty, insurance policy, or home document" | Document upload picker |
| 4 | Set up emergency info | "Document your shutoffs and emergency contacts — works offline" | Emergency Hub setup flow |

**Behavior:**
- Steps can be completed in any order (not strictly sequential).
- Completing a step shows a green checkmark and strikethrough on the step title.
- Steps can be skipped individually (tap "Skip" on each step). Skipped steps show a gray skip indicator.
- The entire checklist card has a "Dismiss setup guide" link at the bottom. Tapping this hides the checklist permanently and reveals the normal dashboard sections.
- The checklist card persists across app sessions until all steps are completed or the card is explicitly dismissed.
- After dismissal or completion, the normal dashboard sections (Insights, Urgent Banner, Coming Up, Completed) appear based on available data.

### 11.4 Task Relevance Review (Step 2)

This is a critical onboarding step where the user configures which maintenance tasks apply to their home.

**Layout:** Full-screen view with tasks organized as **cards grouped by room/area**:
- Kitchen
- Bathroom(s)
- Garage
- Yard / Exterior
- HVAC / Heating & Cooling
- Plumbing
- Electrical
- Roof & Gutters
- Safety (smoke detectors, CO detectors, fire extinguishers)

Each area card shows a header with the area name and a list of generated tasks with toggle switches. The user can:
- Toggle individual tasks on/off
- Use "Select all" / "Deselect all" per area card
- Skip the entire review (all generated tasks remain active by default)

**After review:** Tasks that are toggled off are dismissed as `not_applicable`. The remaining tasks populate the Coming Up section and begin contributing to the health score.

### 11.5 Progressive Score Build

As the user completes onboarding steps, the health score updates in real-time:
- Adding systems → may generate additional tasks and insights
- Reviewing tasks → refines the denominator for maintenance score
- Uploading a document → documents score improves
- Setting up emergency info → emergency score improves

The rings animate from 0% to their new values when the user returns to the dashboard after completing each step, providing a satisfying visual reward.

---

## 12. Dashboard API Requirements

### 12.1 Primary Dashboard Endpoint

The dashboard should fetch all required data in a **single aggregated call** (or a small set of parallel calls) to minimize load time. Proposed RPC:

```
get_dashboard_data(property_id) → {
  greeting: { user_first_name, overdue_count, active_project, climate_zone },
  health_score: { composite, maintenance, documents, emergency, trend },
  momentum: { completed_30d, total_30d },
  weather: { seasonal_tag } | { temperature, forecast },  // v1.0 vs v1.5
  insights: [ { rule_id, title, description, progress, navigation_target } ],
  urgent_items: [ { type, title, days_overdue, cost_impact, urgency_score, navigation_target } ],
  coming_up: [ { task_id, name, due_date, category_icon, system_name, cost_estimate, project_tag? } ],  // max 5, next 30 days
  completed_recent: [ { task_id, name, completed_date } ],  // last 7 days, max 10
  onboarding: { checklist_visible, steps: [ { id, title, completed, skipped } ] }
}
```

### 12.2 Data Sources Per Section

| Section | Primary Table(s) | Joins/Lookups |
|---------|-----------------|---------------|
| Greeting | profiles, maintenance_tasks (overdue count), projects | — |
| Health Score | maintenance_tasks, documents, emergency_* tables | RPC calculation |
| Momentum | maintenance_tasks, task_completions | 30-day window filter |
| Insights | systems, appliances, documents, emergency_*, maintenance_tasks | Lifespan data, expiration dates |
| Urgent Banner | maintenance_tasks (overdue), documents (expiring) | Task templates for cost estimates |
| Coming Up | maintenance_tasks (due next 30 days) | systems, appliances, projects |
| Completed | task_completions (last 7 days) | maintenance_tasks |
| Onboarding | onboarding_progress (new table needed) | — |

---

## 13. Cross-References

| Topic | Document | Section |
|-------|----------|---------|
| Task CRUD & completion flow | API Contract | Section 9 |
| Health Score RPC (needs expansion) | API Contract | Section 9.9 |
| Emergency Hub screens & offline | Sprint Plan | Phase 4 |
| Task generation from templates | Sprint Plan | Section 2.5 |
| Document Vault upload flow | Sprint Plan | Phase 1 |
| Navigation & tab structure | Navigation Tab Update | — |
| Skeleton loading & error states | Error Handling Guide | Sections 3–4 |
| Platform-adaptive widgets | Platform UI Guide | All sections |
| Weather-triggered alerts (v1.5) | SRS | Section 4.1 |
| Design system (colors, type, spacing) | SKILL.md / SRS Section 8.4 | — |

---

## 14. Open Questions for Health Score Algorithm Doc

These questions need to be resolved in the dedicated Health Score Algorithm specification (documentation item #2):

1. Exact formula for Maintenance pillar score — how much do overdue tasks penalize vs. on-time completions reward?
2. What "expected document categories" does the Documents pillar measure against? Is there a baseline set (insurance, deed, mortgage, warranty) or is it dynamic?
3. Should pillar weights (50/30/20) be adjustable per user or fixed?
4. How does the trend arrow calculate (comparing which time periods)?
5. Should newly onboarded users with few data points get a "provisional" score, or does the formula handle sparse data gracefully?

---

*End of Home Screen & Dashboard Specification*  
*HomeTrack (Keystona) — Version 1.0 — February 2026*
