# Keystona — Implementation Notes (from the Aurora storyboard)

**Started:** Oct 5, 2026 · **Status:** Living list. Add to it whenever a storyboard decision needs to carry into the Flutter build.
**Why this exists:** Some decisions only show up as behaviour, so a static screen can't capture them. Read this alongside the storyboard (Aurora storyboard artifact) and `Keystona_Screen_Inventory.md` before building a screen in Claude Code.

---

## Gestures & interactions

| Rule | Where | Storyboard |
|---|---|---|
| **Long-press any task row** opens a context menu. The pressed row lifts, the screen behind blurs, and the menu opens under the row with: Skip this time · Change how often (inline chips) · Open the task · Stop reminding me (coral, set apart at the bottom). Tap outside to dismiss; there's no Cancel button. | Every task row: Home "Do this next", Home coming-up list, Tasks tab, a system's task list | 4.5 |
| **No ⋯ buttons on task rows.** Long-press replaces them so rows stay uncluttered. | All task rows | — |
| Every task action (skip, frequency change, stop) ends with a dark snackbar that has **Undo**. Use a 5 s window, matching the Sprint Plan undo pattern. | Global | 4.5 |

## Turning reminders on and off

- Every task belongs to exactly one parent: a **system**, an **appliance**, or an **area of the house** (Safety, Outside, Yard, From your climate, Yours). Store the area in `maintenance_tasks.category`, so there's no "miscellaneous" pile.
- **Main place to manage:** each parent's reminders screen, with a switch and a "how often" picker per reminder and a "Turned off" section at the bottom.
  - Systems and appliances: *Manage* on the item's task list (2.19 → 2.22).
  - Whole-house reminders: Home profile → Around the house (2.23).
- **First pass:** "Review your reminders" during setup (2.30). It's step 2 of the setup checklist, with a "Turn all on" option and a "Looks good — keep N" button.
- **Safety net:** Settings → Turned-off reminders (6.11), grouped by parent, with Turn on / Undo.
- Turned-off reminders are **hidden everywhere** and **excluded from Home Health** (both numerator and denominator).
- Turned-off state is **property-scoped** and resets on a new home (Dashboard Spec §6).
- Climate-generated reminders carry a small reason tag (FREEZE / HUMID / STORMS) so people know why they're there.
- User-created reminders get Edit and Delete, not a switch.
- When a matching item is added (e.g., a sump pump), its area reminders move to that item automatically.

## Home tab states (Dashboard States spec, Aurora version)

- **The coral hero card never changes color.** Urgency comes from content: overdue count, the overdue card, banners, and the trend arrow. The score number stays white.
- **Overdue card:**
  - Shows the most urgent task large, with Mark done / Snooze.
  - Up to 2 more overdue rows, then "+ N more", then "Review all N overdue".
  - The CTA becomes coral when the home is at risk (score < 40).
- **Quick wins line** (at risk only): suggests the 3 shortest overdue tasks plus the score they'd recover.
- **Urgent banners** (insurance, emergency setup, freeze warnings) sit below the overdue card, with a colored left border and an × to hide for the session.
- **Returning user** (30+ days away): the greeting changes to "Welcome back", and a "While you were away" list marks each new item with a lime dot (tasks that came due, a warranty that ended, a project that finished). This shows for one session only.
- **Offline:**
  - A top banner shows "You're offline · Emergency still works · last synced". It's a white bar with an amber rule; no tinted fills.
  - Scan and Add task are dimmed, and tapping them shows a snackbar.
  - **Mark done still works**: it's saved on the phone and syncs later. The button turns lime with "Done · will sync".
- **Setup checklist:** it replaces the data sections during setup (2.24). Once setup is mostly done it shrinks to a one-line "N steps left" card (2.25).

## Shopping path

- A saved home is `properties.is_prospective = true`. Buying it converts the home and carries its records over: documents, systems with ages, open repairs → tasks, Monitor items → reminders, tour photos.
- Inspection extraction from PDFs is a stretch feature. The cheaper fallback is storing the PDF and letting users tag findings themselves.

## Home History Report (the "CarFax") — proposed Oct 5, pending Caleb's call

- **Short by default: 3 pages for a sale.** The PDF is a summary. The live link carries the detail: any line opens to its receipt, photos or the full log. (Revised Oct 5 from a 13-page draft.)
  1. **The house at a glance:** address and facts in the header, plus 4 numbers (record complete, tasks on time, improvement spend, warranties that transfer). Also "Worth knowing", the trust-mark key and the verify link.
  2. **Systems & upkeep:** one table with life used, upkeep summed up per system ("Serviced every fall · 4×") and warranty, with appliances on a single line. Under it, "Coming up · next 5 years" in 3 lines. Warranties and coming-up are no longer separate sections.
  3. **Improvements:** one short entry per project with a before/after thumbnail, dates, cost, who did it and the documented count.
  - Optional extras, off for selling: the full maintenance log (+2 pages), belongings & photos (+2), and emergency info (+1, never in the Selling preset).
  - Original files: listed by title only, added as pages at the end, or offered as a separate ZIP.
- **Trust marks.** Every entry is either ✓ **Documented** (a receipt, invoice or photo is on file) or ○ **Owner-reported**. The cover says "Prepared by the owner using Keystona. Not a home inspection."
- **Purpose presets** set the section and privacy defaults: Selling / Insurance or a claim / Refinance or appraisal / Just for me. Everything can be overridden per section.
- **Money setting:** every cost, totals only, or no money.
- **Privacy switches:**
  - hide the purchase price
  - show "Owner" instead of names
  - mask serial and policy numbers (••••7719)
  - leave out interior photos
  - Emergency info is never included in the Selling preset.
- **Sharing:**
  - **Live link:** either stays up to date or is frozen to today's version. It expires in 30 days, after closing, or never. It shows an opened count and can be turned off.
  - **PDF:** a snapshot of today.
  - **QR code:** for flyers and open houses; it opens the live link.
  - Every report has an ID that can be verified at keystona.app/r/ID.
- **Projects in the report:**
  - Each finished project is one short entry on the Improvements page. The full photo set and receipts are at the link.
  - The builder's "Improvements & projects" row opens a picker (6.15). Each project has just an include checkbox. Small owner-reported DIY jobs start unchecked so the report doesn't look padded.
  - In-progress projects stay out by default. They can be added as "In progress" (shows the plan and the permit), which helps if the owner lists before the work is done.
  - The "Next time" notes are never included in the report.
  - The At-a-glance improvements total counts only the projects that are included.
- **Sharing one project** (5.24, from Share on a finished project): a one-page link, the before/after image alone, or "In my Home History Report", which confirms the project is already on the report's Improvements page. The one-page link has its own switches for cost, who did the work and notes.
- **Storyboard:** 6.12 builder → 6.15 pick projects → 6.13 preview → 6.14 share; 5.22 finished project → 5.24 share one project.
  - It's reached from the Home profile's History Report card.
  - It's Premium (HR-007). The free "Request a copy" data export in 6.8 stays separate.

## Budget

- The final budget design is **5.9** (overview → tap a category) plus **5.10** (at scale: over time, plus a receipt grouped by trip or by item). The Squares, Receipt-only and Jars options are retired.

## Design rules to keep enforcing

- No tinted fills. Use outlines, solid lime or solid coral.
- Use coral only for "act now".
- Cobalt is for actions and progress; amber means soon; lime/olive means done or a win.
- Touch targets must be at least 44 px.
