# HomeTrack - CLAUDE.md

> This file is read by Claude Code at the start of every session. Keep it concise and universally applicable.

## Project Overview

HomeTrack is a home management platform helping homeowners organize documents, track maintenance, monitor property value, and manage home-related tasks.

**Stack:** Flutter (mobile) | Next.js (web) | Supabase (backend) | RevenueCat + Stripe (payments)

**Design System:** Keystona Premium Home Theme
- Primary: #1E3A5F (Deep blue)
- Accent: #D4A574 (Warm gold)
- See: `Keystona_PremiumHome_Theme.md`

## Key Conventions

### Flutter Mobile
- State management: Riverpod with AsyncNotifier
- Offline-first: Local SQLite → Supabase sync
- Feature structure: `lib/features/[feature]/models|providers|screens|widgets`

### Next.js Web  
- App Router with Server Components
- Desktop-optimized layouts
- Structure: `app/(dashboard)/[feature]`

### Supabase
- Always use RLS policies
- Edge Functions for complex logic
- Real-time for collaborative features

### Code Style
- Prefer duplication over premature abstraction
- Simple, clear code over clever code
- Self-documenting names; comments only when non-obvious

## Before You Code

1. Check for existing patterns: `git log --oneline -20`
2. Look for similar features in codebase
3. Reference feature specs in `/mnt/project/`
4. Plan before implementing

## Patterns

<!-- Add patterns discovered during development here -->

### Pattern: Supabase RLS Policy
```sql
ALTER TABLE [table] ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own data" ON [table]
  FOR SELECT USING (user_id = auth.uid());
```

### Pattern: Flutter Feature Structure
```
lib/features/[feature_name]/
├── models/          # Data classes
├── providers/       # Riverpod state
├── screens/         # Full pages
├── widgets/         # UI components
└── services/        # Business logic
```

## Decisions

<!-- Document significant decisions and their rationale here -->

### Decision: Supabase for MVP
**Context:** Needed backend that's fast to develop with  
**Chose:** Supabase over Firebase/custom  
**Reason:** PostgreSQL, built-in auth, familiar to team, clear migration path to AWS  
**Trade-off:** 500MB storage limit requires early R2 migration planning

## Lessons

<!-- Document bugs, failures, and how to prevent them here -->

### Lesson: [Template]
**Symptom:** [What was observed]  
**Root cause:** [Why it happened]  
**Prevention:** [How to avoid in future]

---

## Commands

Custom slash commands live in `.claude/commands/`:
- `/compound` - Extract learnings from completed work
- `/quick-compound` - Fast learnings extraction

## Resources

- Feature Specs: `/mnt/project/*_FeatureSpec.md`
- Technical Architecture: `/mnt/project/HomeTrack_TechnicalArchitecture.md`
- Design System: `/mnt/project/Keystona_*.md`
- Agent Guide: `HomeTrack_Agent_Implementation_Guide.docx`
- Skills Guide: `HomeTrack_Skills_Implementation_Guide.docx`
