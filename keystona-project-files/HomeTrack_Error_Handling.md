# HomeTrack Error Handling & Edge Case Guide
## The Rulebook for When Things Go Wrong (or Empty, or Slow, or Offline)

**Version 1.0 | February 2026**
**Status:** Active — Every agent follows this before building any screen

---

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [Error Display Patterns](#2-error-display-patterns)
3. [Loading States](#3-loading-states)
4. [Empty States](#4-empty-states)
5. [Offline Behavior](#5-offline-behavior)
6. [Form Validation](#6-form-validation)
7. [Network & Retry Logic](#7-network--retry-logic)
8. [Supabase Error Handling](#8-supabase-error-handling)
9. [Permission Handling](#9-permission-handling)
10. [Subscription Gating & Upgrade Flows](#10-subscription-gating--upgrade-flows)
11. [File Upload Edge Cases](#11-file-upload-edge-cases)
12. [Data Conflicts & Sync](#12-data-conflicts--sync)
13. [Crash Recovery](#13-crash-recovery)
14. [Feature-Specific Edge Cases](#14-feature-specific-edge-cases)
15. [Error Logging & Monitoring](#15-error-logging--monitoring)
16. [Quick Reference Table](#16-quick-reference-table)

---

## 1. Philosophy

Three principles guide every error handling decision in HomeTrack:

**1. Never leave the user confused.**
Every error has a clear message explaining what happened and what they can do about it. No generic "Something went wrong" without a next step.

**2. Never lose user data.**
If a user spent time entering data or uploading a file, protect that work. Cache form state, retry uploads, preserve drafts.

**3. Keep it calm.**
HomeTrack is a home management app, not mission control. Errors should feel like a helpful nudge, not an alarm. The only exception is the Emergency Hub, where clarity and urgency are appropriate.

### Tone Guidelines

| Context | Tone | Example |
|---------|------|---------|
| Minor error | Casual, reassuring | "Couldn't save just now. We'll try again in a moment." |
| User mistake | Helpful, no blame | "That email doesn't look quite right. Mind checking it?" |
| Feature limit | Gentle, value-focused | "You've filled up your free vault! Premium gives you unlimited storage." |
| Connection issue | Informative, patient | "You're offline. Your Emergency Hub is still available." |
| Upload failure | Protective of their work | "Upload interrupted — your file is saved and will resume when you're back online." |
| Critical (data loss risk) | Clear and direct | "We couldn't save your changes. Please try again before leaving this screen." |

---

## 2. Error Display Patterns

### 2.1 Snackbar (Primary — Use for Most Errors)

The default error display. Brief message at bottom of screen, auto-dismisses after 4 seconds.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                    [Screen Content]                      │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ ⚠ Couldn't upload document. Check connection. [RETRY]   │
└─────────────────────────────────────────────────────────┘
```

**When to use:** Network errors, save failures, minor validation, success confirmations.

**Implementation rules:**
- Auto-dismiss after **4 seconds**
- Max **2 lines** of text
- Optional action button (right side): "RETRY", "UNDO", "VIEW"
- Queue snackbars — never stack or overlap
- Colors: Error = `#D32F2F` background, Success = `#2E7D32` background, Warning = `#F57C00` background
- Text: White, 14px

**Snackbar message templates:**

```dart
// Network errors
"Couldn't save. Check your connection and try again."
"Connection lost. Reconnecting..."
"Back online! Syncing your changes."

// Save/update errors
"Couldn't save changes. Tap to retry."
"Update failed. Your changes are preserved — try again."

// Success confirmations
"Document uploaded ✓"
"Task marked complete ✓"
"Contact saved ✓"
"Photo added ✓"

// Undo-able actions
"Document moved to trash. [UNDO]"
"Task skipped. [UNDO]"
```

### 2.2 Inline Error (Form Fields)

Error text directly below the problematic field. Red text, appears on validation failure.

```
┌─────────────────────────────────────────┐
│ Email                                   │
│ ┌─────────────────────────────────────┐ │
│ │ jane@                               │ │ ← Red border
│ └─────────────────────────────────────┘ │
│ ⚠ Enter a valid email address           │ ← Red text, 12px
└─────────────────────────────────────────┘
```

**When to use:** Form validation errors only.

**Rules:**
- Text color: `#D32F2F`
- Font size: 12px
- Appears below the field, shifts content down (don't overlay)
- Field gets red border
- Clears when user starts typing in the field

### 2.3 Full-Screen Error (Rare)

Only for situations where the entire screen can't load.

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│              [Error Icon]               │
│                                         │
│        Something's not working          │
│                                         │
│    We couldn't load your documents.     │
│    This is usually a connection issue.  │
│                                         │
│          ┌──────────────┐               │
│          │   Try Again   │              │
│          └──────────────┘               │
│                                         │
└─────────────────────────────────────────┘
```

**When to use:** Initial screen load fails (no cached data available), authentication expired.

**Rules:**
- Centered vertically
- Friendly icon (not a red X — use an illustration or subtle icon)
- Short headline + one sentence explanation
- Primary action button: "Try Again"
- Secondary option if applicable: "Go Back" or "Contact Support"
- Never show technical details to the user

### 2.4 Bottom Sheet (Contextual Actions Required)

For errors that need user decision before proceeding.

**When to use:**
- File too large (needs compression decision)
- Unsupported file type (suggest alternatives)
- Premium feature gate (show upgrade value)
- Destructive action confirmation (delete)

**Rules:**
- Draggable, dismissible
- Max 50% screen height
- Clear title, body text, and action buttons
- Always include a "Cancel" / "Not Now" option

---

## 3. Loading States

### 3.1 Skeleton Screens (Primary — Use for All Content Loading)

Gray placeholder shapes that mimic the layout of the content being loaded. This is HomeTrack's standard loading pattern.

```
┌─────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                        │  ← Title placeholder
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           │ │  ← Card skeleton
│ │ ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓                 │ │
│ │         ▓▓▓▓▓▓▓▓                    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           │ │  ← Card skeleton
│ │ ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓                 │ │
│ │         ▓▓▓▓▓▓▓▓                    │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           │ │  ← Card skeleton
│ │ ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓                 │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Implementation rules:**
- Skeleton color: `#E0E0E0` (light gray)
- Subtle pulse animation (opacity 0.4 → 1.0, 1.5s cycle)
- Match the exact layout of the real content (same card height, text line widths)
- Show 3-5 skeleton items for lists
- Each screen has its own skeleton that matches its specific layout
- Transition: fade from skeleton to real content (200ms)

**Skeleton required for every screen:**

| Screen | Skeleton Shape |
|--------|---------------|
| Document list | Card with thumbnail + 3 text lines |
| Document detail | Header image + text blocks |
| System/appliance list | Category header + item cards |
| Maintenance task list | Date header + task cards with status |
| Emergency Hub | 3 utility cards (water/gas/electric) |
| Contact list | Avatar circle + 2 text lines per item |
| Home Health Score | Circle gauge + stat boxes |

### 3.2 Small Spinner (Secondary — Inline Actions Only)

A small circular spinner replacing a button or inline element during a brief action.

**When to use:** Button tap actions (save, complete task, delete) where the action takes 1-3 seconds.

**Rules:**
- Replace button text with spinner (same button size — no layout shift)
- Disable button while loading
- Spinner color: matches button text color
- Spinner size: 20px
- If action takes >5 seconds, switch to snackbar: "Still working..."

### 3.3 Progress Indicator (File Uploads Only)

Linear progress bar showing upload percentage.

```
┌─────────────────────────────────────────┐
│ Uploading insurance_policy.pdf...       │
│ ████████████░░░░░░░░░░  67%            │
│                                [Cancel] │
└─────────────────────────────────────────┘
```

**When to use:** File uploads to Supabase Storage.

**Rules:**
- Show actual progress percentage
- Allow cancel during upload
- If upload completes, show success snackbar
- If upload fails, preserve file reference for retry

### 3.4 Pull-to-Refresh

All scrollable list screens support pull-to-refresh.

**Rules:**
- Standard Flutter `RefreshIndicator`
- Indicator color: Gold Accent (`#C9A84C`)
- Refreshes the entire list
- Shows snackbar if refresh fails: "Couldn't refresh. Pull down to try again."

---

## 4. Empty States

> **Cross-reference:** The **HomeTrack Empty States Catalog** is now the single source of truth for all empty states. It defines the exact pattern (Motivational/Showcase/Instructional), copy, icons, and CTA for every screen — 25 total. This section provides the foundational patterns; the Catalog provides the screen-by-screen implementation details. When building a screen, reference the Catalog for the exact empty state specification.

Empty states are the first thing a new user sees in each feature. They're onboarding opportunities, not dead ends.

### 4.1 Style Guide

**Key features get motivational empty states** — these are the screens where we want to drive first action:

- Document Vault (main screen)
- Maintenance Calendar
- Emergency Hub (each utility type)

**Simple screens get instructional empty states** — straightforward, get out of the way:

- Search results (no matches)
- Contact list
- System/appliance detail
- Notification inbox
- Completion history

### 4.2 Motivational Empty States

```
┌─────────────────────────────────────────┐
│                                         │
│             [Illustration]              │  ← Friendly, on-brand illustration
│                                         │
│     Your Document Vault is ready!       │  ← Headline (20px, semibold)
│                                         │
│   Most homeowners start by uploading    │  ← Subtitle (16px, regular, gray)
│   their insurance policy — it only      │
│   takes 30 seconds.                     │
│                                         │
│        ┌────────────────────┐           │
│        │  + Add First Doc   │           │  ← Primary CTA button
│        └────────────────────┘           │
│                                         │
└─────────────────────────────────────────┘
```

**Per-feature motivational empty states:**

| Screen | Headline | Subtitle | CTA |
|--------|----------|----------|-----|
| Document Vault | "Your Document Vault is ready!" | "Most homeowners start by uploading their insurance policy — it only takes 30 seconds." | "+ Add First Document" |
| Maintenance Calendar | "Stay ahead of home repairs" | "We'll build a personalized maintenance plan based on your home's systems and climate. Add your first system to get started." | "+ Add a System" |
| Emergency Hub — Water | "Know your water shutoff" | "In a burst pipe emergency, every second counts. Add your water shutoff location so it's always one tap away." | "+ Add Water Shutoff" |
| Emergency Hub — Gas | "Locate your gas shutoff" | "Gas leaks are rare but serious. Document your shutoff valve location now so you're ready if it happens." | "+ Add Gas Shutoff" |
| Emergency Hub — Electrical | "Find your electrical panel" | "Whether it's a tripped breaker or an emergency, knowing your panel location saves time and stress." | "+ Add Electrical Panel" |

### 4.3 Instructional Empty States

```
┌─────────────────────────────────────────┐
│                                         │
│              [Simple Icon]              │  ← Muted icon, not illustration
│                                         │
│         No results found                │  ← Headline (16px, semibold)
│                                         │
│     Try a different search term.        │  ← Subtitle (14px, regular, gray)
│                                         │
└─────────────────────────────────────────┘
```

**Per-screen instructional empty states:**

| Screen | Headline | Subtitle |
|--------|----------|----------|
| Search (no results) | "No results found" | "Try a different search term or browse by category." |
| Contact list | "No emergency contacts yet" | "Tap + to add a plumber, electrician, or other pro." |
| Systems list | "No systems added yet" | "Tap + to add your HVAC, plumbing, or other home systems." |
| Appliance list | "No appliances tracked yet" | "Tap + to add your refrigerator, washer, or other appliances." |
| Notification inbox | "All caught up!" | "You'll see maintenance reminders and expiration alerts here." |
| Completion history | "No completed tasks yet" | "Completed maintenance tasks will appear here with cost and notes." |
| Expiration dashboard | "No expiring documents" | "Documents with expiration dates will show up here sorted by urgency." |

### 4.4 Implementation Rules

- Empty states are centered vertically in the available space
- Illustrations/icons are max 120px tall
- Always include at least a headline and subtitle
- Primary CTA button uses Gold Accent (`#C9A84C`) background
- Motivational states: illustration + headline + subtitle + CTA button
- Instructional states: icon + headline + subtitle (no button unless there's an obvious action)
- Empty states disappear as soon as there's one item of data

---

## 5. Offline Behavior

> **Cross-reference:** The **HomeTrack Dashboard State Variations §3.8** defines the specific offline behavior for the Home tab (cached data display, disabled quick actions, offline banner). The **HomeTrack Empty States Catalog §6** defines the offline empty state pattern for all non-Emergency screens.

### 5.1 Strategy: Strict Offline (Emergency Hub Only)

| Feature | Offline Behavior |
|---------|-----------------|
| **Emergency Hub** | ✅ Fully functional — all data cached in local SQLite |
| **All other features** | ❌ Show connection required message, no cached reads |

### 5.2 Connection Detection

```dart
// Monitor connectivity
// Use connectivity_plus package

// Three states:
// 1. CONNECTED     → Normal operation
// 2. DISCONNECTED  → Show offline banner + restrict to Emergency Hub
// 3. RECONNECTED   → Remove banner, sync Emergency Hub changes
```

### 5.3 Offline Banner

When the device loses connection, show a persistent banner at the top of every screen (except Emergency Hub):

```
┌─────────────────────────────────────────┐
│ ░░ You're offline. Emergency Hub        │  ← Amber background
│    is still available. ░░░░░░░░░░░░░░░░ │
├─────────────────────────────────────────┤
│                                         │
│            [Screen Content]             │  ← Content still visible but
│         (disabled / grayed out)         │     interactions disabled
│                                         │
└─────────────────────────────────────────┘
```

**Rules:**
- Banner color: Warning amber (`#FFF3E0` background, `#E65100` text)
- Persists until connection restored
- Tapping banner navigates to Emergency Hub
- Non-Emergency screens: disable all write actions (upload, save, edit)
- Non-Emergency screens: still show cached header/navigation but disable data interactions
- Emergency Hub: no banner, functions completely normally

### 5.4 Emergency Hub Offline Architecture

```
┌─────────────────┐          ┌──────────────────┐
│  Supabase       │  sync    │  Local SQLite     │
│  (server)       │ ◄──────► │  (on device)      │
│                 │          │                    │
│  shutoffs       │ ───────► │  shutoffs          │
│  contacts       │ ───────► │  contacts          │
│  insurance      │ ───────► │  insurance         │
│  photos (URLs)  │ ───────► │  photos (files)    │
│                 │          │                    │
└─────────────────┘          └──────────────────┘
                                     │
                              Reads from SQLite
                              when offline
```

**Sync rules:**
- Sync on every app open (if connected)
- Sync on Emergency Hub tab tap (if connected)
- Photos downloaded to device storage (compressed to <500KB each)
- Last sync timestamp stored and shown: "Last updated: 2 hours ago"
- If sync fails silently, use last cached data (never show error if cached data exists)
- If no cached data AND offline → show empty state: "Connect to the internet to set up your Emergency Hub. Once set up, it works offline."

### 5.5 Offline Edits (Emergency Hub Only)

If user edits Emergency Hub data while offline:

1. Save changes to local SQLite immediately
2. Mark changes as `pending_sync`
3. When connection restores, push changes to Supabase
4. On conflict (server data newer): **server wins** — show snackbar: "Your emergency info was updated on another device. Syncing latest version."
5. On success: clear `pending_sync` flag

---

## 6. Form Validation

### 6.1 When to Validate

| Method | When | Use For |
|--------|------|---------|
| **On blur** (field loses focus) | User tabs/taps away from field | Required fields, email format, phone format |
| **On change** (as user types) | Real-time feedback | Character counters, password strength |
| **On submit** | User taps Save/Submit | All fields re-validated, scroll to first error |

### 6.2 Validation Rules by Field Type

**Required fields:**
```
Message: "[Field name] is required"
Example: "Address is required"
```

**Email:**
```
Regex: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
Message: "Enter a valid email address"
```

**Phone:**
```
Regex: ^\+?[1-9]\d{1,14}$  (E.164 or 10-digit US)
Message: "Enter a valid phone number"
Allow: formatting characters (spaces, dashes, parens) — strip before saving
```

**Dates:**
```
Must be valid calendar date
Future dates: allowed for expiration_date, due_date
Past dates: allowed for purchase_date, installation_date
Message: "Enter a valid date"
```

**Currency amounts:**
```
Must be positive number
Max: 99,999,999.99
Auto-format with commas and 2 decimal places
Message: "Enter a valid amount"
```

**File size:**
```
Documents: max 25MB
Photos (items, completion): max 10MB
Shutoff photos: max 5MB (encourage compression)
Message: "File is too large (max [X]MB). Try a smaller file or compress it."
```

**File type:**
```
Documents: PDF, JPEG, PNG, HEIC, WebP
Photos: JPEG, PNG, HEIC, WebP
Message: "This file type isn't supported. Try PDF, JPEG, or PNG."
```

**Text fields:**
```
Document name: max 200 characters
Notes: max 2000 characters
Description: max 500 characters
Address: max 200 characters
Show character counter when within 20% of limit
```

### 6.3 Form State Preservation

**Rule: Never lose user input.**

- If user navigates away from an incomplete form, preserve state
- On return, restore all field values
- If app is killed mid-form, attempt to restore from local storage
- On deliberate cancel: show confirmation if any field has data
  - "You have unsaved changes. Discard them?" [Discard] [Keep Editing]

### 6.4 Submit Button States

```
┌─────────────────────┐
│       Save          │  ← Enabled: Gold Accent, full opacity
└─────────────────────┘

┌─────────────────────┐
│       Save          │  ← Disabled: Gray, 50% opacity (form invalid)
└─────────────────────┘

┌─────────────────────┐
│      ◌  Saving...   │  ← Loading: Spinner replaces text, disabled
└─────────────────────┘

┌─────────────────────┐
│      ✓  Saved       │  ← Success: Green flash, then return to normal
└─────────────────────┘
```

---

## 7. Network & Retry Logic

### 7.1 Automatic Retry

For transient failures (network timeout, 500 server errors):

```
Attempt 1: immediate
Attempt 2: after 2 seconds
Attempt 3: after 4 seconds
(give up after 3 attempts)
```

**Applies to:**
- Data fetches (GET)
- File uploads
- Edge Function calls

**Does NOT apply to:**
- User-initiated actions (save, delete) — show error immediately, let user retry manually
- Authentication calls — show error, let user try again
- 4xx errors (client errors) — no retry, the request itself is wrong

### 7.2 Manual Retry

When automatic retry fails, show retry option to user:

```
Snackbar: "Couldn't load documents. [RETRY]"
```

Or on full-screen error:
```
[Try Again] button
```

### 7.3 Timeout Thresholds

| Operation | Timeout | On Timeout |
|-----------|---------|------------|
| Data fetch | 10 seconds | Show error, offer retry |
| File upload | 60 seconds | Show error, preserve file for retry |
| Edge Function | 30 seconds | Show error, offer retry |
| Search query | 5 seconds | Show "Search is taking longer than usual..." |
| Image load | 15 seconds | Show placeholder image |

### 7.4 Background Sync

For operations that happen in the background (OCR processing, thumbnail generation):

- Don't block the user
- Show status indicator if relevant: "Processing document..."
- Poll for completion every 5 seconds (max 60 seconds)
- If still not done after 60 seconds: show "Processing is taking a while. We'll notify you when it's ready."
- User can navigate away — processing continues server-side

---

## 8. Supabase Error Handling

### 8.1 PostgREST Errors (Database)

```dart
try {
  final data = await supabase.from('documents').select();
} on PostgrestException catch (e) {
  switch (e.code) {
    case '42501':  // RLS violation
      showSnackbar('You don\'t have access to this data.');
      break;
    case '23505':  // Unique constraint violation
      showSnackbar('This item already exists.');
      break;
    case '23503':  // Foreign key violation
      showSnackbar('Referenced item no longer exists. Please refresh.');
      break;
    case '23514':  // Check constraint violation
      showSnackbar('Some data is invalid. Please check your entries.');
      break;
    case 'PGRST116':  // No rows found (.single() on empty result)
      // Handle gracefully — show empty state, not error
      break;
    default:
      showSnackbar('Something went wrong. Please try again.');
      logError(e);  // Log to Sentry
  }
}
```

### 8.2 Storage Errors (File Upload/Download)

```dart
try {
  await supabase.storage.from('documents').upload(path, file);
} on StorageException catch (e) {
  if (e.statusCode == '413') {
    showSnackbar('File is too large. Maximum size is 25MB.');
  } else if (e.statusCode == '415') {
    showSnackbar('File type not supported. Try PDF, JPEG, or PNG.');
  } else if (e.statusCode == '403') {
    showSnackbar('Upload permission denied. Please sign in again.');
  } else {
    showSnackbar('Upload failed. Tap to retry.');
    logError(e);
  }
}
```

### 8.3 Auth Errors

```dart
try {
  await supabase.auth.signInWithPassword(email: email, password: password);
} on AuthException catch (e) {
  switch (e.message) {
    case 'Invalid login credentials':
      showSnackbar('Incorrect email or password. Please try again.');
      break;
    case 'Email not confirmed':
      showSnackbar('Please check your email and confirm your account.');
      break;
    case 'User already registered':
      showSnackbar('An account with this email already exists. Try signing in.');
      break;
    case 'Password should be at least 6 characters':
      // Show as inline field error, not snackbar
      setFieldError('password', 'Password must be at least 6 characters');
      break;
    default:
      showSnackbar('Sign in failed. Please try again.');
      logError(e);
  }
}
```

### 8.4 Edge Function Errors

```dart
try {
  final response = await supabase.functions.invoke('process-document-ocr',
    body: {'document_id': docId},
  );

  if (response.status != 200) {
    final error = response.data;
    switch (error['code']) {
      case 'FREE_TIER_DOCUMENT_LIMIT':
        showUpgradeSheet(
          title: 'Document vault is full',
          message: 'Your free plan includes 25 documents. Upgrade to Premium for unlimited storage.',
        );
        break;
      case 'OCR_PROCESSING_FAILED':
        showSnackbar('We couldn\'t read this document\'s text. Search may be limited.');
        // Document is still usable — just without OCR text
        break;
      default:
        showSnackbar('Something went wrong. Please try again.');
        logError(error);
    }
  }
} catch (e) {
  showSnackbar('Couldn\'t connect to server. Please try again.');
  logError(e);
}
```

### 8.5 Session Expiration

```dart
// Listen for auth state changes globally
supabase.auth.onAuthStateChange((event, session) {
  if (event == AuthChangeEvent.signedOut || session == null) {
    // Token expired or user signed out
    navigateToLogin();
    showSnackbar('Your session expired. Please sign in again.');
  }
});
```

---

## 9. Permission Handling

### 9.1 Permission Request Flow

```
1. User taps action requiring permission (e.g., camera)
2. Check if permission is granted
3. If never asked → show system permission dialog
4. If previously denied → show explanation sheet THEN system settings
5. If permanently denied → show settings redirect sheet
```

### 9.2 Pre-Permission Explanation

Before the system dialog, show a brief explanation of why we need access:

```
┌─────────────────────────────────────────┐
│                                         │
│  📷  Camera Access                      │
│                                         │
│  HomeTrack uses your camera to scan     │
│  documents and photograph your home     │
│  systems.                               │
│                                         │
│  ┌──────────┐  ┌───────────────┐        │
│  │ Not Now  │  │   Continue    │        │
│  └──────────┘  └───────────────┘        │
│                                         │
└─────────────────────────────────────────┘
```

### 9.3 Permission Denied Handling

| Permission | Feature Affected | If Denied |
|------------|-----------------|-----------|
| Camera | Document upload, system photos, shutoff photos | Show "Choose from Files" as alternative. Snackbar: "Camera access needed for scanning. You can still upload from Files." |
| Photo Library | Document upload from gallery | Show "Take Photo" as alternative. Snackbar: "Photo access needed to upload from your library." |
| Notifications | Push reminders | App works fully without push. Show in Settings: "Turn on notifications so you never miss a maintenance reminder." |
| Location (future) | Climate zone auto-detect | Fall back to ZIP code entry. No error shown. |

### 9.4 Settings Redirect

If permission is permanently denied, redirect to system settings:

```dart
showModalBottomSheet(
  title: 'Camera Access Required',
  message: 'To scan documents, HomeTrack needs camera access. You can enable this in Settings.',
  primaryAction: 'Open Settings',  // Opens iOS/Android settings for this app
  secondaryAction: 'Not Now',
);
```

---

## 10. Subscription Gating & Upgrade Flows

### 10.1 Philosophy: Gentle and Helpful

Never punish free users. Show them the value they're missing, not a locked door.

### 10.2 Free Trial Flow

**Trial structure:** 30-day free Premium trial, credit card required upfront, auto-converts to paid Premium at end of trial.

**When it starts:** Prompted after onboarding completion. User has set up their property and seen the app — they've earned it.

```
Onboarding complete
        │
        ▼
┌─────────────────────────────────────────┐
│                                         │
│  🎉  Your home is set up!              │
│                                         │
│  Try Premium free for 30 days and get:  │
│                                         │
│  ✦ Unlimited document storage           │
│  ✦ Full-text search across all docs     │
│  ✦ Home value tracking                  │
│  ✦ Weather-based maintenance alerts     │
│  ✦ 2 household members                  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Start Free Trial — $0 today   │    │
│  │  Then $7.99/mo after 30 days   │    │
│  └─────────────────────────────────┘    │
│                                         │
│     Continue with Free plan             │
│                                         │
└─────────────────────────────────────────┘
```

**RevenueCat handles:**
- Card collection via App Store / Google Play native flow
- 30-day free period
- Auto-conversion to paid subscription
- Cancellation at any time during trial

**Trial state tracking in `profiles` table:**
- `trial_started_at` — set when trial begins
- `trial_ends_at` — set to `trial_started_at + 30 days`
- `subscription_tier` — set to `'premium'` during trial
- On conversion: RevenueCat webhook updates `subscription_id`
- On cancellation/expiry: RevenueCat webhook sets tier back to `'free'`

**Trial ending reminders (subtle):**

| Day | Channel | Message |
|-----|---------|---------|
| Day 25 | In-app banner (top of home screen) | "Your Premium trial ends in 5 days. You've uploaded [X] documents and completed [Y] tasks!" |
| Day 28 | Push notification | "Your Premium trial ends in 2 days. Your documents and data are safe either way." |
| Day 30 | Push notification | "Your Premium trial ended today. Thanks for trying it! You can upgrade anytime." |

**Banner design (Day 25-30):**

```
┌─────────────────────────────────────────┐
│ ✦ Premium trial ends in 5 days.  [View] │  ← Gold background, subtle
└─────────────────────────────────────────┘
```

Tapping [View] opens a summary screen showing what they used during the trial and what they'd lose.

**What happens when the trial ends without converting → Time-Limited Freeze (14 days):**

The trial ends and a 14-day grace period begins. During this window, the user can still see everything but can't add new content past free limits. After 14 days, documents beyond the free tier (25) are **archived** — moved out of the active vault, no longer viewable in-app, but never deleted. Upgrading at any time instantly restores everything.

**Timeline:**

```
Day 0          Day 30              Day 44
│               │                   │
▼               ▼                   ▼
[Trial starts]  [Trial ends]        [Archive happens]
                │← 14-day grace →│
                   period
```

**During 14-day grace period (Day 30–44):**

| Feature | Behavior |
|---------|----------|
| Documents (all) | **Read-only** — can view, download, and share all docs. Cannot upload new docs past 25. |
| OCR full-text search | ❌ Reverts to name/category search only |
| Home value tracking | ❌ Hidden from navigation |
| Weather alerts | ❌ Notifications stop |
| Household members (2nd) | ❌ 2nd member loses access, notified by email |
| Maintenance calendar | ✅ (always free) |
| Emergency Hub | ✅ (always free) |
| Home Profile | ✅ (always free) |

**After 14-day grace period (Day 44+):**

| Feature | Behavior |
|---------|----------|
| Documents 1–25 (most recent) | ✅ Full access (free tier) |
| Documents 26+ | **Archived** — not visible in vault, not searchable, but NOT deleted. Stored server-side. |
| All premium features | ❌ Off (same as free tier) |
| Core features | ✅ Maintenance, Emergency Hub, Home Profile all work normally |

**Archive rules:**
- Archived documents are kept server-side for **1 year** after archival
- If user upgrades within 1 year, all archived docs instantly restore
- After 1 year with no upgrade, archived docs are permanently deleted
- User is notified 30 days before permanent deletion: "Your archived documents will be permanently removed on [date]. Upgrade or download them before then."
- User can always request a **data export** (CCPA) to download archived documents as a ZIP, even on free tier

**Grace period reminders:**

| Day | Channel | Message |
|-----|---------|---------|
| Day 30 (trial ends) | Push + in-app | "Your Premium trial ended. You have 14 days to upgrade or download your documents." |
| Day 37 (7 days left) | Push | "7 days left before your extra documents are archived. Upgrade to keep full access." |
| Day 42 (2 days left) | Push | "In 2 days, documents beyond your free limit will be archived. Download or upgrade now." |
| Day 44 (archive day) | Push + in-app | "Your extra documents have been archived. Upgrade anytime to restore them." |

**Grace period banner (Day 30–44):**

```
┌─────────────────────────────────────────────────────┐
│ ⚠ 9 documents will be archived in 8 days.  [Upgrade]│  ← Amber background
└─────────────────────────────────────────────────────┘
```

Shows exact count of at-risk documents and countdown. Tapping [Upgrade] goes to subscription screen.

**Post-trial upgrade prompt (shown once, on first app open after trial ends):**

```
┌─────────────────────────────────────────┐
│                                         │
│  Your Premium trial has ended           │
│                                         │
│  During your trial you:                 │
│  • Uploaded 34 documents                │
│  • Completed 8 maintenance tasks        │
│  • Set up your Emergency Hub            │
│                                         │
│  You have 14 days to upgrade or         │
│  download your documents. After that,   │
│  9 documents over the free limit will   │
│  be archived.                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Continue with Premium $7.99/mo │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Download My Documents          │    │
│  └─────────────────────────────────┘    │
│                                         │
│       Continue with Free plan           │
│                                         │
└─────────────────────────────────────────┘
```

**Key rules:**
- **Never delete data without warning.** Users always get 30-day notice before permanent deletion.
- **Archive ≠ delete.** Archived docs are invisible in-app but recoverable by upgrading (for 1 year).
- **Download is always available.** Even archived docs can be exported via CCPA data export.
- **Upgrading instantly restores.** No waiting, no re-upload. Everything comes back.

### 10.3 Gating Triggers

| Trigger | Free Limit | Premium/Family |
|---------|-----------|----------------|
| Upload 26th document | 25 documents | Unlimited |
| Search document content (OCR) | Name/category only | Full-text OCR search |
| Invite 2nd household member | 1 member | 2 (Premium) / 5 (Family) |
| Home value tracking | Not available | ✅ |
| Weather alerts | Not available | ✅ |
| Home History Report | Not available | ✅ |

### 10.4 Upgrade Bottom Sheet

When a free user taps a premium feature or hits a limit:

```
┌─────────────────────────────────────────┐
│                                         │
│  ━━━━━  (drag handle)                   │
│                                         │
│  🏠  Unlock Unlimited Documents         │  ← Headline
│                                         │
│  Your Document Vault is full with 25    │  ← Friendly explanation
│  documents on the Free plan.            │
│                                         │
│  With Premium, you get:                 │  ← Value list
│  ✦ Unlimited document storage           │
│  ✦ Full-text search across all docs     │
│  ✦ Home value tracking                  │
│  ✦ Weather-based maintenance alerts     │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  See Premium Plans — $7.99/mo   │    │  ← Primary CTA
│  └─────────────────────────────────┘    │
│                                         │
│           Maybe Later                   │  ← Subtle dismiss
│                                         │
└─────────────────────────────────────────┘
```

### 10.5 Tone Rules

- **Never say:** "Upgrade required", "Locked", "Subscribe to access", "You can't do this"
- **Instead say:** "Unlock [feature]", "Available with Premium", "Get more from HomeTrack"
- **Never block the flow aggressively.** "Maybe Later" is always visible and easy to tap.
- **Never show the upgrade sheet more than once per session** for the same trigger.
- **Track dismissals** — if user dismisses 3 times for the same feature, stop showing for 7 days.

### 10.6 Inline Premium Badges

For features visible but not accessible to free users, show a small badge:

```
┌─────────────────────────────────────────┐
│ 🔍  Search documents          [✦ PRO]  │  ← Small gold badge
└─────────────────────────────────────────┘
```

Badge: Gold Accent background, white "PRO" text, small and unobtrusive.

Tapping the feature → opens upgrade bottom sheet.

---

## 11. File Upload Edge Cases

### 11.1 Upload Interrupted (Connection Lost)

1. Detect connection loss during upload
2. Pause upload (preserve progress if possible)
3. Show snackbar: "Upload paused — no connection."
4. When connection restores: auto-resume if user is still on same screen
5. If user navigated away: show notification "Your upload is ready to resume" (next app open)

### 11.2 App Killed During Upload

1. File reference saved to local storage before upload starts
2. On next app open, check for pending uploads
3. Show snackbar: "You have a document waiting to upload. [RESUME]"
4. Resume upload from beginning (Supabase Storage doesn't support resumable uploads)

### 11.3 Duplicate Detection

Before uploading, check:
- Same filename + same file size + same property → likely duplicate
- Show: "A document with this name already exists. Upload anyway?" [Upload] [Cancel]

### 11.4 HEIC Conversion

iOS devices capture HEIC by default:
- Convert to JPEG before upload (using `flutter_image_compress`)
- Conversion happens client-side, transparent to user
- If conversion fails, upload original HEIC (Supabase Storage accepts it)

### 11.5 Large File Handling

If file exceeds limit:
- Show bottom sheet before upload attempt (don't waste bandwidth)
- "This file is [X]MB, which exceeds the [limit]MB limit."
- For images: offer compression option: "Compress to fit? Quality will be slightly reduced."
- For PDFs: "Try a smaller PDF or split it into sections."

---

## 12. Data Conflicts & Sync

### 12.1 Household Member Conflicts

Two household members editing the same record simultaneously:

**Strategy: Last Write Wins**

- No real-time locking (too complex for MVP)
- Supabase `updated_at` column tracks latest change
- If two users save the same record, the last save wins
- This is acceptable for MVP — conflicts will be rare with 1-2 household members

### 12.2 Realtime Updates

When another household member changes data:
- Supabase Realtime pushes the change
- UI updates automatically (Riverpod state refresh)
- No notification to user — data just appears/updates
- Exception: if user is actively editing the same record, don't overwrite their form. Apply change after they save or navigate away.

---

## 13. Crash Recovery

### 13.1 Form Data Recovery

```dart
// On every field change, save form state to SharedPreferences
// Key: 'draft_{screen_name}_{entity_id}'
// Value: JSON of all form fields

// On screen open, check for draft:
// If draft exists and is < 24 hours old → restore it
// If draft is > 24 hours old → discard silently
// On successful save → clear draft
```

### 13.2 Upload Recovery

```dart
// Before upload starts:
// Save to SharedPreferences: { file_path, property_id, category_id, metadata, timestamp }

// On app restart:
// Check for pending uploads
// If found and < 7 days old → offer to resume
// If found and > 7 days old → discard, show snackbar
```

### 13.3 Navigation State

- Use GoRouter's state restoration
- If app is killed and relaunched, return to the last active tab (not the last deep screen)
- Auth state persists (JWT stored securely) — user doesn't need to re-login

---

## 14. Feature-Specific Edge Cases

### 14.1 Document Vault

| Edge Case | Handling |
|-----------|---------|
| OCR fails on uploaded document | Document saved normally, search limited to name/category. Show subtle note on document: "Text search unavailable for this document." |
| User uploads same document twice | Duplicate detection based on name + size. Prompt user. |
| Expiration date in the past | Allow it. Show "Expired" badge immediately. |
| Category deleted with documents in it | Move documents to "Uncategorized". Never orphan documents. |
| Document viewed on small screen | Pinch to zoom + pan. Rotate button for landscape docs. |

### 14.2 Maintenance Calendar

| Edge Case | Handling |
|-----------|---------|
| Task due date passes without completion | Auto-update status to "overdue" (daily cron job). |
| User completes task, then hits undo | Undo within 5 seconds (snackbar with UNDO). After that, create a new completion reversal. |
| Recurring task completed early | Schedule next occurrence from the **original** due date, not completion date. |
| All tasks completed (none remaining) | Show celebratory empty state: "All caught up! 🎉 Great job keeping your home in shape." |
| System deleted that has linked tasks | Tasks remain but lose system link. Tasks still completable. |

### 14.3 Home Profile

| Edge Case | Handling |
|-----------|---------|
| System with no installation date | Lifespan calculations show "Unknown age". Prompt: "Add an installation date for lifespan tracking." |
| Warranty already expired when entered | Allow it. Show "Expired" badge. Good for records. |
| User replaces a system | Mark old as "replaced", link new one via `replaced_by_system_id`. Old system's completion history preserved. |
| Photo fails to upload | Save photo locally, queue for upload. Show ⚠ icon on photo. |

### 14.4 Emergency Hub

| Edge Case | Handling |
|-----------|---------|
| No photos added for shutoff | Fully functional without photos. Prompt: "Adding a photo helps you find it fast in an emergency." |
| Phone number tapped (call action) | Use `url_launcher` to initiate phone call. If fails: copy number to clipboard, show snackbar. |
| Offline with no cached data | Show: "Connect to the internet to set up your Emergency Hub. Once set up, it works offline." |
| Large circuit directory (30+ breakers) | Scrollable list within electrical shutoff detail. No limit on entries. |

### 14.5 Onboarding

| Edge Case | Handling |
|-----------|---------|
| User skips onboarding | Allow it. Show contextual prompts later: "Set up your home profile to get personalized maintenance tasks." |
| User enters address that doesn't map to climate zone | Fall back to manual ZIP entry. If still no match, allow manual climate zone selection. |
| User starts onboarding, kills app, returns | Resume from last completed step (saved in `profiles.onboarding_step`). |

---

## 15. Error Logging & Monitoring

### 15.1 What to Log (Sentry)

**Always log:**
- Unhandled exceptions (automatic with `sentry_flutter`)
- Supabase errors (4xx and 5xx)
- Edge Function failures
- File upload failures
- Auth failures (not credentials — just the error type)
- Offline sync failures

**Never log:**
- User passwords or tokens
- Personal information (names, addresses, emails)
- Document content or OCR text
- File contents

### 15.2 Error Context

Every logged error should include:

```dart
Sentry.captureException(
  error,
  stackTrace: stackTrace,
  withScope: (scope) {
    scope.setTag('feature', 'document_vault');
    scope.setTag('action', 'upload');
    scope.setTag('subscription_tier', 'free');
    scope.setExtra('file_size_bytes', fileSize);
    scope.setExtra('mime_type', mimeType);
    // NEVER include: user email, document name, file contents
  },
);
```

### 15.3 Error Severity Levels

| Level | When | Alert |
|-------|------|-------|
| **Fatal** | App crash | Sentry alert → immediate |
| **Error** | Feature broken (can't upload, can't sign in) | Sentry alert → within 1 hour |
| **Warning** | Degraded experience (OCR failed, slow load) | Sentry dashboard → review daily |
| **Info** | Expected edge cases (offline, permission denied) | Sentry log → review weekly |

---

## 16. Quick Reference Table

Copy-paste reference for agents building any screen.

### Every Screen Must Have:

| Element | Required | Pattern |
|---------|----------|---------|
| Loading state | ✅ | Skeleton screen matching layout |
| Empty state | ✅ | Motivational (key features) or instructional (simple screens) |
| Error state | ✅ | Snackbar for minor, full-screen for load failure |
| Pull-to-refresh | ✅ (if scrollable list) | Standard RefreshIndicator |
| Offline banner | ✅ | Amber banner when disconnected |

### Error Display Decision Tree

```
Is it a form validation error?
  → YES: Inline error below the field (red text)
  → NO: Continue ↓

Is the entire screen unable to load?
  → YES: Full-screen error with Try Again button
  → NO: Continue ↓

Does the user need to make a decision?
  → YES: Bottom sheet (file too large, upgrade prompt, confirm delete)
  → NO: Continue ↓

Default:
  → Snackbar (4 second auto-dismiss, optional RETRY action)
```

### Error Message Formula

```
[What happened] + [What to do about it]

✅ "Couldn't upload document. Check your connection and try again."
✅ "File is too large (32MB). Maximum size is 25MB."
✅ "Session expired. Please sign in again."

❌ "Error 42501"
❌ "Something went wrong"
❌ "Upload failed"  (missing the "what to do" part)
```

---

## Related Specification Documents

| Document | Relationship |
|----------|-------------|
| **Empty States Catalog** | Extends Section 4 with screen-by-screen empty state specs (25 total). The Catalog is the implementation reference; this guide provides the foundational patterns. |
| **Dashboard State Variations** | Extends Section 5 with Home tab offline behavior. Defines 8 dashboard states including Needs Attention card, greeting subtitles, and hero adaptation. |
| **Dashboard Spec** | Defines the Home tab section layout, urgent banner behavior, and insight triggers that interact with error/empty/loading states. |
| **Notification Priority** | Defines push notification back-off, quiet hours, and delivery status tracking — complements Section 9 (Permission Handling) for notification permission flows. |

---

*End of Error Handling & Edge Case Guide*
*HomeTrack — Version 1.1 — February 2026*
