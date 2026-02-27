# HomeTrack — Empty States Catalog

**Version:** 1.0  
**Date:** February 23, 2026  
**Status:** Active — Living Document  
**Author:** Caleb (Founder & Product Owner)  
**Cross-references:** Error Handling Guide (Section 4), Dashboard Spec (Section 11), Sprint Plan, Platform UI Guide

---

## 1. Overview

Every screen in Keystona that can be empty has a defined empty state. Empty states are onboarding opportunities, not dead ends. They answer two questions: "What goes here?" and "What should I do next?"

This catalog is the single source of truth for every empty state in the app. Developers should reference this document when building any screen — an empty state is a required deliverable for every list, detail section, and tab.

### 1.1 Design Principles

- **Every empty screen drives action.** No blank screens. No "nothing here" dead ends.
- **Icon-based illustrations.** Simple, clean, minimal icons using the Keystona color palette. No photo-realistic images, no complex illustrations. Icons are max 120px tall, rendered in Deep Navy (#1A2B4A) or muted gray.
- **Tone matches the screen's importance.** Key feature screens get motivational copy with CTAs. Sub-screens get brief instructional copy.
- **Disappear on first data.** Empty states vanish as soon as one item exists. No lingering "getting started" messages once the user has content.

### 1.2 Visual Structure

There are three empty state patterns used across the app:

**Pattern A — Motivational (Key Feature Screens)**
```
┌─────────────────────────────────────────┐
│                                         │
│              [Icon · 120px]             │
│                                         │
│       Headline (20px, semibold)         │
│                                         │
│     Subtitle — 1-2 lines explaining    │
│     the value and suggesting a first   │
│     action. (16px, regular, gray)      │
│                                         │
│        ┌────────────────────┐           │
│        │   Primary CTA      │           │
│        └────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

**Pattern B — Showcase (Discovery Screens)**
```
┌─────────────────────────────────────────┐
│                                         │
│       Headline (20px, semibold)         │
│     Subtitle (16px, regular, gray)     │
│                                         │
│  ┌──────────┐  ┌──────────┐            │
│  │ Example  │  │ Example  │  ← scroll  │
│  │ Card 1   │  │ Card 2   │            │
│  │ (ghosted)│  │ (ghosted)│            │
│  └──────────┘  └──────────┘            │
│                                         │
│        ┌────────────────────┐           │
│        │   Primary CTA      │           │
│        └────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

**Pattern C — Instructional (Sub-Screens)**
```
┌─────────────────────────────────────────┐
│                                         │
│             [Icon · 64px]               │
│                                         │
│       Headline (16px, semibold)         │
│     Subtitle (14px, regular, gray)     │
│                                         │
└─────────────────────────────────────────┘
```

### 1.3 Implementation Rules

- Empty states are **centered vertically** in the available space.
- **Primary CTA button:** Gold Accent (#C9A84C) background, white text, 8px border radius.
- Empty states **disappear immediately** when the first item of data exists — no transition animation needed.
- Pattern A and B screens must have the CTA button. Pattern C screens have no button unless there's an obvious single action.
- All text uses the standard Keystona typography (Outfit for headlines, Plus Jakarta Sans for body).

---

## 2. Tab-Level Empty States

These are the empty states for the five bottom navigation tabs.

### 2.1 Home Tab (Dashboard)

The Home tab uses the **onboarding setup checklist** as its empty state rather than a traditional empty state pattern. See Dashboard Spec Section 11 for the full onboarding flow.

| State | Behavior |
|-------|----------|
| Brand new user (post-onboarding) | Setup checklist card replaces sections 4–7. Hero shows rings at 0% with "—" in center. Quick actions visible. |
| Setup complete, no data yet | Normal dashboard with hidden sections (no Insights, no Urgent Banner, no Coming Up, no Completed). Only Greeting + Hero + Quick Actions visible. |
| Established user, all tasks complete | Coming Up and Urgent Banner hidden. Completed section shows recent completions. Greeting subtitle: "Your home is looking good." |

The Home tab never shows a traditional empty state illustration — it always has the Greeting + Hero + Quick Actions visible.

---

### 2.2 Documents Tab

**Pattern:** A — Motivational

| Element | Value |
|---------|-------|
| Icon | Document stack icon (120px, Deep Navy) |
| Headline | "Your Document Vault is ready!" |
| Subtitle | "Most homeowners start by uploading their insurance policy — it only takes 30 seconds." |
| CTA | "+ Add First Document" → opens document upload picker |

---

### 2.3 Tasks Tab (Maintenance Calendar)

**Pattern:** A — Motivational

| Element | Value |
|---------|-------|
| Icon | Wrench + calendar icon (120px, Deep Navy) |
| Headline | "Stay ahead of home repairs" |
| Subtitle | "We'll build a personalized maintenance plan based on your home's systems and climate. Add your first system to get started." |
| CTA | "+ Add a System" → navigates to Home Profile → Add System flow |

**Special state — all tasks completed, nothing due:**

| Element | Value |
|---------|-------|
| Icon | Checkmark in circle (120px, Success Green) |
| Headline | "All caught up! Nothing due right now" |
| Subtitle | "Great work keeping your home in shape. We'll let you know when something's coming up." |
| CTA | None — this is a celebration, not a call to action |

This celebration state appears when the user has active tasks in the system but none are currently due within the visible window and none are overdue.

---

### 2.4 Projects Tab

**Pattern:** B — Showcase

| Element | Value |
|---------|-------|
| Headline | "Organize renovations with phases, budgets, and before/after photos" |
| Subtitle | "Track every project from planning to completion." |
| Example cards | Two ghosted example project cards displayed in a horizontal scroll: |

**Example Card 1:**
```
┌──────────────────────────┐
│  🛁 Bathroom Renovation  │  ← ghosted (50% opacity)
│  Planning → Demo → Build │
│  ████████░░  62%         │
│  Budget: $12,500         │
└──────────────────────────┘
```

**Example Card 2:**
```
┌──────────────────────────┐
│  🪵 Deck Build           │  ← ghosted (50% opacity)
│  Design → Permit → Build │
│  ███░░░░░░░  28%         │
│  Budget: $8,200          │
└──────────────────────────┘
```

| CTA | "+ Start a Project" → opens project creation form |

The ghosted example cards give users an immediate understanding of what a project looks like in the app. They use 50% opacity and are non-interactive (tapping them does nothing — only the CTA button is tappable).

---

### 2.5 Settings Tab

Settings is a **static menu** — it does not have an empty state. It always shows the full menu structure regardless of user data:

- Account (name, email, subscription tier)
- Property (address, switch property for Family tier)
- Notifications (push preferences, timing)
- Maintenance Tasks (dismissed tasks, task preferences)
- Subscription (current plan, upgrade/manage)
- Data & Privacy (export data, delete account)
- Help & Support
- About (version, legal)

No dynamic content. No empty states needed.

---

## 3. Feature Screen Empty States

### 3.1 Document Vault Sub-Screens

**Document category view (filtered, no docs in category):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Folder icon (64px, gray) |
| Headline | "No [category] documents yet" |
| Subtitle | "Tap + to upload your first [category] document." |

**Document search (no results):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Magnifying glass icon (64px, gray) |
| Headline | "No results found" |
| Subtitle | "Try a different search term or browse by category." |

---

### 3.2 Emergency Hub

Each utility shutoff type has its own motivational empty state:

**Water shutoff:**

| Pattern | A — Motivational |
|---------|-------------------|
| Icon | Water droplet icon (120px, Deep Navy) |
| Headline | "Know your water shutoff" |
| Subtitle | "In a burst pipe emergency, every second counts. Add your water shutoff location so it's always one tap away." |
| CTA | "+ Add Water Shutoff" |

**Gas shutoff:**

| Pattern | A — Motivational |
|---------|-------------------|
| Icon | Flame icon (120px, Deep Navy) |
| Headline | "Locate your gas shutoff" |
| Subtitle | "Gas leaks are rare but serious. Document your shutoff valve location now so you're ready if it happens." |
| CTA | "+ Add Gas Shutoff" |

**Electrical panel:**

| Pattern | A — Motivational |
|---------|-------------------|
| Icon | Lightning bolt icon (120px, Deep Navy) |
| Headline | "Find your electrical panel" |
| Subtitle | "Whether it's a tripped breaker or an emergency, knowing your panel location saves time and stress." |
| CTA | "+ Add Electrical Panel" |

**Emergency contacts (no contacts):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Phone icon (64px, gray) |
| Headline | "No emergency contacts yet" |
| Subtitle | "Tap + to add a plumber, electrician, or other pro." |

**Insurance quick reference (not entered):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Shield icon (64px, gray) |
| Headline | "No insurance info yet" |
| Subtitle | "Add your policy number and claims phone for quick access during emergencies." |

---

### 3.3 Home Profile

**Systems list (no systems):**

| Pattern | A — Motivational (Combined) |
|---------|-------------------|
| Icon | Home systems icon — simplified house with gear (120px, Deep Navy) |
| Headline | "Add your home's systems" |
| Subtitle | "Systems are the major components of your home — HVAC, plumbing, electrical, roofing, and more. Adding them unlocks personalized maintenance tasks and lifespan tracking." |
| CTA | "+ Add First System" → opens system creation form |

**Appliance list (no appliances):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Appliance icon (64px, gray) |
| Headline | "No appliances tracked yet" |
| Subtitle | "Tap + to add your refrigerator, washer, or other appliances." |

**System detail — service history (no completions for this system):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Clock/history icon (64px, gray) |
| Headline | "No service history yet" |
| Subtitle | "Completed maintenance tasks for this system will appear here with cost and notes." |

---

### 3.4 Project Detail Sub-Sections

These empty states appear within sections of a project detail screen when the user has created a project but hasn't populated all sections.

**Budget section (no budget items):**

| Pattern | Single CTA card |
|---------|-----------------|
| Layout | Compact card within the budget section area (not full-screen) |
| Icon | Dollar sign icon (48px, Gold Accent) |
| Headline | "Track your project budget" |
| Subtitle | "Add line items to monitor spending against your budget. See totals, categories, and how actual costs compare to estimates." |
| CTA | "+ Start Tracking" → opens budget item creation form |

**Photos section (no photos):**

| Pattern | Single CTA card |
|---------|-----------------|
| Layout | Compact card within the photos section area |
| Icon | Camera icon (48px, Deep Navy) |
| Headline | "Document your progress with before & after photos" |
| Subtitle | "Capture each phase of your project. Photos are saved to your project timeline." |
| CTA | "+ Add Photo" → opens camera/photo picker |

**Phases section (no phases defined):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Checklist icon (64px, gray) |
| Headline | "No phases defined yet" |
| Subtitle | "Break your project into phases like Planning, Demo, and Build to track progress." |

**Notes section (no notes):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Pencil icon (64px, gray) |
| Headline | "No notes yet" |
| Subtitle | "Jot down contractor quotes, material choices, or decisions as you go." |

---

### 3.5 Maintenance Calendar Sub-Screens

**Task completion history (global — no completions ever):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Checkmark list icon (64px, gray) |
| Headline | "No completed tasks yet" |
| Subtitle | "Completed maintenance tasks will appear here with cost and notes." |

**Overdue tasks filter (no overdue tasks):**

| Pattern | C — Instructional (Celebration variant) |
|---------|-------------------|
| Icon | Checkmark in circle (64px, Success Green) |
| Headline | "Nothing overdue!" |
| Subtitle | "You're on top of your home maintenance. Keep it up." |

---

### 3.6 Notifications

**Notification inbox (no notifications):**

| Pattern | C — Instructional (Positive) |
|---------|-------------------|
| Icon | Bell icon (64px, gray) |
| Headline | "All caught up!" |
| Subtitle | "You'll see maintenance reminders and expiration alerts here." |

---

### 3.7 Settings Sub-Screens

**Dismissed tasks list (no dismissed tasks):**

| Pattern | C — Instructional |
|---------|-------------------|
| Icon | Eye-off icon (64px, gray) |
| Headline | "No dismissed tasks" |
| Subtitle | "Tasks you mark as 'not applicable' to your home will appear here. You can re-enable them anytime." |

---

## 4. Free-Tier Limit States

When a user on the Free tier is approaching or has reached their content limit, the app shows a **subtle upgrade banner** in addition to the normal content. This is NOT a replacement for the empty state — it's an additive element that appears alongside existing content.

### 4.1 Approaching Limit Banner

Shown when the user is within 1–2 items of their tier limit.

```
┌─────────────────────────────────────────┐
│  ⬆ You've used 4 of 5 documents.       │  ← Subtle amber background
│    Upgrade for unlimited storage →      │  ← "Upgrade" is tappable
└─────────────────────────────────────────┘
```

**Rules:**
- Background: Light amber (#FFF8E7)
- Text: 14px, regular
- "Upgrade" link: Gold Accent, taps to subscription screen
- Appears as a persistent banner at the top of the list, above the content
- Does not replace content or empty states

### 4.2 Limit Reached Banner

Shown when the user has hit their tier limit and cannot add more items.

```
┌─────────────────────────────────────────┐
│  ⬆ Document limit reached (5/5).       │  ← Subtle amber background
│    Upgrade to Premium for unlimited →   │
└─────────────────────────────────────────┘
```

**Rules:**
- Same visual treatment as approaching-limit banner
- The "+ Add" button/FAB is **still visible** but tapping it triggers the upgrade sheet (per Error Handling Guide) instead of opening the creation form
- Existing content is fully visible and functional below the banner

### 4.3 Where Limit Banners Apply

| Screen | Free Tier Limit | Banner Trigger |
|--------|----------------|----------------|
| Document Vault | 5 documents | At 4/5 (approaching) and 5/5 (reached) |
| Systems | 5 systems | At 4/5 and 5/5 |
| Appliances | 10 appliances | At 8/10 and 10/10 |
| Projects | 1 project | At 1/1 (reached only — no "approaching" for limit of 1) |
| Emergency Contacts | 3 contacts | At 2/3 and 3/3 |

**Note:** Tier limits are defined in the monetization strategy and may be adjusted. This catalog uses the current limits as reference. The banner component should accept the limit values as parameters, not hardcode them.

---

## 5. Dashboard Section Empty States

Dashboard sections are hidden when empty (per Dashboard Spec Section 3), so they don't have traditional empty states. However, there are specific behaviors worth documenting:

| Dashboard Section | When Empty | Behavior |
|-------------------|-----------|----------|
| Insights | No insight conditions met | Section hidden entirely |
| Urgent Banner | No overdue/expiring items | Section hidden entirely |
| Coming Up (Tasks) | No tasks due in next 30 days | Section hidden entirely |
| Completed | No completions in last 7 days | Section hidden entirely |

The dashboard never shows empty state illustrations for individual sections. If all optional sections are empty, the user sees: Greeting → Hero → Quick Actions → end of scroll. This is acceptable and by design — it means the user's home is in good shape and there's nothing to act on.

---

## 6. Offline Empty States

When the device is offline, most screens show a connection-required state instead of their normal empty state. The Emergency Hub is the exception — it works fully offline.

**Offline state (all screens except Emergency Hub):**

```
┌─────────────────────────────────────────┐
│                                         │
│          [Wifi-off icon · 64px]         │
│                                         │
│        No internet connection           │
│                                         │
│  Connect to load your data. Your        │
│  Emergency Hub is still available        │
│  offline.                               │
│                                         │
│      ┌──────────────────────┐           │
│      │  Go to Emergency Hub │           │
│      └──────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

This state takes priority over any content-based empty state. If the user regains connectivity, the screen refreshes automatically and shows the appropriate state (content, empty, or loading skeleton).

---

## 7. Complete Screen Inventory

Every screen in the app and its empty state status:

| Screen | Empty State Pattern | Defined In |
|--------|-------------------|------------|
| **Home Tab** | Onboarding checklist (special) | Dashboard Spec §11 |
| **Documents Tab** | A — Motivational | §2.2 |
| Documents — Category filter | C — Instructional | §3.1 |
| Documents — Search results | C — Instructional | §3.1 |
| **Tasks Tab** | A — Motivational | §2.3 |
| Tasks — All caught up | A — Celebration | §2.3 |
| Tasks — Completion history | C — Instructional | §3.5 |
| Tasks — Overdue filter | C — Celebration | §3.5 |
| **Projects Tab** | B — Showcase | §2.4 |
| Project Detail — Budget | CTA Card (inline) | §3.4 |
| Project Detail — Photos | CTA Card (inline) | §3.4 |
| Project Detail — Phases | C — Instructional | §3.4 |
| Project Detail — Notes | C — Instructional | §3.4 |
| **Settings Tab** | None (always has menu) | §2.5 |
| Settings — Dismissed tasks | C — Instructional | §3.7 |
| **Emergency Hub — Water** | A — Motivational | §3.2 |
| **Emergency Hub — Gas** | A — Motivational | §3.2 |
| **Emergency Hub — Electrical** | A — Motivational | §3.2 |
| Emergency Hub — Contacts | C — Instructional | §3.2 |
| Emergency Hub — Insurance | C — Instructional | §3.2 |
| **Home Profile — Systems** | A — Motivational (Combined) | §3.3 |
| Home Profile — Appliances | C — Instructional | §3.3 |
| Home Profile — Service history | C — Instructional | §3.3 |
| **Notifications** | C — Instructional (Positive) | §3.6 |
| **Offline (all non-Emergency)** | Special — connection required | §6 |

**Total: 25 defined empty states** across the app.

---

## 8. Implementation Checklist

For every screen a developer builds, verify:

- [ ] Empty state exists and matches this catalog
- [ ] Empty state is centered vertically in available space
- [ ] Icon is the correct size (120px for Pattern A/B, 64px for Pattern C, 48px for inline CTA cards)
- [ ] Icon uses correct color (Deep Navy for motivational, gray for instructional, themed for special)
- [ ] CTA button uses Gold Accent (#C9A84C) background with white text
- [ ] Empty state disappears when first item of data is added
- [ ] Free-tier limit banner shows when applicable (approaching + reached)
- [ ] Offline state takes priority when device has no connectivity
- [ ] Empty state copy matches this catalog exactly (do not improvise copy)

---

## 9. Cross-References

| Topic | Document | Section |
|-------|----------|---------|
| Empty state visual patterns & CSS | Error Handling Guide | Section 4 |
| Loading skeletons (precede empty states) | Error Handling Guide | Section 3 |
| Dashboard onboarding checklist | Dashboard Spec | Section 11 |
| Free-tier limits & upgrade sheet | Error Handling Guide | Section 14 |
| Offline architecture | Error Handling Guide | Section 5 |
| Screen build order (skeleton → empty → content) | SKILL.md | Standard Screen Build Order |

---

*End of Empty States Catalog*  
*HomeTrack (Keystona) — Version 1.0 — February 2026*
