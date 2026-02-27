# HomeTrack Sprint Plan & Backlog
## Feature-Based Development Roadmap — MVP

**Version 1.0 | February 2026**
**Status:** Active — Work through phases in order, at your own pace

---

## Table of Contents

1. [Plan Overview](#1-plan-overview)
2. [Phase 0: Foundation](#2-phase-0-foundation)
3. [Phase 1: Document Vault](#3-phase-1-document-vault)
4. [Phase 2: Maintenance Calendar](#4-phase-2-maintenance-calendar)
5. [Phase 3: Home Profile](#5-phase-3-home-profile)
6. [Phase 4: Emergency Hub](#6-phase-4-emergency-hub)
7. [Phase 5: Projects](#7-phase-5-projects)
8. [Phase 6: Subscription & Payments](#8-phase-6-subscription--payments)
9. [Phase 7: Notifications](#9-phase-7-notifications)
10. [Phase 8: Polish & Integration](#10-phase-8-polish--integration)
11. [Phase 9: Launch Prep](#11-phase-9-launch-prep)
12. [Dependency Map](#12-dependency-map)
13. [Agent Assignment Guide](#13-agent-assignment-guide)

---

## 1. Plan Overview

### Philosophy

This is a **feature-based backlog**, not a time-based calendar. Each phase contains chunks of work with clear acceptance criteria. You work through them in order, at whatever pace fits your schedule. Some chunks can be parallelized across agents; the plan calls out when.

### Launch Goal

**Ship complete** — all 5 feature pillars fully polished, straight to App Store. No soft launch, no partial feature set. When it ships, it's the real thing.

### Build Order

```
Phase 0: Foundation          ← You build this (required before agents start)
    │
    ├── Phase 1: Document Vault       ← Agent A (highest priority)
    ├── Phase 2: Maintenance Calendar  ← Agent B (parallel with 1)
    │
    ├── Phase 3: Home Profile          ← Agent C (parallel with 1 & 2)
    ├── Phase 4: Emergency Hub         ← Agent D (parallel with 1, 2 & 3)
    │
    └── Phase 5: Projects              ← Agent E (after Phase 3 — shares contractors)
    │
Phase 6: Subscription & Payments  ← After features are built
Phase 7: Notifications            ← After features are built
Phase 8: Polish & Integration     ← Tie everything together
Phase 9: Launch Prep              ← App Store submission
```

### How to Read Each Chunk

Every work chunk follows this format:

```
### X.Y Chunk Name
**Assignee:** You | Agent | Either
**Depends on:** What must be done first
**Agent branch:** feature/branch-name

**What to build:**
- Specific deliverables

**Acceptance criteria (done when):**
- [ ] Testable conditions that prove this chunk is complete

**Key references:**
- Which docs to consult
```

---

## 2. Phase 0: Foundation

**You build this before any agent starts.** This is the shared scaffolding that every feature depends on.

---

### 0.1 Repository & Environment Setup

**Assignee:** You
**Depends on:** Nothing

**What to build:**
- Initialize monorepo with directory structure per Environment Setup Guide
- Configure Git Flow (`main`, `develop`, feature branch prefixes)
- Create root `Makefile`, `.gitignore`, `.env.example`
- Link Supabase project to CLI

**Done when:**
- [ ] `git flow init` completed
- [ ] Directory structure matches Environment Setup Guide Section 2.2
- [ ] `.gitignore` covers all platforms
- [ ] `supabase link` succeeds

**Key references:** Environment Setup Guide, Sections 2–3

---

### 0.2 Local Supabase & Database

**Assignee:** You
**Depends on:** 0.1

**What to build:**
- Run all 11 migrations (001–011)
- Create storage buckets with policies
- Verify seed data loaded (categories, document types, task templates, phase templates)
- Create test user in Supabase Auth

**Done when:**
- [ ] `supabase db reset` runs cleanly with no errors
- [ ] 27 tables visible in Studio
- [ ] 6 storage buckets created with policies
- [ ] Seed data present: 6 categories, 40+ doc types, 25+ task templates, 34+ phase templates
- [ ] Test user created and profile auto-created via trigger

**Key references:** Database Schema (all migrations), Environment Setup Guide Section 3

---

### 0.3 Flutter Project Scaffold

**Assignee:** You
**Depends on:** 0.1

**What to build:**
- Create Flutter project with all dependencies from Environment Setup Guide
- Set up environment config (`AppConfig`, `.env`, `--dart-define-from-file`)
- Initialize Supabase in `main.dart`
- Verify app launches on simulator/emulator and connects to local Supabase

**Done when:**
- [ ] `flutter run --dart-define-from-file=.env` launches app
- [ ] App displays "HomeTrack - Setup Complete" on screen
- [ ] No analyzer warnings (`flutter analyze` clean)

**Key references:** Environment Setup Guide, Section 4

---

### 0.4 Keystona Design System Implementation

**Assignee:** You or Agent
**Depends on:** 0.3

**What to build:**
- `app_colors.dart` — Deep Navy `#1A2B4A`, Gold Accent `#C9A84C`, Warm Off-White `#FAF8F5`, all status colors, grays
- `app_text_styles.dart` — Outfit for headlines, Plus Jakarta Sans for body, all size/weight variants
- `app_theme.dart` — Complete `ThemeData` with Material 3, color scheme, text theme, button themes, card themes, input decoration
- `app_sizes.dart` — 4px base spacing grid, standard paddings, border radii

**Done when:**
- [ ] Theme applied to app — correct fonts and colors visible
- [ ] Dark mode not required for MVP but theme structure supports adding it later
- [ ] All Keystona colors accessible via `AppColors.deepNavy` etc.
- [ ] Typography scale matches design system (H1 through body/caption)

**Key references:** SRS Section 8 (Design System), Homeowner Guide (brand reference)

---

### 0.5 Core Widgets & Utilities

**Assignee:** You or Agent
**Depends on:** 0.4

**What to build:**

**Shared widgets** (`lib/core/widgets/`):
- `AppScaffold` — standard screen wrapper with app bar, safe area, optional FAB
- `LoadingSkeletonCard` — generic card skeleton with pulse animation
- `ErrorView` — full-screen error with icon, message, retry button
- `EmptyState` — configurable empty state (motivational and instructional variants)
- `StatusBadge` — colored pill for status labels (active, expired, overdue, etc.)
- `SnackbarService` — global snackbar with error/success/warning variants per Error Handling Guide
- `ConfirmDialog` — "Are you sure?" bottom sheet for destructive actions
- `UpgradeSheet` — premium upgrade bottom sheet per Error Handling Guide Section 10
- `OfflineBanner` — amber connection-lost banner per Error Handling Guide Section 5
- `PhotoPicker` — unified camera/gallery picker with compression

**Services** (`lib/services/`):
- `SupabaseService` — singleton client accessor
- `AuthService` — sign in, sign up, sign out, session listener, password reset
- `StorageService` — upload file, get signed URL, delete file (wraps Supabase Storage)
- `ConnectivityService` — connection state stream

**Utilities** (`lib/core/utils/`):
- `DateUtils` — relative dates ("3 days ago"), formatters, duration helpers
- `CurrencyFormatter` — USD formatting
- `Validators` — email, phone, required, max length (per Error Handling Guide Section 6)

**Done when:**
- [ ] All shared widgets render correctly in a test screen
- [ ] `AuthService` can sign up, sign in, sign out against local Supabase
- [ ] `StorageService` can upload and retrieve a test file
- [ ] `ConnectivityService` detects airplane mode toggle
- [ ] Snackbar shows error/success/warning variants correctly

**Key references:** Error Handling Guide (all patterns), Environment Setup Guide Section 10 (foundation layer)

---

### 0.6 Navigation Shell & Routing

**Assignee:** You or Agent
**Depends on:** 0.5

**What to build:**
- GoRouter configuration with all routes defined (even if screens are placeholder)
- Bottom navigation bar with 5 permanent tabs: Home · Docs · Tasks · Projects · Settings
  - All tabs always visible — Projects shows empty state (Showcase pattern) when no projects exist
  - Emergency Hub accessed via quick-action button on Home tab, not a dedicated tab
- Auth guard — redirect to login if not authenticated
- Deep link handling structure

**Route structure:**
```
/                          → redirect to /dashboard
/login                     → Login screen
/signup                    → Sign up screen
/forgot-password           → Password reset
/onboarding                → Onboarding flow
/onboarding/property       → Property setup
/onboarding/trial          → Trial offer

/dashboard                 → Home tab (dashboard) — see Dashboard Spec

/documents                 → Document Vault list
/documents/:id             → Document detail
/documents/upload          → Upload flow
/documents/search          → Search
/documents/expiring        → Expiration dashboard

/maintenance               → Maintenance task list
/maintenance/:id           → Task detail
/maintenance/complete/:id  → Complete task flow

/home                      → Home Profile overview
/home/systems              → Systems list
/home/systems/:id          → System detail
/home/systems/add          → Add system
/home/appliances           → Appliances list
/home/appliances/:id       → Appliance detail
/home/appliances/add       → Add appliance

/emergency                 → Emergency Hub (accessed from Home tab quick-action, not a tab)
/emergency/shutoffs/:type  → Shutoff detail (water/gas/electrical)
/emergency/contacts        → Emergency contacts
/emergency/contacts/add    → Add contact
/emergency/insurance       → Insurance info

/projects                  → Projects list
/projects/:id              → Project detail
/projects/create           → Create project
/projects/:id/budget       → Budget detail
/projects/:id/photos       → Photo gallery / before-after
/projects/:id/notes        → Journal

/settings                  → Settings hub
/settings/profile          → Edit profile
/settings/notifications    → Notification preferences
/settings/subscription     → Subscription management
/settings/household        → Household members
/settings/export           → Data export (CCPA)
/settings/delete-account   → Account deletion
```

**Done when:**
- [ ] Bottom nav shows 5 permanent tabs: Home · Docs · Tasks · Projects · Settings
- [ ] Home tab is the default landing screen on app open
- [ ] Projects tab shows Showcase empty state when no projects exist (see Empty States Catalog §2.4)
- [ ] GoRouter guards redirect unauthenticated users to `/login`
- [ ] All routes defined (screens can be `Scaffold(body: Center(child: Text('TODO: Screen Name')))`)
- [ ] Tab state preserved when switching tabs

**Key references:** API Contract (feature organization), SRS (feature list)

---

### 0.7 Authentication Flow

**Assignee:** Agent
**Depends on:** 0.5, 0.6
**Agent branch:** `feature/auth`

**What to build:**
- Login screen (email/password, Google OAuth button, Apple Sign-In button, magic link option)
- Sign up screen (name, email, password, confirm password)
- Forgot password screen (email input, sends reset link)
- Auth state listener (auto-navigate on sign in/out, handle token refresh)
- Riverpod auth provider wrapping `AuthService`

**Done when:**
- [ ] New user can sign up with email/password → profile auto-created → navigated to onboarding
- [ ] Existing user can sign in → navigated to home
- [ ] Forgot password sends email (visible in Inbucket locally)
- [ ] Sign out returns to login screen
- [ ] Killing and relaunching app preserves auth state (doesn't require re-login)
- [ ] Invalid credentials show snackbar error per Error Handling Guide
- [ ] OAuth buttons present (can be non-functional until provider setup)

**Key references:** API Contract Section 2, Error Handling Guide Section 8.3

---

### 0.8 Onboarding Flow

**Assignee:** Agent
**Depends on:** 0.7
**Agent branch:** `feature/onboarding`

**What to build:**
- Welcome screen (value prop, "Get Started" button)
- Property setup screen (address, property type, year built, bedrooms/bathrooms, purchase date/price)
- Climate zone auto-detection (call Edge Function from ZIP code)
- First steps prompt (suggest which feature to set up first)
- Trial offer screen (30-day Premium trial, card upfront via RevenueCat — can be mocked for now)
- Onboarding progress tracking (`profiles.onboarding_step`)
- Skip option at every step

**Done when:**
- [ ] New user lands on welcome → property setup → first steps → trial offer → home screen
- [ ] Property saved to database with all fields
- [ ] Climate zone detected from ZIP code (or manual fallback)
- [ ] `profiles.onboarding_completed` set to `true` on completion
- [ ] User can skip any step and come back later
- [ ] Killing app mid-onboarding resumes from last completed step

**Key references:** API Contract Sections 4–5, Error Handling Guide Section 14.5

---

## 3. Phase 1: Document Vault

**Priority:** #1 — The core value driver. Build first.

---

### 1.1 Document List Screen

**Assignee:** Agent
**Depends on:** Phase 0 complete
**Agent branch:** `feature/document-vault`

**What to build:**
- Document list with cards showing: thumbnail/icon, name, category badge, date
- Category filter chips (horizontally scrollable)
- Sort options (date added, name, category)
- Pull-to-refresh
- Skeleton loading state (document card shaped)
- Empty state (motivational: "Your Document Vault is ready!")
- FAB to add new document

**Done when:**
- [ ] List loads documents from Supabase and displays in cards
- [ ] Category filter chips filter the list
- [ ] Skeleton shows while loading
- [ ] Empty state shows when no documents exist
- [ ] Pull-to-refresh works
- [ ] Tapping a card navigates to document detail

**Key references:** API Contract Section 6.1, Error Handling Guide Sections 3–4

---

### 1.2 Document Upload Flow

**Assignee:** Agent
**Depends on:** 1.1
**Agent branch:** `feature/document-vault`

**What to build:**
- Upload source picker (camera scan, photo library, file picker)
- Category selection screen (system categories + custom)
- Document type selection (filtered by category)
- Metadata form (name, expiration date, notes, optional fields per type)
- File upload with progress bar to Supabase Storage
- Free tier limit check (25 documents) — show upgrade sheet if exceeded
- Post-upload: navigate to document detail

**Done when:**
- [ ] User can upload a PDF from file picker → appears in document list
- [ ] User can take a photo with camera → saves as document
- [ ] Category and type selection works
- [ ] Progress bar shows real upload percentage
- [ ] File saved to `documents` storage bucket at correct path
- [ ] Database record created with all metadata
- [ ] 26th document blocked for free tier with upgrade sheet
- [ ] HEIC converted to JPEG before upload
- [ ] Duplicate detection prompt shown for same name + size

**Key references:** API Contract Section 6.4, Error Handling Guide Sections 10–11

---

### 1.3 Document Detail & Preview

**Assignee:** Agent
**Depends on:** 1.1
**Agent branch:** `feature/document-vault`

**What to build:**
- Document preview (PDF viewer, image viewer with pinch-to-zoom)
- Document info: name, category, type, upload date, expiration date, file size, notes
- Edit document metadata (name, category, expiration, notes)
- Delete document (soft delete with undo snackbar)
- Download / share document
- Expiration status badge (Active/Expiring Soon/Expired)
- Linked system/appliance display (if any)

**Done when:**
- [ ] PDF documents render in-app with zoom
- [ ] Image documents display with pinch-to-zoom
- [ ] All metadata fields display correctly
- [ ] User can edit name, category, expiration, notes
- [ ] Delete shows undo snackbar (5 seconds), then soft deletes
- [ ] Share/download generates signed URL and opens share sheet
- [ ] Expiration badge color-coded: green (>90 days), amber (30-90), red (<30 or expired)

**Key references:** API Contract Sections 6.2, 6.5–6.7

---

### 1.4 Document Search

**Assignee:** Agent
**Depends on:** 1.1
**Agent branch:** `feature/document-vault`

**What to build:**
- Search bar at top of document list
- Free tier: name and category search (ilike)
- Premium tier: full-text OCR search (tsvector)
- Search results with matching snippet highlighted
- Premium badge on search bar for free users (tapping shows upgrade sheet)
- "No results" empty state

**Done when:**
- [ ] Typing in search bar filters document list in real time (debounced 300ms)
- [ ] Free users search by name/category only
- [ ] Premium users get OCR full-text results with snippets
- [ ] Free users tapping OCR search see gentle upgrade prompt
- [ ] Empty search results show instructional empty state
- [ ] Search returns results in under 2 seconds

**Key references:** API Contract Section 6.3, Error Handling Guide Section 10

---

### 1.5 Expiration Dashboard

**Assignee:** Agent
**Depends on:** 1.1, 1.3
**Agent branch:** `feature/document-vault`

**What to build:**
- Dashboard showing documents with expiration dates sorted by urgency
- Three sections: Expired, Expiring Soon (< 30 days), Upcoming (30–90 days)
- Color-coded status indicators per section
- Tapping a document goes to its detail screen
- Empty state when no expiring documents

**Done when:**
- [ ] Dashboard shows all documents with expiration dates
- [ ] Sorted by urgency (expired first, then soonest expiring)
- [ ] Correct color coding per section
- [ ] Navigates to document detail on tap
- [ ] Empty state when no documents have expiration dates

**Key references:** API Contract Section 6.8

---

### 1.6 Custom Categories

**Assignee:** Agent
**Depends on:** 1.1
**Agent branch:** `feature/document-vault`

**What to build:**
- Category management screen (accessible from document list or settings)
- List of system categories (not editable) + user custom categories
- Create custom category (name, icon picker, color picker)
- Edit custom category
- Delete custom category (moves documents to Uncategorized)

**Done when:**
- [ ] User can create a custom category with name, icon, and color
- [ ] Custom categories appear alongside system categories in upload flow
- [ ] User can edit or delete custom categories
- [ ] Deleting a category moves its documents to "Uncategorized" — no orphans

**Key references:** API Contract Sections 6.9–6.11, Error Handling Guide Section 14.1

---

### 1.7 OCR Processing (Edge Function)

**Assignee:** Agent (backend-focused)
**Depends on:** 1.2, Google Cloud Vision account set up
**Agent branch:** `feature/document-ocr`

**What to build:**
- Edge Function: `process-document-ocr`
- Triggers on document upload (database webhook or called after insert)
- Downloads file from Storage → sends to Google Cloud Vision API → stores OCR text
- Auto-detects category from OCR keywords
- Extracts expiration dates from OCR text
- Generates thumbnail (first page of PDF, resized image)
- Updates `ocr_status` through pipeline: `pending` → `processing` → `complete` / `failed`

**Done when:**
- [ ] Uploading a PDF triggers OCR processing automatically
- [ ] OCR text stored in `documents.ocr_text`
- [ ] Thumbnail generated and path stored in `documents.thumbnail_path`
- [ ] Expiration dates auto-detected from common patterns
- [ ] Category suggestion generated (logged, optionally shown to user)
- [ ] `ocr_status` updates correctly through each stage
- [ ] OCR failure doesn't break the document — it's still usable without search

**Key references:** API Contract Section 14.2, Error Handling Guide Section 14.1

---

## 4. Phase 2: Maintenance Calendar

**Priority:** #2 — Can be built in parallel with Document Vault.

---

### 2.1 Maintenance Task List

**Assignee:** Agent
**Depends on:** Phase 0 complete
**Agent branch:** `feature/maintenance-calendar`

**What to build:**
- Task list grouped by status: Overdue (red), Due This Week, Upcoming
- Task cards showing: name, category icon, due date, status badge, linked system/appliance
- Filter by: status, category, linked system
- Sort by: due date (default), priority, category
- Pull-to-refresh
- Skeleton loading state
- Empty state (motivational: "Stay ahead of home repairs")
- Home Health Score badge at top

**Done when:**
- [ ] Tasks load from Supabase grouped by status
- [ ] Overdue tasks visually prominent (red indicators)
- [ ] Filters and sorts work correctly
- [ ] Skeleton shows while loading
- [ ] Empty state displays when no tasks exist
- [ ] Home Health Score displays at top (can be placeholder calculation initially)

**Key references:** API Contract Section 9.1, Error Handling Guide Sections 3–4

---

### 2.2 Task Detail Screen

**Assignee:** Agent
**Depends on:** 2.1
**Agent branch:** `feature/maintenance-calendar`

**What to build:**
- Task info: name, description, category, status, due date, priority
- Instructions from template (if template-based task)
- Tools needed, supplies needed, estimated time
- DIY vs professional recommendation
- Difficulty badge
- Linked system/appliance with navigation
- Completion history (past completions with dates, costs, notes)
- Quick complete button (one-tap, auto-timestamp)
- Detailed complete button (opens completion form)
- Skip button with reason

**Done when:**
- [ ] All task fields display correctly
- [ ] Template instructions show for system-generated tasks
- [ ] Quick complete creates completion record with today's date
- [ ] Skip updates task status and prompts for reason
- [ ] Completion history shows past completions
- [ ] Linked system/appliance tappable to navigate

**Key references:** API Contract Sections 9.2, 9.4–9.6

---

### 2.3 Task Completion Flow

**Assignee:** Agent
**Depends on:** 2.2
**Agent branch:** `feature/maintenance-calendar`

**What to build:**
- Detailed completion form: date, completed by (DIY/contractor), contractor info, costs, time spent, notes
- Photo upload for completion evidence
- Receipt linking (pick from Document Vault)
- After completion: update task status, schedule next occurrence if recurring
- Undo within 5 seconds (snackbar)

**Done when:**
- [ ] Quick complete: one tap → task marked done → snackbar with UNDO
- [ ] Detailed complete: form saves all fields including costs and contractor info
- [ ] Completion photos upload to `completion-photos` bucket
- [ ] Recurring tasks auto-schedule next occurrence after completion
- [ ] Undo works within 5-second snackbar window

**Key references:** API Contract Sections 9.4–9.5, Error Handling Guide Section 14.2

---

### 2.4 Create Custom Task

**Assignee:** Agent
**Depends on:** 2.1
**Agent branch:** `feature/maintenance-calendar`

**What to build:**
- Create task form: name, description, category, due date, recurrence, priority, difficulty
- DIY or professional selection
- Optional: link to system/appliance
- Optional: estimated time, tools needed, supplies needed
- Recurrence options: none, weekly, biweekly, monthly, quarterly, biannual, annual

**Done when:**
- [ ] User can create a custom task with all fields
- [ ] Task appears in task list at correct position by due date
- [ ] Recurrence generates next occurrence after completion
- [ ] Linked system/appliance relationship saved

**Key references:** API Contract Section 9.3

---

### 2.5 Task Generation from Templates

**Assignee:** Agent (backend-focused)
**Depends on:** 2.1, Phase 0.8 (onboarding — need property with climate zone)
**Agent branch:** `feature/maintenance-calendar`

**What to build:**
- Edge Function: `generate-maintenance-tasks`
- Takes property_id, climate_zone, and system categories
- Filters templates by climate zone compatibility
- Creates tasks with correct due dates based on season
- Assigns tasks to linked systems when applicable
- Edge Function: `schedule-next-task` — schedules recurring task after completion/skip

**Done when:**
- [ ] After property + systems are set up, calling the function generates 15-25 relevant tasks
- [ ] Tasks are climate-zone appropriate (no "winterize sprinklers" in zone 1)
- [ ] Tasks have correct seasonal due dates
- [ ] Completing a recurring task triggers `schedule-next-task` and creates next occurrence

**Key references:** API Contract Sections 9.7–9.8, Database Schema Migration 006 + 010

---

### 2.6 Home Health Score

**Assignee:** Agent
**Depends on:** 2.1, 2.3
**Agent branch:** `feature/maintenance-calendar`

**What to build:**
- RPC function: `get_home_health_score`
- Score calculation (0–100) based on: tasks completed on time vs overdue/skipped
- Display widget: circular gauge with score, trend arrow, task stats
- Trend calculation: improving/stable/declining (compare last 30 days vs prior 30)

**Done when:**
- [ ] Score calculates correctly from task completion data
- [ ] Gauge widget displays score with color (green >70, amber 40-70, red <40)
- [ ] Trend arrow shows correctly
- [ ] Stats show: total tasks, completed, overdue, upcoming

**Key references:** API Contract Section 9.9

---

## 5. Phase 3: Home Profile

**Priority:** #3 — Can be built in parallel with Phases 1 & 2.

---

### 3.1 Home Profile Overview

**Assignee:** Agent
**Depends on:** Phase 0 complete
**Agent branch:** `feature/home-profile`

**What to build:**
- Property summary card (address, type, year built, sq ft, photo)
- Systems section with count and quick status
- Appliances section with count and quick status
- Lifespan overview (systems nearing end of life highlighted)
- Navigation to systems list, appliances list, property edit

**Done when:**
- [ ] Property info displays from database
- [ ] Systems and appliances counts show correctly
- [ ] "X items nearing end of life" warning shows when applicable
- [ ] Navigation to sub-screens works

**Key references:** API Contract Sections 5, 7, 8

---

### 3.2 Systems CRUD

**Assignee:** Agent
**Depends on:** 3.1
**Agent branch:** `feature/home-profile`

**What to build:**
- Systems list grouped by category (HVAC, plumbing, electrical, etc.)
- Add system form: category, type, name, brand, model, serial number, install date, location, lifespan, warranty, replacement cost
- System detail screen with all info + photos + linked maintenance tasks
- Edit system
- Photo upload (model label, overview, condition photos)
- Delete system (soft delete)

**Done when:**
- [ ] User can add a system with all fields
- [ ] Systems list displays grouped by category
- [ ] System detail shows all info, photos, and linked tasks
- [ ] Photos upload to `item-photos` bucket
- [ ] Edit and delete work correctly
- [ ] Skeleton loading on list, empty state when no systems

**Key references:** API Contract Sections 7.1–7.5

---

### 3.3 Appliances CRUD

**Assignee:** Agent
**Depends on:** 3.1
**Agent branch:** `feature/home-profile`

**What to build:**
- Same patterns as Systems (3.2) but for appliances
- Appliance-specific fields: purchase price, retailer, specifications JSON
- Category groups: kitchen, laundry, climate, cleaning, outdoor, bathroom

**Done when:**
- [ ] Full CRUD for appliances matching system patterns
- [ ] Appliance-specific fields (purchase price, retailer, specs) save correctly
- [ ] Photos work same as systems

**Key references:** API Contract Sections 8.1–8.3

---

### 3.4 Lifespan Tracking

**Assignee:** Agent
**Depends on:** 3.2
**Agent branch:** `feature/home-profile`

**What to build:**
- Lifespan overview screen showing all systems sorted by age percentage
- Visual lifespan bar for each system (green → amber → red)
- Health status: healthy, aging, end of life
- Estimated years until replacement
- Replacement cost summary (total upcoming costs)
- RPC: `get_system_lifespan_overview`

**Done when:**
- [ ] Lifespan bars show correct percentage based on installation date vs expected lifespan
- [ ] Color coding correct: green (<75% lifespan), amber (75-100%), red (>100%)
- [ ] Systems without installation date show "Unknown age"
- [ ] Total replacement cost sums correctly
- [ ] RPC returns calculated fields correctly

**Key references:** API Contract Section 7.6

---

## 6. Phase 4: Emergency Hub

**Priority:** #4 — Can be built in parallel with other phases.

---

### 4.1 Emergency Hub Main Screen

**Assignee:** Agent
**Depends on:** Phase 0 complete
**Agent branch:** `feature/emergency-hub`

**What to build:**
- Three utility shutoff cards: Water, Gas, Electrical — each showing completion status
- Emergency contacts section (favorites shown, "See all" link)
- Insurance quick reference section
- "Last synced" timestamp for offline data
- High-contrast, clean layout optimized for stress situations

**Done when:**
- [ ] Three shutoff cards display with completion status (complete/incomplete)
- [ ] Contacts section shows favorites
- [ ] Insurance section shows policy summary
- [ ] Layout is clean and scannable — no clutter

**Key references:** API Contract Sections 10.1, 10.4, 10.6

---

### 4.2 Utility Shutoff Setup

**Assignee:** Agent
**Depends on:** 4.1
**Agent branch:** `feature/emergency-hub`

**What to build:**
- Shutoff detail screen per utility type (water, gas, electrical)
- Fields: location description, valve type, turn direction, tools required, special instructions
- Photo upload (location photo, valve close-up) — compressed to <500KB
- Step-by-step instructions display
- Mark as complete

**Done when:**
- [ ] User can set up all three utility shutoffs with full details
- [ ] Photos upload compressed to `shutoff-photos` bucket
- [ ] Completion status tracked per shutoff type
- [ ] Instructions display clearly

**Key references:** API Contract Sections 10.2–10.3

---

### 4.3 Emergency Contacts

**Assignee:** Agent
**Depends on:** 4.1
**Agent branch:** `feature/emergency-hub`

**What to build:**
- Contact list with category icons, favorites pinned to top
- Add contact form: name, company, category, phone(s), email, availability, 24/7 flag, notes
- Edit and delete contacts
- Tap-to-call (phone primary)
- Favorite toggle
- **Note:** These contacts are the shared contractor pool — also accessible from Projects

**Done when:**
- [ ] User can add, edit, delete emergency contacts
- [ ] Contacts sorted by favorite status then category
- [ ] Tap-to-call launches phone dialer
- [ ] Favorite toggle works
- [ ] Contact appears in both Emergency Hub and Projects contractor picker

**Key references:** API Contract Sections 10.4–10.5, Error Handling Guide Section 14.4

---

### 4.4 Insurance Quick Reference

**Assignee:** Agent
**Depends on:** 4.1
**Agent branch:** `feature/emergency-hub`

**What to build:**
- Insurance list by policy type (homeowners, flood, earthquake, umbrella, home warranty)
- Add/edit insurance: carrier, policy number, coverage, deductible, premium, agent info, claims phone, dates
- Tap-to-call claims phone and agent phone
- Linked document from Document Vault (policy document)

**Done when:**
- [ ] User can add multiple insurance policies
- [ ] All fields display and edit correctly
- [ ] Tap-to-call works for claims and agent phone
- [ ] Document linking works (pick from vault)

**Key references:** API Contract Section 10.6

---

### 4.5 Offline Sync

**Assignee:** Agent (more complex — needs offline expertise)
**Depends on:** 4.1, 4.2, 4.3, 4.4
**Agent branch:** `feature/emergency-offline`

**What to build:**
- SQLite local database for Emergency Hub data
- Sync service: download all shutoffs, contacts, insurance on app open (if connected)
- Download and cache shutoff photos locally
- Edge Function: `emergency-hub-sync` returns bundled payload
- Offline read: when disconnected, serve all Emergency Hub data from SQLite
- Offline edit: queue changes in SQLite, sync when reconnected
- Conflict resolution: server wins, notify user
- "Last synced" timestamp display

**Done when:**
- [ ] Turn on airplane mode → Emergency Hub still shows all data
- [ ] Shutoff photos display offline from local cache
- [ ] Contacts and insurance display offline
- [ ] Making changes offline → queued → synced on reconnect
- [ ] "Last synced" timestamp updates after each successful sync
- [ ] All other tabs show offline banner and disable interactions

**Key references:** API Contract Section 10.7, Error Handling Guide Section 5

---

## 7. Phase 5: Projects

**Priority:** #5 — Build after Home Profile (shares contractor pool).

---

### 5.1 Projects List Screen

**Assignee:** Agent
**Depends on:** Phase 0 complete, Phase 4.3 (shared contacts/contractors)
**Agent branch:** `feature/projects`

**What to build:**
- Project list with cards: name, status badge, budget summary (estimated vs spent), cover photo, date range
- Filter by status (planning, in progress, on hold, completed, cancelled)
- Sort by updated date (default), name, status
- FAB to create new project
- Free tier limit check (2 projects) before creation
- Projects tab is permanent (always visible in bottom nav) — shows Showcase empty state with ghosted example cards when no projects exist. See Empty States Catalog §2.4 and Dashboard Spec §3 for navigation structure.
- Skeleton loading state

**Done when:**
- [ ] Projects list loads and displays correctly
- [ ] Status filters work
- [ ] Projects tab always visible in bottom nav with Showcase empty state when no projects
- [ ] Free tier blocked at 3rd project with upgrade sheet
- [ ] Empty state matches Empty States Catalog §2.4 exactly (ghosted example cards)

**Key references:** API Contract Section 14.1, 14.3

---

### 5.2 Create & Edit Project

**Assignee:** Agent
**Depends on:** 5.1
**Agent branch:** `feature/projects`

**What to build:**
- Create project form: name, description, type (kitchen remodel, bathroom, etc.), estimated budget, planned dates, DIY/contractor/mixed
- After creation: prompt to load phase templates for selected project type
- Edit project: all fields + status changes
- Status transitions: Planning → In Progress → On Hold / Completed / Cancelled

**Done when:**
- [ ] User can create project with all fields
- [ ] Phase template prompt shows for supported project types
- [ ] Status can be changed between valid transitions
- [ ] Edit saves all fields correctly

**Key references:** API Contract Sections 14.3–14.4

---

### 5.3 Project Phases

**Assignee:** Agent
**Depends on:** 5.2
**Agent branch:** `feature/projects`

**What to build:**
- Phase list within project (drag to reorder)
- Create custom phase: name, description, planned dates
- Load phases from templates (batch create)
- Phase status tracking (same statuses as project)
- Delete phase (budget items and notes keep project link, lose phase link)

**Done when:**
- [ ] Phases display in order within project
- [ ] User can create custom phases
- [ ] Template loading creates all phases for project type in one action
- [ ] Phase status updates independently
- [ ] Reordering works (drag and drop or up/down buttons)

**Key references:** API Contract Sections 14.5–14.6, 14.15

---

### 5.4 Budget Tracking

**Assignee:** Agent
**Depends on:** 5.2
**Agent branch:** `feature/projects`

**What to build:**
- Budget overview: estimated total vs actual total, category breakdown chart
- Budget category sections: materials, labor, permits, fixtures, equipment rental, design, other
- Add line item: name, category, estimated cost, actual cost, vendor, paid status, receipt link
- Edit and delete line items
- Auto-calculate project `actual_spent` via RPC
- Over-budget indicator (amber badge when actual > estimated)
- Link receipt from Document Vault

**Done when:**
- [ ] Budget overview shows estimated vs actual with visual comparison
- [ ] Category breakdown displays correctly (could be bar chart or grouped list)
- [ ] Line items CRUD works with all fields
- [ ] Actual spent auto-updates via RPC after line item changes
- [ ] Over-budget badge shows when applicable
- [ ] Receipts can be linked from Document Vault

**Key references:** API Contract Sections 14.7–14.8

---

### 5.5 Project Contractors

**Assignee:** Agent
**Depends on:** 5.2, Phase 4.3 (shared contact pool)
**Agent branch:** `feature/projects`

**What to build:**
- Add contractor to project: pick from shared emergency contacts pool
- Project-specific fields: role, contract amount, amount paid
- Rate contractor after project (1–5 stars, review notes)
- Link contract/invoice documents from vault
- Option to add a new contractor (creates emergency contact + project link)

**Done when:**
- [ ] User can add existing contacts as project contractors
- [ ] Project-specific contract amount and role save correctly
- [ ] Rating and review work after project completion
- [ ] New contractor creation adds to shared pool AND project
- [ ] Documents linkable to contractor record

**Key references:** API Contract Sections 14.9–14.10

---

### 5.6 Before/After Photos

**Assignee:** Agent
**Depends on:** 5.2
**Agent branch:** `feature/projects`

**What to build:**
- Photo gallery within project: before, after, progress, inspiration, issue types
- Before/after pairing: user selects a "before" photo and matches with an "after" photo → creates pair_id
- Side-by-side comparison viewer with swipe slider
- Room/area tagging on photos
- Optional phase assignment
- Upload with type selection

**Done when:**
- [ ] Photos upload to `project-photos` bucket with correct type tags
- [ ] User can pair a before photo with an after photo
- [ ] Slider comparison view works smoothly (drag divider left/right to reveal before vs after)
- [ ] Photos filterable by type and phase
- [ ] Room/area tags display and filter correctly
- [ ] Unpaired "before" photos show prompt to add matching "after"

**Key references:** API Contract Sections 14.11–14.12, Error Handling Guide Section 14.5

---

### 5.7 Project Journal

**Assignee:** Agent
**Depends on:** 5.2
**Agent branch:** `feature/projects`

**What to build:**
- Journal/notes feed within project, sorted by date (newest first)
- Add note: title (optional), content (required), date, optional phase assignment
- Edit and delete notes
- Clean, readable display (like a simple blog feed)

**Done when:**
- [ ] Notes display in date-sorted feed
- [ ] User can add, edit, delete notes
- [ ] Phase assignment optional and works
- [ ] Clean display — content is the focus

**Key references:** API Contract Section 14.13

---

### 5.8 Document Linking

**Assignee:** Agent
**Depends on:** 5.2, Phase 1 (Document Vault must exist)
**Agent branch:** `feature/projects`

**What to build:**
- Link existing documents from Document Vault to project
- Link type selection: receipt, permit, contract, invoice, warranty, general
- View linked documents within project
- Unlink document from project (doesn't delete the document)

**Done when:**
- [ ] User can browse Document Vault and link documents to a project
- [ ] Link type saved and displayed correctly
- [ ] Linked documents viewable within project detail
- [ ] Unlinking removes the link but keeps the document

**Key references:** API Contract Section 14.14

---

## 8. Phase 6: Subscription & Payments

**Build after feature phases.** Features need to exist before gating works.

---

### 6.1 RevenueCat Integration

**Assignee:** Agent
**Depends on:** All feature phases complete, RevenueCat account setup
**Agent branch:** `feature/subscription`

**What to build:**
- RevenueCat SDK initialization in Flutter
- Product configuration: Premium monthly, Premium annual, Family monthly, Family annual
- Purchase flow: paywall screen, product selection, native App Store/Play Store purchase
- Restore purchases
- Trial flow: 30-day free trial with card upfront (per Error Handling Guide Section 10.2)
- Webhook Edge Function: `revenuecat-webhook` — updates `profiles.subscription_tier`
- Subscription status display in Settings

**Done when:**
- [ ] Paywall displays all products with pricing
- [ ] Purchase flow completes (sandbox/test mode)
- [ ] 30-day trial flow works with card upfront
- [ ] Webhook updates subscription tier in database
- [ ] Restore purchases works
- [ ] Subscription status shows correctly in Settings
- [ ] Feature gating enforces limits based on tier

**Key references:** API Contract Section 13, Error Handling Guide Section 10

---

### 6.2 Feature Gating Enforcement

**Assignee:** Agent
**Depends on:** 6.1
**Agent branch:** `feature/subscription`

**What to build:**
- Riverpod provider that exposes current tier and feature access checks
- Gate enforcement at: document upload (25 limit), project creation (2 limit), OCR search, household member invite
- Upgrade bottom sheet per Error Handling Guide
- Premium badge on gated features
- Trial ending flow: banner at day 25, push at day 28/30
- Post-trial graceful handling: 14-day grace period, then archive

**Done when:**
- [ ] Free users blocked at 26th document with upgrade sheet
- [ ] Free users blocked at 3rd project with upgrade sheet
- [ ] OCR search shows premium badge and upgrade prompt for free users
- [ ] Household invite limit enforced per tier
- [ ] Trial countdown banner appears at day 25
- [ ] Post-trial 14-day grace period works → documents archived after day 44

**Key references:** Error Handling Guide Section 10 (entire section)

---

## 9. Phase 7: Notifications

**Build after features exist** — need things to notify about.

---

### 7.1 Push Notification Setup

**Assignee:** Agent
**Depends on:** Firebase account setup, all feature phases
**Agent branch:** `feature/notifications`

**What to build:**
- Firebase Cloud Messaging integration in Flutter
- Push token registration → `push_tokens` table
- Notification preferences screen (enable/disable by type, quiet hours, preferred day/time)
- Edge Function: `send-push-notification` with preference checks

**Done when:**
- [ ] App requests notification permission on first launch
- [ ] Push token saved to database
- [ ] Preferences screen saves all settings
- [ ] Test push notification received on device

**Key references:** API Contract Section 12, Error Handling Guide Section 9

---

### 7.2 Notification Triggers

**Assignee:** Agent (backend-focused)
**Depends on:** 7.1
**Agent branch:** `feature/notifications`

**What to build:**
- Cron Edge Function: `check-expirations` — daily scan for expiring documents (90/30/7 day reminders)
- Cron Edge Function: `check-overdue-tasks` — daily scan for overdue maintenance tasks
- Trial ending reminders (day 25 banner, day 28 push, day 30 push)
- Post-trial grace period reminders (day 37, day 42, day 44)
- Notification log — records all sent notifications
- In-app notification inbox with read/unread status

**Done when:**
- [ ] Expiration reminders fire at 90/30/7 days before document expiration
- [ ] Overdue task notifications fire daily for overdue tasks
- [ ] Trial reminders fire on correct days
- [ ] Notification log records all notifications
- [ ] In-app inbox shows notification history with read/unread
- [ ] Quiet hours respected — no notifications during quiet period

**Key references:** API Contract Sections 12, 14.3 (cron jobs)

---

## 10. Phase 8: Polish & Integration

**After all features are individually complete.** This phase ties everything together.

---

### 8.1 Cross-Feature Integration

**Assignee:** You (integrator)
**Depends on:** All feature phases complete

**What to build:**
- Document ↔ System/Appliance linking (warranty docs linked to the appliance)
- Document ↔ Project linking verified end-to-end
- Maintenance task ↔ System linking verified
- Emergency contacts ↔ Project contractors verified (shared pool)
- Navigation between linked entities works in both directions
- Bottom nav shows 5 permanent tabs consistently across all states

**Done when:**
- [ ] Tapping a linked document from a system → opens document detail
- [ ] Tapping a linked system from a maintenance task → opens system detail
- [ ] Adding a contractor in Emergency Hub → available in Projects
- [ ] All cross-feature navigation flows work smoothly
- [ ] No orphaned data or broken links

---

### 8.2 UI Polish Pass

**Assignee:** Agent(s)
**Depends on:** 8.1

**What to build:**
- Consistent spacing, typography, and colors across all screens
- All skeleton loading states match their respective content layouts
- All empty states present with correct variant (motivational vs instructional)
- All error states follow Error Handling Guide patterns
- Transitions and animations: page transitions, list item animations, hero animations for photos
- Pull-to-refresh on all list screens
- Haptic feedback on key actions (complete task, upload success)

**Done when:**
- [ ] Design system audit: every screen uses AppColors, AppTextStyles, AppSizes correctly
- [ ] No default Flutter widgets visible (everything themed)
- [ ] Smooth 60fps scrolling on all lists
- [ ] Animations feel native to platform (iOS/Android appropriate)

---

### 8.3 Performance Optimization

**Assignee:** Agent
**Depends on:** 8.2

**What to build:**
- Image caching (CachedNetworkImage everywhere)
- Lazy loading for long lists
- Minimize unnecessary rebuilds (Riverpod selector optimization)
- Reduce app startup time (defer non-critical initialization)
- Profile with Flutter DevTools — fix any jank

**Done when:**
- [ ] App cold start < 3 seconds
- [ ] Document list with 100+ items scrolls smoothly
- [ ] Image loading doesn't block UI
- [ ] No unnecessary Supabase calls (verified via network tab)

---

### 8.4 Accessibility

**Assignee:** Agent
**Depends on:** 8.2

**What to build:**
- Semantic labels on all interactive elements
- Touch targets ≥ 48dp
- Contrast ratios meet WCAG AA
- Screen reader navigation order makes sense
- Dynamic text size support

**Done when:**
- [ ] VoiceOver (iOS) and TalkBack (Android) can navigate all key flows
- [ ] No interactive element smaller than 48x48dp
- [ ] Text readable at 200% system font size
- [ ] Contrast passes WCAG AA automated check

---

## 11. Phase 9: Launch Prep

**Final steps before App Store submission.**

---

### 9.1 Analytics Integration

**Assignee:** Agent
**Depends on:** All features complete, PostHog account setup
**Agent branch:** `feature/analytics`

**What to build:**
- PostHog SDK initialization
- Key event tracking: sign_up, sign_in, document_uploaded, task_completed, project_created, emergency_hub_setup_complete, subscription_started, subscription_cancelled
- User properties: subscription_tier, platform, onboarding_completed
- Screen view tracking

**Done when:**
- [ ] Events firing correctly in PostHog dashboard
- [ ] User properties set on identification
- [ ] No PII in analytics events

---

### 9.2 Error Tracking

**Assignee:** Agent
**Depends on:** All features complete, Sentry account setup
**Agent branch:** `feature/error-tracking`

**What to build:**
- Sentry SDK initialization with Flutter integration
- Automatic crash reporting
- Manual error capturing with context tags per Error Handling Guide Section 15
- Performance monitoring (transaction tracking)

**Done when:**
- [ ] Test crash shows up in Sentry dashboard
- [ ] Errors include feature tags and relevant context
- [ ] No PII captured in error reports

---

### 9.3 Production Environment

**Assignee:** You
**Depends on:** All features complete

**What to build:**
- Supabase production project created and configured
- All migrations pushed to production
- Storage buckets created in production
- Environment variables set for production
- Edge Functions deployed
- Cron jobs scheduled
- `.env.production` file created

**Done when:**
- [ ] Production Supabase has all 27 tables with seed data
- [ ] Storage buckets configured with policies
- [ ] Edge Functions deployed and responding
- [ ] Cron jobs running on schedule
- [ ] App connects to production with production env file

---

### 9.4 App Store Submission

**Assignee:** You (with agent support for assets)
**Depends on:** 9.3, Apple Developer + Google Play accounts

**What to build:**

**iOS (App Store):**
- App icons (all required sizes)
- Screenshots (6.7", 6.5", 5.5" — at minimum)
- App description, keywords, categories
- Privacy policy URL
- App review notes (test account credentials)
- Build uploaded via Xcode → App Store Connect

**Android (Google Play):**
- App icons and feature graphic
- Screenshots (phone, optional tablet)
- Store listing (description, short description, categories)
- Privacy policy URL
- Content rating questionnaire
- Signed release APK/AAB uploaded

**Done when:**
- [ ] iOS build uploaded to App Store Connect
- [ ] Android AAB uploaded to Google Play Console
- [ ] All store listing metadata complete
- [ ] Privacy policy live at URL
- [ ] Submitted for review

---

### 9.5 Final QA

**Assignee:** You + Agent
**Depends on:** 9.3

**What to build:**
- Full flow testing on real iOS device
- Full flow testing on real Android device
- Test all happy paths: onboarding → upload document → add system → create task → set up emergency hub → create project
- Test all error paths: offline, no permission, free tier limits, expired session
- Test on older devices (3+ year old phones per SRS requirement)
- Test trial flow end-to-end

**Done when:**
- [ ] All 5 features work on iOS and Android
- [ ] No crashes in 1 hour of continuous use
- [ ] Offline Emergency Hub works
- [ ] Free tier limits enforced correctly
- [ ] Trial flow works end-to-end
- [ ] Performance acceptable on older devices

---

## 12. Dependency Map

Visual overview of what depends on what:

```
Phase 0: Foundation
  ├── 0.1 Repo Setup
  ├── 0.2 Database ──────────────────────────────────────────────┐
  ├── 0.3 Flutter Scaffold                                       │
  ├── 0.4 Design System ← 0.3                                   │
  ├── 0.5 Core Widgets ← 0.4                                    │
  ├── 0.6 Navigation ← 0.5                                      │
  ├── 0.7 Auth Flow ← 0.5, 0.6                                  │
  └── 0.8 Onboarding ← 0.7                                      │
                                                                  │
  ┌──────── All depend on Phase 0 complete ──────────────────────┘
  │
  │  These can run IN PARALLEL:
  │
  ├── Phase 1: Document Vault (Agent A)
  │     1.1 List → 1.2 Upload → 1.7 OCR
  │     1.1 → 1.3 Detail
  │     1.1 → 1.4 Search
  │     1.1 + 1.3 → 1.5 Expiration Dashboard
  │     1.1 → 1.6 Custom Categories
  │
  ├── Phase 2: Maintenance Calendar (Agent B)
  │     2.1 List → 2.2 Detail → 2.3 Completion
  │     2.1 → 2.4 Custom Task
  │     2.1 + 0.8 → 2.5 Task Generation
  │     2.1 + 2.3 → 2.6 Health Score
  │
  ├── Phase 3: Home Profile (Agent C)
  │     3.1 Overview → 3.2 Systems → 3.4 Lifespan
  │     3.1 → 3.3 Appliances
  │
  ├── Phase 4: Emergency Hub (Agent D)
  │     4.1 Main → 4.2 Shutoffs
  │     4.1 → 4.3 Contacts ←──── SHARED CONTRACTOR POOL
  │     4.1 → 4.4 Insurance             │
  │     4.1-4.4 → 4.5 Offline Sync      │
  │                                       │
  └── Phase 5: Projects (Agent E)         │
        Depends on: 4.3 (contacts) ───────┘
        5.1 List → 5.2 Create
        5.2 → 5.3 Phases
        5.2 → 5.4 Budget
        5.2 + 4.3 → 5.5 Contractors
        5.2 → 5.6 Photos
        5.2 → 5.7 Journal
        5.2 + Phase 1 → 5.8 Document Linking

Phase 6: Subscription ← All features
Phase 7: Notifications ← All features
Phase 8: Polish ← All features + 6 + 7
Phase 9: Launch ← Phase 8
```

---

## 13. Agent Assignment Guide

### Recommended Agent Assignments

| Agent | Primary Feature | Branch | Directory |
|-------|----------------|--------|-----------|
| Agent A | Document Vault (1.1–1.7) | `feature/document-vault` | `lib/features/documents/` |
| Agent B | Maintenance Calendar (2.1–2.6) | `feature/maintenance-calendar` | `lib/features/maintenance/` |
| Agent C | Home Profile (3.1–3.4) | `feature/home-profile` | `lib/features/home_profile/` |
| Agent D | Emergency Hub (4.1–4.5) | `feature/emergency-hub` | `lib/features/emergency/` |
| Agent E | Projects (5.1–5.8) | `feature/projects` | `lib/features/projects/` |

### Parallel Work Windows

**Window 1:** Agents A, B, C, D can all start simultaneously after Phase 0
**Window 2:** Agent E starts after Agent D completes 4.3 (emergency contacts / shared contractor pool)
**Window 3:** Subscription + Notifications after all features land on `develop`
**Window 4:** Polish, then Launch

### Integration Checkpoints

After each agent finishes their feature, you (the integrator) should:

1. Review the feature branch
2. Run tests: `flutter test`
3. Run analyzer: `flutter analyze`
4. Test on simulator manually
5. Merge to `develop`
6. Verify no regressions on other features
7. Check cross-feature links work (documents ↔ systems, contacts ↔ projects, etc.)

### What Agents Should Deliver Per Feature

Each agent delivers:
- All screen code in their feature directory
- Riverpod providers for their feature's state
- Models/DTOs for their feature's data
- Widget tests for key screens (at minimum: list screen, detail screen, create form)
- List of routes that need to be added to the router
- List of any shared code they created or needed

### What Agents Need Your Approval to Touch

These shared areas affect all features. Agents can modify them, but **only with your explicit approval** first. They should flag what they need and why, then wait for your go-ahead before making changes:

- `lib/core/` — theme, shared widgets (flag what's missing or needs change)
- `lib/services/` — Supabase, auth, storage services (flag what method or service is needed)
- `lib/router/` — router configuration (provide the routes, explain why)
- `supabase/migrations/` — no new migrations without your approval (describe the schema change needed)
- Any other agent's feature directory — coordinate through you to avoid conflicts

---

## Chunk Summary

| Phase | Chunks | Can Parallelize |
|-------|--------|----------------|
| Phase 0: Foundation | 8 | Sequential (0.1–0.8) |
| Phase 1: Document Vault | 7 | 1.1 first, then 1.2–1.6 parallel, 1.7 after 1.2 |
| Phase 2: Maintenance Calendar | 6 | 2.1 first, then 2.2–2.4 parallel, 2.5–2.6 after |
| Phase 3: Home Profile | 4 | 3.1 first, then 3.2–3.3 parallel, 3.4 after 3.2 |
| Phase 4: Emergency Hub | 5 | 4.1 first, then 4.2–4.4 parallel, 4.5 after all |
| Phase 5: Projects | 8 | 5.1–5.2 first, then 5.3–5.7 parallel, 5.8 after Phase 1 |
| Phase 6: Subscription | 2 | Sequential |
| Phase 7: Notifications | 2 | Sequential |
| Phase 8: Polish | 4 | 8.1 first, then 8.2–8.4 parallel |
| Phase 9: Launch | 5 | Mostly sequential |
| **Total** | **51 chunks** | |

---

## Cross-References to Specification Documents

The following documents provide detailed specifications that supplement this Sprint Plan. Agents should consult these before implementing the relevant features:

| Document | Relevant Sprint Phases | What It Specifies |
|----------|----------------------|-------------------|
| **HomeTrack Dashboard Spec** | Phase 0.6 (navigation), Phase 8 (polish) | Home tab section layout, hero card, quick actions, insights engine, urgent banner, onboarding flow, task relevance model, property transfer |
| **HomeTrack Health Score Algorithm** | Phase 2.6 (health score) | Three-pillar scoring formula (maintenance/documents/emergency), pillar weights, overdue penalties, trend calculation, expanded API contract for `get_home_health_score` RPC |
| **HomeTrack Empty States Catalog** | All feature phases | Exact empty state pattern (motivational/showcase/instructional), copy, icons, and CTA for every screen in the app. 25 total empty states defined. |
| **HomeTrack Dashboard State Variations** | Phase 0.6, Phase 0.8, Phase 8.2 | 8 dashboard states (day one through offline), section visibility matrix, hero adaptation rules, needs attention card, greeting subtitle priority |
| **HomeTrack Notification Priority** | Phase 7 (notifications) | Three-tier priority system (P1/P2/P3), daily digest batching, urgent delivery timing, back-off rules, per-task muting, quiet hours, database schema additions (Migration 012) |
| **HomeTrack Security Guide** | All phases | Auth providers (email + Apple + Google), session management (7-day expiry), biometric unlock, input validation rules, PII handling, Sentry configuration, pre-deployment security checklist. Every agent references §8 checklist before PRs. |

---

*End of Sprint Plan & Backlog*
*HomeTrack — Version 1.1 — February 2026*
