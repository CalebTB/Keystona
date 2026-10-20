# Follow-ups

Things found while rebuilding the app to the Aurora kit that still need doing.
Newest context first. Delete a line when it is done.

## Missing links (a screen exists, nothing opens it yet)

| Screen | Route | Should be opened from | Fix in |
|---|---|---|---|
| Around-the-house reminders | `/home/reminders` (`AppRoutes.homeReminders`) | Home profile → "Around the house" | Sprint 3 (Home profile) |
| Turned-off reminders safety net | `/settings/reminders` (`AppRoutes.settingsReminders`) | Settings hub → "Turned-off reminders" | Sprint 7 (Settings) |
| Review your reminders (setup step 2) | `/maintenance/review` (`AppRoutes.maintenanceReview`) | Onboarding checklist step 2 (copy is fixed "Step 2 of 4") | Onboarding polish |
| Item reminders | — | System / appliance detail → ItemReminders | Sprint 3 |
| "Your categories" | `/documents/categories` | Reached only from the add-document category picker ("Manage" / "New category"); the Docs tab has no link | Sprint 1 polish |
| New users → onboarding | `/onboarding/resume` | After sign-up the router sends everyone to Home. Needs a gate: signed-in + no property + onboarding not finished → resume. Deliberately deferred to near launch | Launch prep |

Also check once built: pushing `maintenance` routes from the Home branch ("Add" / "Edit" in Around-the-house) — works in router tests, unconfirmed in the real nested shell.

## Backend

Applied to the live project on 2026-10-19 (files in `supabase/migrations/`, tests in `supabase/tests/data_gaps_test.sql`):

- 2026-10-20: `completion_photos.kind` ('before'/'after', CHECK-enforced; test in `supabase/tests/completion_photo_kind_test.sql`).
- New columns: `maintenance_tasks` (estimated_cost, notes, recurrence_interval_years, notifications_off_at/_reason, tags), `task_completions` (findings, log_to_item_history, due_date), `documents.tags`.
- New table `task_skips`; new RPCs `soft_delete_task`, `restore_task`, `soft_delete_document`, `restore_document`, `search_documents`.
- Found and fixed: a plain `UPDATE ... SET deleted_at` is blocked by RLS (42501) for tasks and documents, so deleting them never worked from the client, and Undo-delete matched zero rows. New functions fix both.
- Found and fixed: new public functions get an explicit `anon` grant on Supabase; `REVOKE ... FROM PUBLIC` does not remove it. Always `REVOKE ... FROM PUBLIC, anon`.

Wired into the app the same day (Tasks and Docs): estimate, notes, "every N years", turned-off time/reason, tags, findings, add-to-history, completion due date, skips (logged, shown in history, Undo deletes them), delete + Undo through the RPCs, Premium search through `search_documents`. Every selected column was checked against the live schema.

Still open:

- [ ] "Push it back" is not logged as a skip (the occurrence stays pending, so a skip row would show it twice in history). Say if you want it logged.
- [ ] Tasks saved by the old form kept their note in `description`; the new edit form reads `notes`, so those show an empty Notes box. Consider `UPDATE maintenance_tasks SET notes = description WHERE notes IS NULL AND task_origin = 'custom'` (check first which rows that would touch).
- [ ] `search_documents` has no category parameter: a category-scoped Premium search filters the top 25 on the client, so it can return fewer than 25. Add `p_category_id` when convenient.
- [ ] Skip history shows the exact skipped date; the kit shows month-year.
- [ ] `legacy item_tasks_screen.dart` (Home profile, Sprint 3) was edited minimally to use `soft_delete_task` and the off columns; it still needs its kit rebuild.
- [ ] **Edge Functions** need approval before writing: `process-document-ocr` (1.7a), `generate-maintenance-tasks`, `schedule-next-task` (2.5a). Next-occurrence scheduling is done client-side today.
- [ ] `get_home_health_score` should exclude turned-off reminders (2.6a).
- [ ] **Household members** table (Settings → Household, Sprint 7) — the Log screen's "Who did it" has only Me / A pro / Someone else until it exists.
- [ ] Cost-at-risk, per-completion score delta ("MAINT +3"), per-month completion history: no data source yet.
- [ ] `completed_by` stores 'diy' for "someone else" and 'contractor' for a pro.
- [ ] Reminder for document renewals (`scheduleRenewalReminder`) and the "We'll remind you 30 days before" promise on the add-document form: nothing schedules it.
- [ ] Replace-file on document detail is a stub.
- [ ] Linked item's own warranty link (`linked_warranty_doc_id`) is not repointed when a document is renewed.
- [ ] Document search still shows expiry status for replaced documents (`document_search_repository.dart`).
- [ ] Forwarding address for "Or forward an email" needs an inbound-email backend.
- [ ] Climate zone from ZIP is a state-level stand-in; address lookup needs a real autocomplete provider; trial purchase is mocked (RevenueCat).
- [ ] Existing documents' search vectors pick up tags only when the row next changes.

## Setup / dashboard (not code)

- [ ] Apple + Google sign-in: enable providers in the Supabase dashboard, allow-list `io.supabase.keystona://login-callback/`, register the URL scheme in `ios/Runner/Info.plist` and `AndroidManifest.xml`.
- [ ] Terms and Privacy URLs (`AuthLegalLinks`).
- [ ] Supabase Auth: enable leaked-password protection (advisor warning).
- [ ] `pg_trgm` is installed in `public` (advisor warning); move to `extensions` when convenient.
- [ ] Live edge detection for the document camera: pick a package, add `android.permission.CAMERA`.
- [ ] `supabase/migrations/20260117010953_create_documents.sql` is 0 bytes locally (the schema exists only remotely); local `supabase db reset` cannot rebuild documents.

## Product decisions

Decided 2026-10-20 (applied in code):

- Undo lasts 10 s after a DELETE (`AuroraDurations.undoDelete`) and 5 s for everyday actions (`AuroraDurations.undo`).
- Replaced (renewed) documents do not count toward the 25-document free limit; a renewal is allowed even at the limit.
- Log screen "A pro" pre-fills from the last pro who did the task.
- Before/after photos have a real column: `completion_photos.kind` ('before' / 'after').
- Amber "soon" uses each task's own reminder window (`reminder_days_before`, default 7).
- The old Tasks views the kit does not draw (by system, seasonal, plan, week strip) stay deleted.

Left open on purpose (decide later):

- Tasks tab: should "By date" switch grouping (today a "By date / By area" sheet), and what the kit's search button opens (today a live search field).
- Bring back the 3-stage completion animation (the kit's quick-done sheet replaced it)?
- `ScanBadge` option for "from scan" (unchosen in the kit); Home History Report scope (launch or v2.0); shopping path in or out of launch.
- Free-plan limit is 25 documents; the kit PNGs say 50 (code wins for now).

## Sprint 3 (Home profile) assumptions: revisit if any cause trouble

Chosen 2026-10-20 ("go with the defaults"). Details and the full kit-vs-schema analysis are in `design/SPRINT3_PREFLIGHT.md`.

- **System categories:** the Add System list uses the database's real ten (hvac, plumbing, electrical, roofing, foundation, siding, windows/doors, insulation, garage, other), not the kit's Exterior/Interior/Climate/Safety/Water. Chosen because a database enum value can never be removed. If the kit's list is wanted, map it or add enum values.
- **Scan install date:** "Installed" is pre-filled from the label's *manufacture* date, marked "from scan", editable. A manufacture date is not an install date (can be years earlier).
- **Edit mode:** the add form in edit mode has no scan banner and a "More details" section (location, installer, price, warranty, notes) for fields the kit omits; delete uses the confirm dialog with Undo, via `soft_delete_system` / `soft_delete_appliance`.
- **Appliance lifespan:** age counts from `purchase_date`; expected life from `expected_lifespan_min/max` (scan or type default); no date shows "unknown".
- **Lifespan bands:** the kit's 75 / 90 / 100 percent of ONE expected life (override, else the midpoint of min and max), computed in the app from systems and appliances together. The existing `get_system_lifespan_overview` RPC (systems only, different thresholds) is no longer the source; remove it if nothing else uses it.
- **New tables/columns (applied, tested):** `item_service_log` (repairs/services/installed/purchased per item), `systems.specifications` (JSONB), `properties.has_basement`.
- **Home profile:** one cover photo (existing column); garage = type + number of spaces; purchase date = month/year picker; a ZIP change rechecks climate with the stand-in lookup; task counts per item are computed in the app.
- **Photos:** free plan limit of 4 per item, enforced in the app only (no server limit).
- **Home health:** only the maintenance score is shown; records and emergency sub-scores, and the "up N since Sep" trend, wait for Sprint 6 (no source or history table yet).
- **Home History Report card:** hidden until Sprint 9.
- **Item task rows:** long-press menu, no edit/delete icon buttons (kit rule).

## Copy to review

The agents wrote copy where the kit had none. Review in one pass: documents (`docs_copy.dart`, `categories_copy.dart`), tasks (`tasks_copy.dart`, `task_form_copy.dart`, `reminders_copy.dart`), auth (`auth_copy.dart`), onboarding, and error/empty/snackbar strings generally.

## Not verified

Nothing has been run on a simulator or compared against the kit PNGs by a person (no goldens exist). Check especially: tab bar, preview card, sheets, long-press menu blur, date pickers, keyboard behaviour over sheets, camera hand-off, PDF/photo viewers.

## New shared widgets awaiting approval (kit rule: new core widgets need OK)

Dashed-outline painter (three private copies), back link (two copies), section header (several), stepper bar, radio choice card, bordered row group with hairlines, grid backdrop (two copies), password field with Show/Hide + autofill, segmented control, scrolling page frame with width cap (two copies), `AuroraPressable` export from the barrel.
