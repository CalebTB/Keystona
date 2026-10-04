# Keystona — Complete Screen Inventory

**Version 1.0 · June 2026 · Active**
**Status:** Canonical. This is the authoritative list of every screen, modal, and sheet in the Keystona MVP.
**Consumes:** `Keystona_Aurora_Design_System.md` · `Keystona_Aurora_Form_Schemas.md` · `Keystona_Aurora_Component_Library.md` · `HomeTrack_Sprint_Plan.md` · `HomeTrack_SRS.md`
**Owners:** Integration agent (route map) · Flutter agent (screen scaffolding) · Subscription/QA agent (Premium gates)

---

## Inventory at a glance

| Category | Count |
|---|---|
| Primary screens | 68 |
| Modal & sheet surfaces | 19 |
| Edit overlays | 9 |
| **Total distinct surfaces** | **96** |

---

## Legend

- **Primary** — full-screen view the user lands on as a destination
- **Modal** — interruptive dialog requiring acknowledgment or confirmation
- **Sheet** — bottom sheet for selection or secondary editing (dismissable)
- **Edit** — edit overlay variant of a detail screen, follows canonical form pattern
- **🔒 Premium** — Premium-tier feature or gate
- **★ Tier** — varies by subscription tier (Free / Premium / Family)

---

## 1. Auth & onboarding (11 screens)

The first-run flow, from app install through the user's first meaningful Dashboard view.

| # | Name | Type | Notes |
|---|---|---|---|
| 01 | Splash &amp; loading | Primary | App entry. Coral hero with yellow blob, "Keystona" wordmark in Inter 800. Auto-routes to Welcome (new) or Dashboard (returning, logged-in). |
| 02 | Welcome | Primary | Editorial value-prop screen. "The full record of your home — protected." Sign up + Log in CTAs. |
| 03 | Sign up | Primary | Email / password / Apple / Google. Three-button stack. Same canonical form pattern as Schemas (single section, three fields). |
| 04 | Log in | Primary | Email / password / Apple / Google. "Forgot password?" link. |
| 05 | Forgot password | Primary | Email-only field + Send link CTA. Routes back to Log in. |
| 06 | Email verification | Modal | "Check your email" message after sign up. Resend link option. |
| 07 | Persona fork | Primary | Branch point: "I just bought a home" (Owner path) vs "I'm shopping" (Buyer path). Both paths create a `properties` row at this step; Buyer path marks it as `is_prospective: true`. |
| 08 | Property setup | Primary | Address autocomplete + Property type select + Year built + Square footage. Submit creates the property record. |
| 09 | Climate detect result | Sheet | Auto-detected from ZIP via Edge Function. Confirms zone + description + HDD/CDD. User cannot manually override — this is auto-detected only. |
| 10 | Trial offer | Primary | Premium pricing screen ($9.99/mo or $79.99/yr, 30-day trial, card upfront). Skippable to Free tier. |
| 11 | Setup checklist welcome | Primary | "Here's what to do next" with 3–5 checklist items routing into Add System, Scan a document, Set up Emergency Hub. Replaces Dashboard for users with sparse data. |

---

## 2. Home tab (dashboard) (9 screens)

Per `HomeTrack_Dashboard_Spec.md` and `HomeTrack_Dashboard_States.md`, the Home tab has 8 canonical states plus a relevance review surface. Each is the *same screen layout* with different content density, but they're listed separately because each requires distinct copy, empty states, and routing logic.

| # | Name | Type | Notes |
|---|---|---|---|
| 12 | Dashboard · day one | Primary | First-run after onboarding. Coral hero with yellow blob, score 0 or N/A, large empty-state CTA: "Add a system to start." Setup checklist optionally embedded. |
| 13 | Dashboard · mid-setup | Primary | User has added 1–3 systems but ≤ 5 docs. Hero shows tentative score with "Setup in progress" trend label. |
| 14 | Dashboard · sparse | Primary | User has data but minimal recent activity. "Coming up" section shows 0–2 tasks. |
| 15 | Dashboard · healthy | Primary | Steady-state. Score 80+, "Stable this month" trend in lime, 3+ tasks in Coming Up. The screenshotable state. |
| 16 | Dashboard · needs attention | Primary | 1–3 overdue items. Hero score drops, coral-dim warning banner above hero: "3 tasks need attention." Coral overdue chip on affected task rows. |
| 17 | Dashboard · at risk | Primary | 4+ overdue OR insurance expiring &lt; 7 days OR critical emergency setup missing. Hero score is red zone; full-width coral banner above hero with primary action: "Address now." |
| 18 | Dashboard · returning user | Primary | User returns after &gt; 14 days. Hero retains last score but adds a "Welcome back" eyebrow. New items since last visit highlighted with lime "new" dot. |
| 19 | Dashboard · offline | Primary | Same content as healthy/sparse but with the offline banner (`Keystona_Aurora_Component_Library.md` §14). Quick Actions disabled except Emergency. |
| 20 | Task relevance review | Primary | Reached from Dashboard "Review tasks" CTA. List of recently auto-generated tasks with Keep / Dismiss / Edit-recurrence options per row. Bulk action: "Keep all" / "Review one by one." |

---

## 3. Document vault (12 screens)

The Docs tab and its sub-screens. Document vault is the highest-touch data screen in the app.

| # | Name | Type | Notes |
|---|---|---|---|
| 21 | Document list | Primary | Headline + count `[N] of 50`. Search bar. Filter chips by category. Document cards in vertical list. FAB to add. |
| 22 | Document list · empty | Primary | Empty State Pattern A (Motivational). Coral hero icon, primary CTA "+ Add a document", alternate CTA "Or scan one" (Smart scan path, Premium-gated). |
| 23 | Document detail | Primary | Single-doc view. Thumbnail at top, metadata card (category, date, expiration, tags), linked entity chip, notes, action row (View / Share / Edit / Delete). |
| 24 | Document edit | Edit | Schema 5 fields without the File picker. Title becomes "Edit document." |
| 25 | Upload source picker | Sheet | Action sheet variant: "Take photo" / "Pick from library" / "Pick from Files app" / "Smart scan 🔒". Compact 35% sheet. |
| 26 | Camera capture | Primary | Native camera with rectangular frame overlay. Lime corner brackets when capture is ready. Tap shutter or auto-detect for paper-edge alignment. |
| 27 | Category selection | Sheet | Picker sheet. Filter by standard / custom categories. Premium users see "+ Custom category" at the bottom. |
| 28 | Upload metadata form | Primary | Schema 5 form. After capture or pick, this is where the user names + categorizes + sets expiration. |
| 29 | OCR processing status | Modal | 🔒 Premium-only. Cobalt progress bar inside a modal with "Reading the document…" copy. Auto-dismisses on completion → routes to extracted-fields confirmation. |
| 30 | Search results | Primary | Same layout as Document list but filtered by the search query. Search highlight on matched terms in document names (full-text content search is Premium-only). |
| 31 | Expiration dashboard | Primary | Reached from Docs tab → "Expiring soon" chip in the filter row. Sorted by expiration date ascending. Each card shows days-until-expiry chip in coral-dim (urgent) / yellow-dim (soon) / cobalt-dim (later). |
| 32 | Custom category manager | Primary | 🔒 Premium-only. List of user's custom categories. Tap to edit, swipe to delete (with reassignment modal). Add new via FAB. |

---

## 4. Tasks · maintenance (11 screens)

The Tasks tab. Filtered task lists across systems/appliances live in the Home Profile area, not here.

| # | Name | Type | Notes |
|---|---|---|---|
| 33 | Task list · daily | Primary | Default Tasks tab view. "Today" + "This week" + "Later this month" sections. Each task row uses canonical task component (`Keystona_Aurora_Design_System.md` §6.5). |
| 34 | Task list · seasonal | Primary | Toggle from Daily view. Tasks grouped by season + month. Better for first-30-days new users seeing the year's rhythm. |
| 35 | Task list · by system | Primary | Toggle from Daily. Grouped by linked system/appliance. Useful for power users planning by component. |
| 36 | Task list · all caught up | Primary | Empty State Pattern D (Celebration). Lime check circle, "You're all caught up." No CTA. |
| 37 | Task detail | Primary | Single-task view. Coral overdue banner if applicable, stat row (time/difficulty/cost), grouped info card (system / recurrence / method / last done), instructions block, CTA pair `Mark done` / `Add details`. |
| 38 | Task edit | Edit | Schema 6 form. Title "Edit task." |
| 39 | Mark done · quick | Modal | Confirmation flavor: "Mark done now? +3 health points." Optional cost field + note field. Single cobalt Confirm + ghost Cancel. |
| 40 | Add details · form | Primary | Long-form completion record. Cost actual, contractor used (link picker), photos before/after, notes. Used when user taps "Add details" instead of "Mark done." |
| 41 | Skip task · reason | Sheet | Action sheet: "Not applicable" / "Done by someone else" / "Will do later" / "Cancel." Selecting a reason updates recurrence handling. |
| 42 | Create custom task | Primary | Schema 6 form. Title "New task." |
| 43 | Completion history | Primary | Reached from Task detail → "History" link. Vertical timeline of past completions for this recurring task. Each entry shows date, who did it, cost, notes, photos. |

---

## 5. Home profile (11 screens)

The property-specific deep view. Reached by tapping the home strip on the Dashboard. Distinct from Dashboard (which is portfolio-wide). The Home Profile is the parent for Systems, Appliances, and Lifespan sub-screens.

| # | Name | Type | Notes |
|---|---|---|---|
| 44 | Home profile overview | Primary | Property hero card, Needs Attention banner (if applicable), Health rings (3-pillar), Active Project preview, Quick stats, 5-year forecast, Systems/Appliances strip, Recent activity feed. |
| 45 | Edit property | Edit | Schema-like form for the property record. Address (autocomplete), type, year built, square footage, lot size, climate zone (read-only, auto-detected), photos. |
| 46 | Systems list | Primary | List of all systems for the property. Filter chips by category. Each row shows name, category icon, lifespan progress bar mini, linked task count. |
| 47 | System detail | Primary | Dossier-style detail (per the Appliance Detail Dossier variant). Hero with category icon + name + brand/model, lifespan card, identification card, install/warranty card, linked tasks count, linked documents count, photos grid. |
| 48 | Add &middot; edit system | Edit | Schema 1 form. |
| 49 | Appliances list | Primary | Same layout pattern as Systems list. Filter chips by category (kitchen/laundry/etc.). |
| 50 | Appliance detail | Primary | Dossier-style detail. Same component pattern as System detail. Includes the JSONB specifications accordion. |
| 51 | Add &middot; edit appliance | Edit | Schema 2 form. |
| 52 | Item tasks · filtered | Primary | Tasks list filtered to a single system or appliance. Reached from System detail / Appliance detail → tasks count tap. Uses the Item Tasks Striped variant (per the variant exploration). |
| 53 | Item photos | Primary | Photo gallery for a single system or appliance. Reached from System/Appliance detail → photos count tap. Uses photo grid pattern + photo viewer. |
| 54 | Lifespan overview | Primary | Portfolio-wide lifespan view. Vertical list of systems and appliances sorted by % through lifespan. Each row shows progress bar, expected replacement date, estimated cost. Premium tier shows replacement cost forecast totals. |

---

## 6. Emergency hub (10 screens)

The Emergency Hub is reached from a permanent surface (Quick Action on Dashboard) — not a tab — but it has its own sub-screen tree.

| # | Name | Type | Notes |
|---|---|---|---|
| 55 | Emergency hub main | Primary | Ink banner with "Works offline · last synced N min ago", coral 911 call card, three shutoff cards (Water / Gas / Electric) with completion states, pinned contacts list with tap-to-call buttons. |
| 56 | Shutoff detail · water | Primary | Detail screen for the water shutoff. Location description (large), valve type, turn direction, tools required, special instructions, location photo, valve close-up photo. Edit button at top. |
| 57 | Shutoff detail · gas | Primary | Same pattern as water. Specific copy for gas (relight pilot warnings, smell-gas-call-911 banner). |
| 58 | Shutoff detail · electrical | Primary | Same pattern. Breaker panel diagram support (optional photo annotation). |
| 59 | Shutoff setup form | Edit | Sub-form D from Form Schemas §13.4. Modal sheet at 85% height. The single offline-required form in the app. |
| 60 | Emergency contacts list | Primary | All contacts. Filter chips: Pinned / Plumber / Electrician / etc. Pinned (favorite) contacts at the top with coral avatars. Tap-to-call icons on each row. |
| 61 | Contact detail | Primary | Single contact view. Avatar, name, company, category, all phone numbers, email, hours, 24/7 badge if applicable, notes, "edit" and "remove" actions. If this contact is also on a project, shows the project link with role. |
| 62 | Add &middot; edit contact | Edit | Schema 3 form. |
| 63 | Insurance list | Primary | All insurance policies. Each card shows type, carrier, policy number (mono), coverage amount, renewal date. Renewal-soon badges in coral-dim or yellow-dim. |
| 64 | Add &middot; edit insurance | Edit | Schema 4 form. |

---

## 7. Projects (13 screens)

The Projects tab and its sub-page tree. Projects have the most complex sub-page architecture of any feature.

| # | Name | Type | Notes |
|---|---|---|---|
| 65 | Projects list · empty | Primary | Empty State Pattern B (Showcase) — ghosted example project cards at 30% opacity, centered CTA. |
| 66 | Projects list · active | Primary | Two sections: "In progress" (active + on hold projects) and "Completed" (retrospective view). Each card: cover photo, name, status badge, progress bar, budget snapshot. |
| 67 | Create project | Primary | Schema 7 form. Title "New project." |
| 68 | Project detail · active | Primary | Coral project hero with progress bar, lime fill, budget snapshot. Tab row: Overview / Phases / Budget / Photos / Notes. Per the three-file spec pattern, the active default wraps the "Overview" tab. |
| 69 | Project detail · retrospective | Primary | Same screen wrapper but loads when status is `completed` or `cancelled`. Tab row stays but Photos becomes default tab. Includes "Project complete" celebration banner. |
| 70 | Phases editor | Primary | The Phases tab content. List of phases with drag-to-reorder. Each phase shows status (done/active/scheduled/skipped), date range, budget allocation. Add via inline `+` button. |
| 71 | Budget overview | Primary | The Budget tab content. Header row: estimated total vs actual spent, with over/under badge. Line item list grouped by category. Each line shows estimated vs actual, paid toggle status, linked receipt chip. |
| 72 | Add &middot; edit line item | Edit | Schema 8 form. Modal sheet at 50% height. |
| 73 | Contractors list | Primary | The Contractors tab content. List of contractors on this project. Each row: avatar, name, role, contract amount, amount paid, rating (if project completed). Tap to edit role / unlink. |
| 74 | Photo gallery | Primary | The Photos tab content. Grid view by default; toggle to Pair view (before/after) or Timeline view. Each photo tap opens the photo viewer. |
| 75 | Before &middot; after slider | Primary | Reached from Photo gallery → tap a before/after pair. Full-screen split-screen viewer with the lime drag handle. Day-count and phase label below. |
| 76 | Project journal | Primary | The Notes tab content. Vertical feed of journal entries sorted by note date descending. Each entry: title (or first 40 chars), content excerpt, phase link if any, date stamp. Tap to expand or edit. |
| 77 | Link documents picker | Sheet | Bottom sheet for linking documents to a project from any project sub-screen. Filter chips: All / Receipt / Permit / Contract. Search bar. Add-new-via-upload at top. |

---

## 8. Settings &amp; account (10 screens)

The Settings tab.

| # | Name | Type | Notes |
|---|---|---|---|
| 78 | Settings hub | Primary | Ink account card (avatar + name + email), coral Premium card (if Free) or "★ Premium active" status card (if Premium). Sectioned list: App / Notifications / Subscription / Household / Data / Support. |
| 79 | Edit profile | Edit | Name, email (read-only after sign up), avatar upload, password change. |
| 80 | Notifications preferences | Primary | Toggle per notification type (task reminders 7-day, task reminders 1-day, expiring warranties, insurance renewals, recall alerts, weather alerts). Lead-time selectors per type. Quiet hours setting. |
| 81 | Subscription &middot; current plan | Primary | Current tier card with Premium "★ Premium" badge or Free "FREE" badge. Billing cycle, next renewal date, payment method, "Manage in App Store" deep link, downgrade / cancel options. |
| 82 | Premium upgrade | Primary | The conversion screen. Coral hero, feature list (unlimited docs, Smart scan, weather alerts, recall monitoring, Home History Report), plan picker (Monthly $9.99 / Annual $79.99 with "Save 33%" badge), 30-day free trial CTA. |
| 83 | Household members | Primary | List of household members. Max 5 per `Keystona_Aurora_Form_Schemas.md` Schema 3 §9. Each member shows avatar, name, email, role (Owner / Editor / Viewer). Add via "+ Invite" button. |
| 84 | Invite member | Sheet | Email + role select + invite CTA. Sends email invitation. |
| 85 | Data export | Primary | 🔒 Premium-only. List of export types (Home History Report PDF, All documents ZIP, CSV of tasks completed). Each shows last export date + Generate button. PDFs generated via Edge Function. |
| 86 | Delete account confirm | Modal | Type-the-word-DELETE confirmation pattern. 30-day grace period explanation. Permanent delete after grace. |
| 87 | Help &amp; FAQ | Primary | Linked FAQ articles + Contact support email link + Terms / Privacy links. Static content. |

---

## 9. System &amp; shared surfaces (9 screens)

Cross-cutting surfaces that aren't bound to a single tab.

| # | Name | Type | Notes |
|---|---|---|---|
| 88 | Notification inbox | Primary | Reached from bell icon (top-right of Dashboard). List of past notifications (24-hour grouping). Each row: icon + message + timestamp + tap-to-context. Unread badge dot in coral. |
| 89 | Offline banner state | Primary | Not a screen per se — the global offline banner applied across all screens. Listed here because it must be implemented and tested as a state, not built per-screen. |
| 90 | Error &middot; retry | Primary | Network failure or app crash fallback. Coral hero with "Something went wrong" copy, retry button, support contact link. Used when a screen-level fetch fails irrecoverably. |
| 91 | Tier limit reached | Modal | Upgrade modal flavor. Triggered when user hits Free tier limits (50 docs, 2 projects, 10 contacts, 0 Smart scans). Routes to Premium upgrade screen. |
| 92 | Confirm delete | Modal | Generic confirmation modal used by every delete action. Title "Delete [entity name]?", body explains linked-records impact, coral primary Confirm + secondary Cancel. |
| 93 | Photo viewer | Modal | Full-screen photo viewer per `Keystona_Aurora_Component_Library.md` §6. Used by item photos, project photos, document image previews, shutoff photos. |
| 94 | PDF viewer | Modal | Full-screen PDF viewer per `Keystona_Aurora_Component_Library.md` §7. Used by document detail when file is a PDF. |
| 95 | Share sheet | Sheet | Native iOS / Android share sheet wrapping. Used for sharing documents, exporting reports, copying links. |
| 96 | Toast &amp; snackbar states | Primary | Not a screen — the global toast/snackbar layer per `Keystona_Aurora_Component_Library.md` §4. Listed here for completeness and test coverage. |

---

## Sub-form sheets (already covered, listed for completeness)

These five are documented in `Keystona_Aurora_Form_Schemas.md` §13 and not counted in the 96 above (they're sub-forms that render *inside* parent screens, not standalone). Listed here so the inventory is exhaustive.

- **Sub-form A** — Phase (within Project Detail → Phases tab)
- **Sub-form B** — Add contractor to project (within Project Detail → Contractors tab)
- **Sub-form C** — Project note (within Project Detail → Notes tab)
- **Sub-form D** — Utility shutoff setup (within Emergency Hub → Shutoff detail)
- **Sub-form E** — Custom category (within Documents → Category picker)

---

## Cross-screen routing map (high level)

Major navigation paths between screens, for the Integration agent.

### Tab-level routes

```
[Bottom tab bar]
  ├─ Home          → #12-19 Dashboard states
  ├─ Docs          → #21 Document list
  ├─ Tasks         → #33 Task list
  ├─ Projects      → #66 Projects list
  └─ Settings      → #78 Settings hub
```

### Dashboard outbound

```
Dashboard (#15) ─┬─ Hero tap          → Home profile overview (#44)
                 ├─ Quick action Scan → Camera capture (#26) [🔒 Premium]
                 ├─ Quick action SOS  → Emergency hub main (#55)
                 ├─ Quick action Task → Create custom task (#42)
                 ├─ Coming up tap     → Task detail (#37)
                 ├─ Bell icon         → Notification inbox (#88)
                 └─ Needs attention   → Filtered Task list (#33 with filter)
```

### Home profile outbound

```
Home profile (#44) ─┬─ Edit              → Edit property (#45)
                    ├─ Systems strip     → Systems list (#46)
                    ├─ Appliances strip  → Appliances list (#49)
                    ├─ Lifespan strip    → Lifespan overview (#54)
                    ├─ Active project    → Project detail active (#68)
                    ├─ Forecast tap      → Lifespan overview (#54)
                    └─ Activity feed     → individual task/project/document details
```

### Project detail outbound

```
Project detail (#68) ─┬─ Phases tab      → Phases editor (#70)
                      ├─ Budget tab      → Budget overview (#71)
                      ├─ Photos tab      → Photo gallery (#74)
                      ├─ Notes tab       → Project journal (#76)
                      ├─ Contractor tap  → Contact detail (#61) via shared pool
                      └─ Edit            → Edit project (#67 in edit mode)
```

### Document detail outbound

```
Document detail (#23) ─┬─ Tap thumbnail   → Photo viewer (#93) or PDF viewer (#94)
                       ├─ Linked entity   → System/Appliance/Project detail
                       ├─ Share           → Share sheet (#95)
                       └─ Edit            → Document edit (#24)
```

### Emergency hub outbound

```
Emergency hub (#55) ─┬─ 911 card        → native phone dialer
                     ├─ Shutoff tap     → Shutoff detail (#56/57/58)
                     ├─ Shutoff edit    → Shutoff setup form (#59) [offline-capable]
                     ├─ Contact tap     → Contact detail (#61)
                     ├─ Phone icon      → tap-to-call (native)
                     ├─ Insurance tap   → Insurance list (#63)
                     └─ Add contact     → Add contact (#62)
```

---

## Premium-gated surfaces

For the Subscription/QA agent — every surface that's tier-gated or behaves differently per tier.

| Surface | Free behavior | Premium behavior |
|---|---|---|
| #25 Upload source picker | Smart scan option locked with 🔒 | Smart scan available |
| #26 Camera capture | Manual capture only | Smart scan auto-extract |
| #29 OCR processing | Not reached | Reached after Smart scan capture |
| #30 Search results | Filename / category search only | Full-text content search |
| #32 Custom category manager | Locked, opens Premium upgrade | Accessible, 10-category cap |
| #82 Premium upgrade | Reachable | Reachable as "Manage Premium" |
| #85 Data export | Locked | Accessible |
| Doc upload | 50-document cap | Unlimited |
| Project create | 2-project cap | Unlimited |
| Contact create | 10-contact cap | Unlimited |
| Photo grid per entity | 4 photos | Unlimited |
| Smart scan icon on form fields | `ink-tertiary` with lock badge | `coral` color, opens scanner |

---

## Screen IDs and routing convention

For the Flutter agent's router:

- Auth/onboarding screens use the prefix `/auth/` (e.g. `/auth/sign-up`, `/auth/property-setup`).
- Tab screens are root-level (`/home`, `/docs`, `/tasks`, `/projects`, `/settings`).
- Detail screens use entity prefixes (`/docs/:id`, `/systems/:id`, `/projects/:id`).
- Edit screens append `/edit` (`/projects/:id/edit`).
- Sub-tabs within Projects use query params (`/projects/:id?tab=budget`).
- Filtered views use query params (`/docs?category=warranty`, `/tasks?system=:id`).
- Modals and sheets are presented programmatically, not routed.

---

## Build order recommendation

For the Flutter agent, screens in approximate dependency order (consume the Aurora widget kit + Form widgets + Component library first):

**Foundation (already speccable, no UI dependencies)**
1. Splash &amp; loading (#01)
2. Welcome (#02)
3. Sign up (#03) / Log in (#04) / Forgot password (#05)
4. Email verification (#06)

**Onboarding flow (depends on Schema 7 property setup + auto-detect)**
5. Persona fork (#07)
6. Property setup (#08)
7. Climate detect result (#09)
8. Trial offer (#10)
9. Setup checklist welcome (#11)

**First content surfaces (depend on Schemas 1, 2, 5, 6)**
10. Dashboard · day one (#12) — needs empty state and Add System CTA wired
11. Add system (#48), Add appliance (#51), Add document (#28) — form schemas
12. Document list (#21) and detail (#23) — first true list screen
13. Systems list (#46) and System detail (#47)
14. Appliances list (#49) and Appliance detail (#50)

**Mid-build surfaces**
15. Task list daily (#33) and Task detail (#37)
16. Home profile overview (#44)
17. Dashboard states #13–#18 (now have real data to populate)
18. Emergency hub main (#55) and shutoff sub-forms

**Late-build surfaces**
19. Projects feature tree (#65–#77) — most complex sub-page architecture
20. Settings hub (#78) and sub-screens
21. Premium upgrade (#82) and tier-gated surfaces
22. Notification inbox (#88), data export (#85), and system surfaces

---

## Maintenance notes

- **When adding a new screen:** add a row to the appropriate category (1–9), increment the total count in the inventory-at-a-glance table, update the routing map if the screen has notable outbound paths.
- **When deleting a screen:** strike through the row but keep the number — number reuse causes confusion in cross-references. Update the count.
- **When changing a screen's Premium gating:** update the Premium-gated surfaces table.
- **When refactoring routing:** update the routing map; the Flutter agent's actual route map should match this doc.

---

*End of Keystona screen inventory.*
