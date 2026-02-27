# HomeTrack — Notification & Urgency Priority System

**Version:** 1.0  
**Date:** February 23, 2026  
**Status:** Active — Living Document  
**Author:** Caleb (Founder & Product Owner)  
**Cross-references:** Dashboard Spec (Section 4.5, Section 9), SRS (Section 3.3.3, 6.6), Sprint Plan (Phase 7), Database Schema (Migration 009), API Contract (Section 12, 14)

---

## 1. Overview

The notification system is Keystona's outreach arm — it brings users back to the app when their home needs attention. It must be useful without being annoying. The core philosophy: **one push notification per day maximum** for routine items, with exceptions only for truly urgent situations.

### 1.1 Design Principles

- **Respect the user's attention.** One push per day max for non-urgent items. Batch everything into a daily digest.
- **Urgent means urgent.** Only items with real consequences (overdue tasks, expiring insurance) break the daily limit.
- **Back off when ignored.** If a user ignores 3 consecutive reminders for an item, stop sending for that item.
- **User is in control.** Per-category toggles, per-task silencing, and quiet hours give granular control.
- **Local time always.** Every notification is scheduled and delivered in the user's local timezone. Never UTC.

### 1.2 Notification Channels

| Channel | Description | Use Case |
|---------|-------------|----------|
| **Push** | Firebase Cloud Messaging to device | Primary delivery for time-sensitive reminders |
| **In-app inbox** | Notification log visible in the app | All notifications are logged here regardless of push delivery |
| **In-app banner** | Contextual banner on the dashboard | Urgent items surfaced via the Needs Attention card and Urgent Banner (see Dashboard Spec) |

Every notification is written to the in-app inbox. Push delivery is additive — it's a tap on the shoulder that points the user to the inbox and the relevant screen.

---

## 2. Notification Categories

### 2.1 Category Inventory

| Category | ID | Examples | Default Enabled | Configurable |
|----------|----|---------|-----------------|-------------|
| Maintenance Reminders | `maintenance` | "HVAC filter due in 7 days", "Gutter cleaning due tomorrow" | Yes | Yes — per-category + per-task |
| Overdue Alerts | `overdue` | "HVAC filter is 1 day overdue", "3 tasks overdue" | Yes | Yes — per-category only (cannot disable per-task — overdue is critical) |
| Expiration Alerts | `expiration` | "Insurance expires in 30 days", "Warranty expires in 7 days" | Yes | Yes — per-category + per-document |
| System Updates | `system` | "Welcome to Keystona", "New feature available" | Yes | Yes — per-category only |
| Trial & Billing | `billing` | "Trial ends in 5 days", "Payment failed" | Yes | No — always delivered (required for billing) |
| Weather Alerts (v1.5) | `weather` | "Freeze warning — protect pipes", "Storm approaching" | Yes | Yes — per-category only |

### 2.2 User Controls

Users configure notifications in **Settings → Notifications**:

**Global controls:**
- Master toggle: Enable/disable all push notifications
- Quiet hours: Start time + end time (default: 10:00 PM – 8:00 AM)

**Per-category controls:**
- Each category has an on/off toggle
- Toggling a category off stops push delivery for that category but items still appear in the in-app inbox

**Per-task/per-document controls:**
- On any task detail screen: "Mute notifications for this task" toggle
- On any document detail screen: "Mute expiration reminders for this document" toggle
- Muting a specific item stops push notifications for that item only; the item still appears in the in-app inbox and on the dashboard

**What cannot be disabled:**
- Trial & billing notifications (required for subscription management)
- In-app inbox entries (always logged regardless of push settings)
- Dashboard indicators (Needs Attention card, Urgent Banner) — these are UI elements, not notifications

---

## 3. Notification Priority Tiers

Every notification event is classified into one of three priority tiers. The tier determines delivery timing and whether it can break the daily push limit.

### 3.1 Tier Definitions

| Tier | Name | Daily Limit Behavior | Delivery Timing | Examples |
|------|------|---------------------|-----------------|---------|
| **P1** | Urgent | **Breaks daily limit** — delivered immediately regardless of whether a digest was already sent | Immediately during waking hours. If during quiet hours, delivered at quiet hours end (next morning). | Task 1 day overdue, insurance expiring in 7 days, payment failed |
| **P2** | Important | Included in daily digest. If no digest scheduled today, triggers one. | User's preferred time (default: Saturday 9 AM). | Task due in 7 days, document expiring in 30 days, task due tomorrow |
| **P3** | Informational | Included in daily digest only if one is already being sent. Otherwise, in-app inbox only. | Next scheduled digest, or in-app only. | "Great week — 5 tasks completed", system update, new feature announcement |

### 3.2 Priority Classification Rules

| Event | Tier | Rationale |
|-------|------|-----------|
| Task 1 day overdue | P1 | Immediate consequence — user missed the deadline yesterday |
| Task 7 days overdue | P1 | Persistent neglect — needs immediate attention |
| Insurance expiring in 7 days | P1 | Coverage gap risk is imminent |
| Payment failed | P1 | Service interruption risk |
| Trial ending in 2 days | P1 | Conversion-critical moment |
| Task due tomorrow | P2 | Actionable reminder with lead time |
| Task due in 7 days | P2 | Advance planning reminder |
| Document expiring in 30 days | P2 | Plenty of time but worth flagging |
| Document expiring in 90 days | P3 | Very early warning — informational only |
| Trial ending in 5 days | P2 | Important but not yet critical |
| Weekly completion summary | P3 | Celebration — nice to have, not urgent |
| New feature announcement | P3 | Informational only |
| Onboarding nudge (setup incomplete after 7 days) | P2 | Re-engagement |

---

## 4. Daily Digest System

### 4.1 How It Works

The daily digest batches all non-urgent (P2 + P3) notifications into a single push notification delivered at the user's preferred time.

**Digest assembly (runs daily at user's preferred time):**

```
1. Query all pending P2 and P3 notifications for the user since last digest
2. If 0 pending items → no digest sent
3. If 1 pending item → send as individual notification (not a digest)
4. If 2+ pending items → batch into digest format
5. All items are logged to in-app inbox individually (not batched)
6. Mark all items as "digest_sent" to prevent re-inclusion
```

### 4.2 Digest Push Format

**Single item (no batching needed):**
```
Title: "HVAC filter change due tomorrow"
Body: "Tap to view details and mark complete."
```

**Multiple items (digest):**
```
Title: "You have 3 items to review"
Body: "HVAC filter due tomorrow · Insurance expires in 28 days · Gutter cleaning due in 5 days"
Tap action: Opens in-app notification inbox
```

**Digest body rules:**
- List up to 3 items in the body, sorted by priority tier then urgency score
- If more than 3 items, show the top 3 and append: "+ 2 more"
- Each item is a brief summary (task name + timing), separated by " · "
- Body text is capped at 150 characters (iOS push notification best practice)

### 4.3 Preferred Time

- **Default:** Saturday at 9:00 AM local time
- **Configurable:** User can set any day of the week + time in Settings → Notifications
- **"Any day" option:** User can choose "Daily" instead of a specific day. When set to daily, the digest runs every morning at the preferred time.
- **Quiet hours interaction:** If the preferred time falls within quiet hours (shouldn't happen by default, but possible if user misconfigures), the digest is delayed to quiet hours end.

### 4.4 Why Saturday 9 AM Default

Home maintenance is weekend work for most homeowners. Saturday morning gives the user time to plan and act on tasks during the weekend. This aligns with SRS requirement MC-015 ("Configurable notification timing, default: weekends 9–10 AM").

---

## 5. Urgent (P1) Notification Delivery

### 5.1 Immediate Delivery Rules

P1 notifications break the daily digest limit and are delivered as individual push notifications immediately — with one exception: quiet hours.

```
IF user.quiet_hours_enabled AND current_time BETWEEN quiet_hours_start AND quiet_hours_end:
    queue for delivery at quiet_hours_end
ELSE:
    deliver immediately via FCM
```

### 5.2 P1 Rate Limiting

Even P1 notifications have a safety valve to prevent notification storms:

- **Max 3 P1 push notifications per day.** If a 4th P1 event occurs, it goes to the in-app inbox only.
- **Minimum 1-hour gap between P1 pushes.** If two P1 events happen within an hour, the second is queued for 1 hour after the first.
- These limits prevent edge cases like a user with 10 overdue tasks getting 10 immediate pushes.

### 5.3 P1 Notification Formats

**Task overdue (1 day):**
```
Title: "⚠ HVAC filter change is overdue"
Body: "Due yesterday. Tap to complete or reschedule."
Tap action: Opens task detail screen
```

**Task overdue (7+ days):**
```
Title: "⚠ HVAC filter change is 7 days overdue"
Body: "Staying on top of maintenance protects your home. Tap to resolve."
Tap action: Opens task detail screen
```

**Insurance expiring (7 days):**
```
Title: "⚠ Insurance expires in 7 days"
Body: "Your homeowner's policy expires Feb 28. Renew to avoid a coverage gap."
Tap action: Opens document detail screen
```

**Payment failed:**
```
Title: "Payment failed — update your method"
Body: "We couldn't process your Premium subscription. Update payment to keep your features."
Tap action: Opens subscription management screen
```

---

## 6. Notification Schedule

This table defines every notification event, when it fires, and its tier.

### 6.1 Maintenance Task Lifecycle

| Event | When It Fires | Tier | Push Text (Title) |
|-------|--------------|------|-------------------|
| Task due in 7 days | 7 days before due date | P2 | "[Task name] due in 7 days" |
| Task due tomorrow | 1 day before due date | P2 | "[Task name] due tomorrow" |
| Task overdue (1 day) | 1 day after due date | P1 | "⚠ [Task name] is overdue" |
| Task overdue (7 days) | 7 days after due date | P1 | "⚠ [Task name] is 7 days overdue" |
| Task overdue (repeated) | Every 7 days after initial overdue | P2 | "[Task name] is still overdue ([X] days)" |

**After the 1-day and 7-day overdue P1 notifications, subsequent reminders drop to P2** and are included in the daily digest. This prevents overdue tasks from generating unlimited P1 pushes.

### 6.2 Document Expiration Lifecycle

| Event | When It Fires | Tier | Push Text (Title) |
|-------|--------------|------|-------------------|
| Expiring in 90 days | 90 days before expiration | P3 | "[Document] expires in 90 days" |
| Expiring in 30 days | 30 days before expiration | P2 | "[Document] expires in 30 days" |
| Expiring in 7 days | 7 days before expiration | P1 | "⚠ [Document] expires in 7 days" |
| Expired | Day of expiration | P1 | "⚠ [Document] has expired" |

**Only homeowner's insurance triggers the "expired" P1 notification.** Other document types stop at the 7-day reminder (P2 level) since their expiration has lower real-world consequence.

### 6.3 Trial & Billing Lifecycle

| Event | When It Fires | Tier | Push Text (Title) |
|-------|--------------|------|-------------------|
| Trial ending in 5 days | Day 25 of 30-day trial | P2 | "Trial ends in 5 days" |
| Trial ending in 2 days | Day 28 | P1 | "⚠ Trial ends in 2 days" |
| Trial ended | Day 30 | P1 | "Your trial has ended" |
| Grace period reminder | Day 37 (7 days post-trial) | P2 | "Upgrade to keep your features" |
| Grace period ending | Day 42 | P2 | "Features will be limited in 3 days" |
| Grace period final | Day 44 | P1 | "⚠ Premium features locked tomorrow" |
| Payment failed | On failed charge | P1 | "⚠ Payment failed" |

### 6.4 Onboarding & Re-engagement

| Event | When It Fires | Tier | Push Text (Title) |
|-------|--------------|------|-------------------|
| Setup incomplete (7 days) | 7 days after signup, checklist not done | P2 | "Finish setting up your home" |
| Setup incomplete (14 days) | 14 days after signup | P2 | "Your home profile is waiting" |
| Inactive 14 days | No app open in 14 days | P2 | "Check in on your home" |
| Inactive 30 days | No app open in 30 days | P2 | "[X] tasks may need your attention" |

---

## 7. Back-Off System

### 7.1 Rules

When a user receives push notifications for a specific item and doesn't take action (doesn't open the app from the notification AND doesn't resolve the item), the system reduces and eventually stops notifications for that item.

```
Attempt 1: Normal delivery (per schedule)
Attempt 2: Normal delivery (per schedule)
Attempt 3: Normal delivery (per schedule) + flag as "final reminder"
Attempt 4+: STOP push notifications for this item
```

**"Ignored" definition:** A notification is considered ignored if:
- The user did not tap the push notification (tracked via FCM click-through), AND
- The item remains unresolved (task still overdue, document still expiring) at the time of the next scheduled reminder

### 7.2 Back-Off Scope

- Back-off is **per-item, per-notification-type.** If the user ignores 3 "HVAC filter overdue" reminders, the system stops sending pushes for that specific task. Other tasks still send normally.
- Back-off does NOT affect the in-app inbox. The item still appears in the inbox and on the dashboard (Needs Attention card, Urgent Banner). Only push delivery stops.
- Back-off does NOT affect other notification types for the same item. If a task triggers both a "due in 7 days" and an "overdue" notification, they have separate back-off counters.

### 7.3 Back-Off Reset

The back-off counter resets when:
- The user taps a notification for that item (signals re-engagement)
- The user takes any action on the item in the app (opens detail screen, completes, skips, dismisses)
- The user changes notification preferences (global or per-category toggle)

### 7.4 Back-Off and P1

P1 notifications are subject to back-off. If a user ignores 3 consecutive P1 pushes for the same overdue task, push delivery stops for that task. This prevents the system from endlessly pinging a user who has clearly chosen to ignore an issue. The item remains visible in the app (Needs Attention card is not dismissible), but the push channel goes quiet.

---

## 8. Notification Priority Score

When building the daily digest or determining which P1 notification to send first, the system ranks items using a priority score. This is the same formula used by the dashboard Urgent Banner (see Dashboard Spec Section 9):

```
priority_score = (days_overdue × 2) + (estimated_cost_impact / 100)
```

For non-overdue items (upcoming reminders, expiration alerts), `days_overdue` is replaced with an inverse of `days_until_due`:

```
For upcoming items:
  urgency_factor = max(0, 30 - days_until_due)

priority_score = (urgency_factor × 2) + (estimated_cost_impact / 100)
```

This means:
- An item due tomorrow has urgency_factor = 29 → score ≈ 58
- An item due in 7 days has urgency_factor = 23 → score ≈ 46
- An item due in 30 days has urgency_factor = 0 → score = cost_impact / 100
- An overdue item uses the existing formula (higher scores = more urgent)

### 8.1 Digest Ordering

Items in the daily digest are sorted by priority_score descending. The top 3 are shown in the push notification body; the rest appear only in the in-app inbox.

---

## 9. Quiet Hours

### 9.1 Default Configuration

- **Start:** 10:00 PM local time
- **End:** 8:00 AM local time
- **Configurable:** Yes, in Settings → Notifications

### 9.2 Behavior During Quiet Hours

| Notification Tier | Behavior |
|-------------------|----------|
| P1 (Urgent) | Queued, delivered at quiet hours end |
| P2 (Important) | Included in next digest (which runs at preferred time, outside quiet hours) |
| P3 (Informational) | Included in next digest or in-app inbox only |

**No push notifications of any tier are delivered during quiet hours.** P1 items are queued and delivered the moment quiet hours end. If multiple P1 items queue during the night, they are delivered with the 1-hour minimum gap rule (Section 5.2), starting from quiet hours end.

### 9.3 Timezone Handling

- All notification scheduling uses the user's **local timezone** stored in their profile.
- The cron functions (`check-expirations`, `check-overdue-tasks`) run in UTC but calculate delivery times per-user based on their stored timezone.
- If a user's timezone is unknown (not set during onboarding), default to the timezone of their property's ZIP code.

---

## 10. In-App Notification Inbox

### 10.1 Purpose

The inbox is the complete record of all notification events, regardless of whether they were delivered as push. It serves as a secondary access point for items the user may have missed.

### 10.2 Inbox Behavior

- **Every notification event** creates an entry in the inbox (push delivered or not).
- Entries show: icon, title, body, timestamp, and read/unread status.
- Tapping an entry navigates to the relevant screen (task detail, document detail, etc.) and marks it as read.
- Entries are sorted by timestamp descending (newest first).
- **Unread badge:** The notification bell icon in the app (accessible from the Home tab header or Settings) shows a red badge with the unread count.

### 10.3 Retention

- Inbox entries are retained for **90 days**, then automatically deleted.
- Read entries can be manually deleted by the user (swipe to delete).
- Unread entries cannot be deleted until marked as read (prevents accidental dismissal).

### 10.4 Digest Expansion

When a user taps a digest push notification ("You have 3 items to review"), it opens the in-app inbox showing all individual items from that digest. The items are logged individually, not as a single batched entry.

---

## 11. Notification-to-Dashboard Connection

The notification system and the dashboard urgency indicators are connected but independent:

| Component | Source | Affected by Notification Preferences? |
|-----------|--------|--------------------------------------|
| **Needs Attention Card** | Direct database query (overdue tasks) | **No** — always shows when overdue items exist, regardless of notification settings |
| **Urgent Banner** | Direct database query (expiring docs, incomplete emergency) | **No** — always shows based on data conditions |
| **Insights** | Rule engine evaluation | **No** — always shows based on conditions |
| **Push notifications** | Cron functions + FCM | **Yes** — respects all user preferences, quiet hours, and back-off |
| **In-app inbox** | Notification log table | **Partially** — entries are always created, but marked as "push_skipped" if the user has disabled push for that category |

**The dashboard never hides urgency just because the user turned off push notifications.** Push is an outreach channel; the dashboard is the source of truth. A user who disables all push notifications will still see the Needs Attention card, Urgent Banner, and Insights when they open the app.

---

## 12. Edge Function Specifications

### 12.1 check-overdue-tasks (Cron — Daily at 9:00 AM UTC)

```
For each user with overdue tasks:
  1. Query maintenance_tasks WHERE status = 'overdue' AND property.user_id = user
  2. For each overdue task:
     a. Calculate days_overdue
     b. Determine notification event:
        - 1 day overdue → P1 "task overdue" (if not already sent)
        - 7 days overdue → P1 "task 7 days overdue" (if not already sent)
        - 14, 21, 28... days → P2 "task still overdue" (weekly cadence)
     c. Check back-off counter for this task+event combo
        - If counter ≥ 3 → skip push, log to inbox as "push_backed_off"
     d. Check user notification preferences
        - If overdue category disabled → skip push, log to inbox as "push_disabled"
        - If task individually muted → skip push, log to inbox as "push_muted"
     e. Classify tier and queue for delivery
  3. For P1 items: queue for immediate delivery (or quiet hours end)
  4. For P2 items: add to pending digest pool
```

### 12.2 check-expirations (Cron — Daily at 9:00 AM UTC)

```
For each user with expiring documents:
  1. Query documents WHERE expiration_date IS NOT NULL AND property.user_id = user
  2. For each document:
     a. Calculate days_until_expiration
     b. Determine notification event:
        - 90 days → P3
        - 30 days → P2
        - 7 days → P1 (insurance only; P2 for other doc types)
        - 0 days (expired) → P1 (insurance only)
     c. Check back-off, preferences, muting (same as overdue flow)
     d. Classify and queue
```

### 12.3 send-daily-digest (Cron — Per User at Preferred Time)

```
For the target user:
  1. Query pending P2 and P3 notifications since last digest
  2. If 0 items → exit (no digest)
  3. Sort by priority_score descending
  4. If 1 item → send as individual push notification
  5. If 2+ items → compose digest:
     a. Title: "You have [X] items to review"
     b. Body: Top 3 items summarized, separated by " · "
     c. If >3 items, append "+ [X] more"
  6. Deliver via FCM
  7. Mark all items as "digest_sent"
  8. Log digest delivery to notification_log
```

**Implementation note:** Running per-user cron at individual preferred times requires either a queue-based system or a single cron that checks which users need digests at the current hour. The recommended approach is a single cron running every hour that queries users whose `preferred_time` matches the current hour in their local timezone.

---

## 13. Database Updates Needed

### 13.1 notification_log Table Additions

The existing schema (Migration 009) needs additional columns:

```sql
ALTER TABLE notification_log ADD COLUMN tier TEXT NOT NULL DEFAULT 'p2';  -- 'p1', 'p2', 'p3'
ALTER TABLE notification_log ADD COLUMN delivery_status TEXT NOT NULL DEFAULT 'pending';
  -- 'pending', 'sent', 'digest_sent', 'push_skipped', 'push_disabled', 'push_muted', 'push_backed_off', 'queued_quiet_hours'
ALTER TABLE notification_log ADD COLUMN back_off_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE notification_log ADD COLUMN clicked_at TIMESTAMPTZ;  -- FCM click-through tracking
ALTER TABLE notification_log ADD COLUMN digest_id UUID;  -- groups items delivered in same digest
```

### 13.2 New Table: notification_back_off

```sql
CREATE TABLE notification_back_off (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reference_type  TEXT NOT NULL,       -- 'task', 'document'
  reference_id    UUID NOT NULL,       -- task_id or document_id
  event_type      TEXT NOT NULL,       -- 'overdue_1d', 'overdue_7d', 'expiring_30d', etc.
  consecutive_ignored INTEGER NOT NULL DEFAULT 0,
  last_sent_at    TIMESTAMPTZ,
  backed_off      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_back_off_unique 
  ON notification_back_off(user_id, reference_type, reference_id, event_type);
```

### 13.3 notification_preferences Table Addition

```sql
ALTER TABLE notification_preferences ADD COLUMN preferred_frequency TEXT DEFAULT 'weekly';
  -- 'daily' or 'weekly'
  -- 'daily' = digest runs every day at preferred_time
  -- 'weekly' = digest runs on preferred_day at preferred_time
```

### 13.4 New Table: task_notification_mutes

```sql
CREATE TABLE task_notification_mutes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  task_id     UUID NOT NULL REFERENCES maintenance_tasks(id) ON DELETE CASCADE,
  muted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_task_mute_unique ON task_notification_mutes(user_id, task_id);

-- Similar table for document mutes
CREATE TABLE document_notification_mutes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  muted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_doc_mute_unique ON document_notification_mutes(user_id, document_id);
```

---

## 14. Complete Notification Flow Diagram

```
           Event Detected
        (cron or real-time)
                │
                ▼
    ┌───────────────────────┐
    │ Classify Priority Tier │
    │   P1 / P2 / P3        │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │ Check User Preferences │──── Category disabled? ──→ Log to inbox as "push_disabled"
    │                        │
    │                        │──── Item muted? ──→ Log to inbox as "push_muted"
    └───────────┬───────────┘
                │ (enabled)
                ▼
    ┌───────────────────────┐
    │ Check Back-Off Counter │──── ≥3 ignored? ──→ Log to inbox as "push_backed_off"
    └───────────┬───────────┘
                │ (<3)
                ▼
        ┌───────┴───────┐
        │               │
     P1 (Urgent)    P2/P3 (Normal)
        │               │
        ▼               ▼
  ┌──────────┐   ┌──────────────┐
  │ Quiet    │   │ Add to       │
  │ hours?   │   │ digest pool  │
  │          │   └──────┬───────┘
  │ Yes: queue│         │
  │ No: send │         ▼
  │ now      │   ┌──────────────┐
  └──────────┘   │ At preferred │
                 │ time: build  │
                 │ & send digest│
                 └──────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Log to in-app    │
              │ inbox + update   │
              │ back-off counter │
              └──────────────────┘
```

---

## 15. Implementation Checklist

- [ ] FCM integration delivering push notifications on iOS and Android
- [ ] `check-overdue-tasks` cron classifies overdue tasks into P1/P2 tiers correctly
- [ ] `check-expirations` cron classifies expiring documents into P1/P2/P3 tiers correctly
- [ ] Daily digest assembles correctly (1 item = individual, 2+ = batched)
- [ ] Digest runs at user's preferred time in their local timezone
- [ ] P1 notifications deliver immediately outside quiet hours
- [ ] P1 notifications queue during quiet hours and deliver at quiet hours end
- [ ] P1 rate limit: max 3 per day, minimum 1-hour gap
- [ ] Back-off counter tracks per-item, per-event-type
- [ ] Back-off stops push after 3 consecutive ignores
- [ ] Back-off resets on user interaction with the item
- [ ] Per-category toggles work in Settings
- [ ] Per-task mute toggle works on task detail screen
- [ ] Per-document mute toggle works on document detail screen
- [ ] Quiet hours prevent all push delivery during the window
- [ ] In-app inbox logs every notification event regardless of push delivery
- [ ] Inbox entries are tappable and navigate to the relevant screen
- [ ] Unread badge count displays correctly
- [ ] Inbox entries auto-delete after 90 days
- [ ] Dashboard Needs Attention card and Urgent Banner are independent of notification preferences
- [ ] Trial/billing notifications always deliver (cannot be disabled)
- [ ] All timestamps use user's local timezone

---

## 16. Cross-References

| Topic | Document | Section |
|-------|----------|---------|
| Dashboard Urgent Banner (same priority formula) | Dashboard Spec | Sections 4.5, 9 |
| Dashboard Needs Attention Card | Dashboard States | Section 3.5, 7 |
| Notification database schema | Database Schema | Migration 009 |
| Push notification Edge Functions | API Contract | Section 14 |
| Notification preferences table | Database Schema | Migration 009 |
| Cron job scheduling | API Contract | Section 14.1 |
| SRS notification requirements | SRS | Sections 3.3.3, 6.6 |
| Sprint Plan notification phase | Sprint Plan | Phase 7 |
| Task overdue resolution flow | Dashboard Spec | Section 6.4 |
| Document expiration reminders | SRS | Section 3.1.4 |

---

*End of Notification & Urgency Priority System*  
*HomeTrack (Keystona) — Version 1.0 — February 2026*
