# Keystona — Build Order (sprint by sprint, commit by commit)

**Oct 5, 2026** · Generated from the Aurora storyboard, which is now arranged the same way: one canvas page per sprint, one row per chunk, screens left → right in build order.
**Chunk numbers** follow `HomeTrack_Sprint_Plan.md` for sprints 0–5. Sprints 6–10 cover what the plan doesn’t: the Home tab (Dashboard Spec), Settings, notifications, the Home History Report and the shopping path.
**Each line below is one commit.** Screens in [brackets] are the storyboard files: PNG in `design/screens/`, source in `design/source/<Name>.dc.html`.

| Sprint | Screens | Commits |
|---|---|---|
| Sprint 0 · Foundation | 17 | 21 |
| Sprint 1 · Docs | 12 | 12 |
| Sprint 2 · Tasks | 13 | 16 |
| Sprint 3 · Home profile | 13 | 11 |
| Sprint 4 · Emergency | 12 | 9 |
| Sprint 5 · Projects | 19 | 14 |
| Sprint 6 · Home tab | 8 | 6 |
| Sprint 7 · Settings & Premium | 9 | 5 |
| Sprint 8 · Notifications | 3 | 3 |
| Sprint 9 · Home History Report | 5 | 5 |
| Sprint 10 · Shopping path | 8 | 5 |
| **Total** | **119** | **107** |

---

## Sprint 0 · Foundation

*Sprint Plan 0.1–0.8.* Repo, Supabase, the Aurora theme and shared widgets, then sign-in and onboarding. Nothing else starts until this is merged.

### 0.1–0.3 Repo, local Supabase, Flutter scaffold

- [ ] `0.1a` chore: monorepo, git flow, Makefile, .env.example
- [ ] `0.1b` chore(db): migrations 001–011 + storage buckets + seed (incl. 1428 Elm Hollow Ln demo home)
- [ ] `0.1c` chore(app): Flutter scaffold, AppConfig, Supabase init — app boots against local Supabase

### 0.4 Aurora theme

- [ ] `0.4a` feat(theme): AppColors / AppText / AppSpacing / AppRadii from Aurora tokens (system font: SF Pro on iOS, Roboto on Android)
- [ ] `0.4b` feat(theme): StatusPill + status color map [ProjectStatus]
- [ ] `0.4c` test(theme): widget gallery screen + golden tests for every token and pill

  Screens: `ProjectStatus` (5.4)

### 0.5 Shared widgets (used everywhere)

- [ ] `0.5a` feat(core): KButton, KTopBar, KTabBar, KSheet, KSwitchRow, KChips, KSnackbar (with Undo)
- [ ] `0.5b` feat(core): ErrorView with retry [ErrorRetry]
- [ ] `0.5c` feat(core): ConfirmDeleteSheet [ConfirmDelete]
- [ ] `0.5d` feat(core): UpgradeSheet for free-plan limits [TierLimit]
- [ ] `0.5e` feat(core): PhotoViewer (pinch, swipe) [PhotoViewer]
- [ ] `0.5f` feat(core): PdfViewer [PdfViewer]

  Screens: `ErrorRetry` (8.1) · `ConfirmDelete` (8.3) · `TierLimit` (8.2) · `PhotoViewer` (8.4) · `PdfViewer` (8.5)

### 0.6 Navigation shell

- [ ] `0.6a` feat(router): GoRouter with every route as a placeholder, 5-tab shell, auth guard

### 0.7 Sign in

- [ ] `0.7a` feat(auth): splash + welcome [OnbSplash, AuthWelcome]
- [ ] `0.7b` feat(auth): create account + check your email [AuthSignUp, AuthCheckEmail]
- [ ] `0.7c` feat(auth): log in + forgot password [AuthLogIn, AuthForgot]
- [ ] `0.7d` feat(auth): Apple / Google buttons, session listener, error snackbars

  Screens: `OnbSplash` (1.0) · `AuthWelcome` (1.1) · `AuthSignUp` (1.2) · `AuthCheckEmail` (1.3) · `AuthLogIn` (1.4) · `AuthForgot` (1.5)

### 0.8 Onboarding

- [ ] `0.8a` feat(onboarding): which sounds like you (owner / shopping branch) [OnbPersona]
- [ ] `0.8b` feat(onboarding): your home + climate from ZIP [OnbProperty, OnbClimate]
- [ ] `0.8c` feat(onboarding): free month (RevenueCat mocked) [OnbTrial]
- [ ] `0.8d` feat(onboarding): do these first + resume where you left off [OnbChecklist]

  Screens: `OnbPersona` (1.6) · `OnbProperty` (1.7) · `OnbClimate` (1.8) · `OnbTrial` (1.9) · `OnbChecklist` (1.10)

---

## Sprint 1 · Docs

*Sprint Plan 1.1–1.7.* The document vault: add, read, find and get warned before things expire.

### 1.1 Docs tab

- [ ] `1.1a` feat(docs): Docs tab with search bar, categories, recent [DocsSearchLed]
- [ ] `1.1b` feat(docs): empty state + skeleton [DocsEmpty]

  Screens: `DocsSearchLed` (3.1) · `DocsEmpty` (3.4)

### 1.2 Add a document

- [ ] `1.2a` feat(docs): add-from sheet [DocAddFrom]
- [ ] `1.2b` feat(docs): camera scan with edge detection [DocCamera]
- [ ] `1.2c` feat(docs): category picker + new document form, upload with progress [DocCategory, AddDocument]

  Screens: `DocAddFrom` (3.8) · `DocCamera` (3.9) · `DocCategory` (3.11) · `AddDocument` (3.6)

### 1.3 Document detail

- [ ] `1.3a` feat(docs): document detail, edit, share, delete with Undo [DocDetail]

  Screens: `DocDetail` (3.7)

### 1.4 Search

- [ ] `1.4a` feat(docs): search with recent + suggestions [Search]
- [ ] `1.4b` feat(docs): results with matched snippet, Premium full-text gate [SearchResults]

  Screens: `Search` (3.2) · `SearchResults` (3.3)

### 1.5 Expiring

- [ ] `1.5a` feat(docs): everything with an expiry date, by urgency [DocsExpiring]

  Screens: `DocsExpiring` (3.12)

### 1.6 Categories

- [ ] `1.6a` feat(docs): your categories — add, rename, delete to Uncategorized [DocCategories]

  Screens: `DocCategories` (3.13)

### 1.7 Reading the document (OCR)

- [ ] `1.7a` feat(edge): process-document-ocr Edge Function
- [ ] `1.7b` feat(docs): reading-your-document state + filled-in fields [DocReading]

  Screens: `DocReading` (3.10)

---

## Sprint 2 · Tasks

*Sprint Plan 2.1–2.6.* Maintenance reminders: see what’s due, do it, log it, skip it, turn it off.

### 2.1 Tasks tab

- [ ] `2.1a` feat(tasks): Tasks tab grouped overdue / this week / later [Tasks]
- [ ] `2.1b` feat(tasks): all tasks, year view [TasksAllYear]
- [ ] `2.1c` feat(tasks): all caught up [TasksCaughtUp]

  Screens: `Tasks` (4.1) · `TasksAllYear` (4.2) · `TasksCaughtUp` (4.3)

### 2.2 Task detail

- [ ] `2.2a` feat(tasks): task detail with how-to, tools, DIY vs pro [TaskDetail]
- [ ] `2.2b` feat(tasks): long-press menu on every task row [TaskMenu]
- [ ] `2.2c` feat(tasks): not now — skip with a reason [TaskSkip]

  Screens: `TaskDetail` (4.4) · `TaskMenu` (4.5) · `TaskSkip` (4.8)

### 2.3 Marking it done

- [ ] `2.3a` feat(tasks): quick mark-done with Undo, next one scheduled [TaskDoneQuick]
- [ ] `2.3b` feat(tasks): log the details — cost, who, photos, receipt [TaskLog]
- [ ] `2.3c` feat(tasks): task history [TaskHistory]

  Screens: `TaskDoneQuick` (4.6) · `TaskLog` (4.7) · `TaskHistory` (4.9)

### 2.4 Your own tasks

- [ ] `2.4a` feat(tasks): add a task form [AddTask]

  Screens: `AddTask` (2.14)

### 2.5 Generated reminders + turning them off

- [ ] `2.5a` feat(edge): generate-maintenance-tasks + schedule-next-task
- [ ] `2.5b` feat(tasks): review your reminders during setup [TaskReview]
- [ ] `2.5c` feat(tasks): around-the-house reminders on/off [HomeReminders]
- [ ] `2.5d` feat(settings): turned-off reminders safety net [SettingsReminders]

  Screens: `TaskReview` (2.30) · `HomeReminders` (2.23) · `SettingsReminders` (6.11)

### 2.6 Home Health score

- [ ] `2.6a` feat(db): get_home_health_score RPC (turned-off reminders excluded)
- [ ] `2.6b` feat(tasks): score widget used on Home

---

## Sprint 3 · Home profile

*Sprint Plan 3.1–3.4.* The house itself: systems, appliances, photos, how long things last.

### 3.1 Home profile

- [ ] `3.1a` feat(home): home profile overview [HomeProfile]
- [ ] `3.1b` feat(home): edit home [HomeEdit]

  Screens: `HomeProfile` (2.15) · `HomeEdit` (2.16)

### 3.2 Systems

- [ ] `3.2a` feat(home): systems list [HomeSystems]
- [ ] `3.2b` feat(home): scan a label → system or appliance [ScanFlow]
- [ ] `3.2c` feat(home): add a system [AddSystem]
- [ ] `3.2d` feat(home): system detail [SystemDetail]
- [ ] `3.2e` feat(home): one system’s tasks, photos, reminders [ItemTasks, ItemPhotos, ItemReminders]

  Screens: `HomeSystems` (2.17) · `ScanFlow` (2.3) · `AddSystem` (2.4) · `SystemDetail` (2.12) · `ItemTasks` (2.19) · `ItemPhotos` (2.20) · `ItemReminders` (2.22)

### 3.3 Appliances

- [ ] `3.3a` feat(home): appliances list + add [HomeAppliances, AddAppliance]
- [ ] `3.3b` feat(home): appliance detail [ApplianceDetail]

  Screens: `HomeAppliances` (2.18) · `AddAppliance` (2.5) · `ApplianceDetail` (2.13)

### 3.4 Lifespan

- [ ] `3.4a` feat(db): get_system_lifespan_overview RPC
- [ ] `3.4b` feat(home): how long things last [HomeLifespan]

  Screens: `HomeLifespan` (2.21)

---

## Sprint 4 · Emergency

*Sprint Plan 4.1–4.5.* Shutoffs, who to call and insurance — and all of it works with no signal.

### 4.1 Emergency hub

- [ ] `4.1a` feat(emergency): hub empty + set up [EmergencyEmpty, EmergencyHub]

  Screens: `EmergencyEmpty` (2.7) · `EmergencyHub` (2.8)

### 4.2 Shutoffs

- [ ] `4.2a` feat(emergency): set up a shutoff form + photos [ShutoffSetup]
- [ ] `4.2b` feat(emergency): water and gas shutoff steps [ShutoffWater, ShutoffGas]
- [ ] `4.2c` feat(emergency): electrical panel + breaker map [ShutoffElectric]
- [ ] `4.2d` feat(emergency): add a local shutoff [ShutoffLocal]

  Screens: `ShutoffSetup` (2.9) · `ShutoffWater` (2.10) · `ShutoffGas` (2.31) · `ShutoffElectric` (2.32) · `ShutoffLocal` (2.11)

### 4.3 Who to call

- [ ] `4.3a` feat(emergency): contacts list, tap to call [EmergencyContacts]
- [ ] `4.3b` feat(emergency): contact detail + add (shared with Projects) [ContactDetail, AddContact]

  Screens: `EmergencyContacts` (2.33) · `ContactDetail` (2.34) · `AddContact` (2.35)

### 4.4 Insurance

- [ ] `4.4a` feat(emergency): insurance list + add a policy [InsuranceList, AddInsurance]

  Screens: `InsuranceList` (2.36) · `AddInsurance` (2.37)

### 4.5 Works offline

- [ ] `4.5a` feat(emergency): SQLite cache + emergency-hub-sync, photos cached, last-synced stamp

---

## Sprint 5 · Projects

*Sprint Plan 5.1–5.8.* Projects with phases, budget, photos, contractors, notes and documents.

### 5.1 Projects tab

- [ ] `5.1a` feat(projects): Projects tab + empty showcase [ProjectsMany, ProjectsEmpty]

  Screens: `ProjectsMany` (5.1) · `ProjectsEmpty` (5.3)

### 5.2 New, detail, finished

- [ ] `5.2a` feat(projects): new project [NewProject]
- [ ] `5.2b` feat(projects): project detail [ProjectDetail]
- [ ] `5.2c` feat(projects): finished project [ProjectDone]

  Screens: `NewProject` (5.21) · `ProjectDetail` (5.2) · `ProjectDone` (5.22)

### 5.3 Phases

- [ ] `5.3a` feat(projects): manage + edit phases [PhasesEditor, PhaseEdit]

  Screens: `PhasesEditor` (5.5) · `PhaseEdit` (5.6)

### 5.4 Budget

- [ ] `5.4a` feat(projects): budget overview → category [BudgetTimeline]
- [ ] `5.4b` feat(projects): budget at scale — over time, by trip / by item [BudgetScale]
- [ ] `5.4c` feat(projects): add an expense [AddExpense]

  Screens: `BudgetTimeline` (5.9) · `BudgetScale` (5.10) · `AddExpense` (5.16)

### 5.5 Contractors

- [ ] `5.5a` feat(projects): contractors from the shared contact pool [ProjectContractors, ContractorDetail]

  Screens: `ProjectContractors` (5.17) · `ContractorDetail` (5.18)

### 5.6 Before & after photos

- [ ] `5.6a` feat(projects): photos grid / pairs / timeline [ProjectPhotos]
- [ ] `5.6b` feat(projects): before & after slider [PhotoCompare]
- [ ] `5.6c` feat(projects): make a pair — pick, then line up [PairMaker, PairAlign]

  Screens: `ProjectPhotos` (5.11) · `PhotoCompare` (5.12) · `PairMaker` (5.13) · `PairAlign` (5.14)

### 5.7 Notes

- [ ] `5.7a` feat(projects): notes / journal [ProjectNotes]

  Screens: `ProjectNotes` (5.19)

### 5.8 Documents on a project

- [ ] `5.8a` feat(projects): documents on this project + link from Docs [ProjectDocs, LinkDocs]

  Screens: `ProjectDocs` (5.20) · `LinkDocs` (5.23)

---

## Sprint 6 · Home tab

*Dashboard Spec + Dashboard States.* Home pulls from everything above, so it’s built last. Each state is a commit with a fixture and a golden test.

### 6.1 Main + setup states

- [ ] `6.1a` feat(home-tab): day one [HomeEmptyPlain]
- [ ] `6.1b` feat(home-tab): partway through setup + not much yet [HomeMidSetup, HomeSparse]
- [ ] `6.1c` feat(home-tab): main — healthy (Option H) [Tabbed]

  Screens: `HomeEmptyPlain` (2.1) · `HomeMidSetup` (2.24) · `HomeSparse` (2.25) · `Tabbed` (2.2)

### 6.2 Problem states

- [ ] `6.2a` feat(home-tab): needs attention + at risk [HomeNeedsAttention, HomeAtRisk]
- [ ] `6.2b` feat(home-tab): welcome back [HomeReturning]
- [ ] `6.2c` feat(home-tab): offline (mark done still works) [HomeOffline]

  Screens: `HomeNeedsAttention` (2.26) · `HomeAtRisk` (2.27) · `HomeReturning` (2.28) · `HomeOffline` (2.29)

---

## Sprint 7 · Settings & Premium

*Sprint Plan 6.1–6.2.* Settings, the plan and RevenueCat, household, export and delete.

### 7.1 Settings

- [ ] `7.1a` feat(settings): hub, profile, help [SettingsHub, SettingsProfile, SettingsHelp]

  Screens: `SettingsHub` (6.1) · `SettingsProfile` (6.2) · `SettingsHelp` (6.10)

### 7.2 Plan & Premium

- [ ] `7.2a` feat(subscription): RevenueCat, paywall, restore, trial [SettingsPlan, SettingsPremium]
- [ ] `7.2b` feat(subscription): feature gates wired to UpgradeSheet

  Screens: `SettingsPlan` (6.4) · `SettingsPremium` (6.5)

### 7.3 Household

- [ ] `7.3a` feat(settings): household + invite [SettingsHousehold, SettingsInvite]

  Screens: `SettingsHousehold` (6.6) · `SettingsInvite` (6.7)

### 7.4 Your data

- [ ] `7.4a` feat(settings): export your record + delete account [SettingsExport, SettingsDelete]

  Screens: `SettingsExport` (6.8) · `SettingsDelete` (6.9)

---

## Sprint 8 · Notifications

*Sprint Plan 7.1–7.2.* Push, the inbox, and the settings that control them.

### 8.1 Notifications

- [ ] `8.1a` feat(notifications): FCM + push tokens + preferences [SettingsNotifications]
- [ ] `8.1b` feat(edge): check-expirations + check-overdue-tasks crons
- [ ] `8.1c` feat(notifications): inbox + empty [Notifications, NotificationsEmpty]

  Screens: `SettingsNotifications` (6.3) · `Notifications` (2.38) · `NotificationsEmpty` (2.39)

---

## Sprint 9 · Home History Report

*Premium · launch or v2.0? (open decision).* The “CarFax” report. Needs a call: does it ship at launch (paywall lists it) or in v2.0 (SRS)?

### 9.1 Build and share the report

- [ ] `9.1a` feat(report): builder + purpose presets [ReportBuilder]
- [ ] `9.1b` feat(report): pick projects [ReportProjects]
- [ ] `9.1c` feat(edge): render report (PDF + live link, verify ID)
- [ ] `9.1d` feat(report): preview + share link / PDF / QR [ReportPreview, ReportShare]
- [ ] `9.1e` feat(projects): share one project [ProjectShare]

  Screens: `ReportBuilder` (6.12) · `ReportProjects` (6.15) · `ReportPreview` (6.13) · `ReportShare` (6.14) · `ProjectShare` (5.24)

---

## Sprint 10 · Shopping path

*Buyer branch · Migration 011.* Saving homes you’re looking at, then turning one into your home. Can move earlier if buyers are a launch audience.

### 10.1 Homes you’re looking at

- [ ] `10.1a` feat(shopping): add a home + homes list [ShopAdd, ShopHomes]
- [ ] `10.1b` feat(shopping): a home, inspected + findings [ShopHomeDetail, ShopInspection]
- [ ] `10.1c` feat(shopping): repair request to the agent [ShopRequest]

  Screens: `ShopAdd` (7.1) · `ShopHomes` (7.2) · `ShopHomeDetail` (7.3) · `ShopInspection` (7.4) · `ShopRequest` (7.5)

### 10.2 Touring, comparing, buying

- [ ] `10.2a` feat(shopping): tour checklist + compare [ShopTour, ShopCompare]
- [ ] `10.2b` feat(shopping): we bought it → convert to my home [ShopBought]

  Screens: `ShopTour` (7.6) · `ShopCompare` (7.7) · `ShopBought` (7.8)

---

## Not in the storyboard (no screens)

- Sprint Plan 8.1–8.4 polish, performance, accessibility · 9.1–9.5 analytics, Sentry, production, store submission, final QA. Keep these as written in the Sprint Plan.
