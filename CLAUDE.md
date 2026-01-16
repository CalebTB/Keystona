# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Keystona** is a comprehensive home management platform helping homeowners organize documents, track maintenance, monitor property value, and manage home-related tasks.

**Technology Stack:**
- **Mobile**: Flutter (iOS & Android)
- **Web**: Next.js 14+ with App Router
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Payments**: RevenueCat (mobile) + Stripe (web)
- **Analytics**: PostHog
- **External APIs**: ATTOM (property data), Google Cloud Vision (OCR), OpenWeatherMap (weather alerts)

## Repository Structure

This is a **planning and specification repository**. The actual implementation will be in separate repositories:
- `hometrack-mobile/` - Flutter mobile app
- `hometrack-web/` - Next.js web app
- `hometrack-supabase/` - Supabase migrations and Edge Functions

This repository contains:
- Feature specifications (`*_FeatureSpec.md`)
- Technical architecture ([Keystona_TechnicalArchitecture.md](Keystona_TechnicalArchitecture.md))
- Wireframes (`.html` files)
- Agent definitions (`.claude/agents/`)
- Development guides

## Core Architecture Principles

### Multi-Platform Strategy
- **Mobile and web share the same backend** but have independent frontends
- Mobile is optimized for on-the-go access and offline capabilities
- Web is optimized for desktop workflows and bulk operations
- Both platforms sync through Supabase real-time

### Offline-First Design
- **Emergency Hub must work without internet** - uses SQLite for local persistence
- Other features support offline mode with background sync
- Always show sync status indicators to users

### Security-First Database
- **Every table must have Row Level Security (RLS) enabled**
- Users can only access their own data via `auth.uid()` checks
- Use signed URLs with expiration for file access
- Never store payment information (handled by RevenueCat/Stripe)

### Scalable Storage Strategy
- **Phase 1 (0-10K users)**: Supabase Storage
- **Phase 2 (10K-100K users)**: Migrate to Cloudflare R2 (zero egress fees)
- **Phase 3 (100K+ users)**: Multi-tier storage (R2 hot + Backblaze B2 cold)

## Development Workflow

### When Implementing Features

1. **Read the feature spec first** - All features have detailed specs in `*_FeatureSpec.md`
2. **Reference the technical architecture** - See [Keystona_TechnicalArchitecture.md](Keystona_TechnicalArchitecture.md)
3. **Use specialized agents** - See `.claude/agents/` for agent definitions:
   - `flutter-ui-builder` - Mobile UI components
   - `nextjs-web-builder` - Web pages and components
   - `supabase-backend-architect` - Database schema and RLS
   - `api-integration-specialist` - External API connections
   - `document-processor` - File upload and OCR pipelines
   - `notification-scheduler` - Reminders and alerts
   - `testing-qa-agent` - Test generation
   - `devops-cicd-orchestrator` - Deployment pipelines

4. **Follow the design system** - Keystona Premium Home Theme:
   - Primary: Deep Blue (#1E3A5F)
   - Accent: Warm Gold (#D4A574)
   - Spacing: 4px base unit (4, 8, 12, 16, 24, 32, 48)
   - Border radius: 8px standard, 12px cards, 16px modals

### Code Organization Patterns

#### Flutter (Mobile)
```
lib/
  features/
    feature_name/
      models/          # Data classes
      providers/       # Riverpod state management
      screens/         # Full page views
      widgets/         # Reusable components
      services/        # Business logic
```

**State Management:** Use Riverpod with AsyncNotifier for complex state, FutureProvider for async data loading.

#### Next.js (Web)
```
app/
  (dashboard)/
    feature_name/
      page.tsx        # Route pages
      [id]/page.tsx   # Dynamic routes
  api/
    feature_name/     # API routes
components/
  ui/                 # Base components
  features/           # Feature-specific components
```

**Conventions:** Server Components by default, Client Components only when needed (interactivity, hooks).

#### Supabase
```
supabase/
  migrations/         # SQL migration files
  functions/          # Edge Functions (Deno)
    function-name/
      index.ts
```

## Common Commands

### Flutter Development
```bash
# Setup and development
flutter pub get                    # Install dependencies
flutter run                        # Run on connected device
flutter analyze                    # Static analysis
flutter test                       # Run unit tests

# Building
flutter build apk --release        # Android APK
flutter build appbundle            # Android App Bundle (for Play Store)
flutter build ios --release        # iOS build
```

### Next.js Development
```bash
# Development
npm install                        # Install dependencies
npm run dev                        # Start dev server (localhost:3000)
npm run build                      # Production build
npm run lint                       # ESLint check
npm run type-check                 # TypeScript validation
```

### Supabase Development
```bash
# Local development
npx supabase start                 # Start local Supabase instance
npx supabase stop                  # Stop local instance
npx supabase status                # Show URLs and keys

# Database operations
npx supabase db reset              # Reset to clean state
npx supabase db push               # Push migrations to remote
npx supabase db pull               # Pull remote schema
npx supabase migration new <name>  # Create new migration
npx supabase db diff               # Generate migration from changes

# Edge Functions
npx supabase functions serve       # Run functions locally
npx supabase functions deploy      # Deploy all functions
```

## Critical Implementation Patterns

### Pattern: Supabase Row Level Security
Every table must have RLS enabled with policies restricting access to the user's own data.

```sql
-- Enable RLS on table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can only see their own documents
CREATE POLICY "Users see own documents" ON documents
  FOR SELECT USING (
    property_id IN (
      SELECT id FROM properties WHERE user_id = auth.uid()
    )
  );

-- Users can only insert their own documents
CREATE POLICY "Users insert own documents" ON documents
  FOR INSERT WITH CHECK (
    property_id IN (
      SELECT id FROM properties WHERE user_id = auth.uid()
    )
  );
```

### Pattern: Flutter Offline-First Data
For Emergency Hub and critical features, always implement local persistence with background sync.

```dart
// 1. Define local and remote data sources
class EmergencyRepository {
  final LocalDatabase _local;
  final SupabaseClient _remote;

  Future<List<Emergency>> getEmergencies() async {
    // Try local first
    final localData = await _local.getEmergencies();

    // Attempt background sync if online
    _syncInBackground();

    return localData;
  }

  Future<void> _syncInBackground() async {
    if (await _hasConnection()) {
      final remoteData = await _remote.from('emergency_info').select();
      await _local.updateEmergencies(remoteData);
    }
  }
}
```

### Pattern: Next.js Server Actions with Supabase
Use Server Actions for mutations that require server-side validation or security.

```typescript
// app/actions/documents.ts
'use server'

import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function deleteDocument(documentId: string) {
  const supabase = createClient()

  // Supabase RLS will enforce authorization
  const { error } = await supabase
    .from('documents')
    .delete()
    .eq('id', documentId)

  if (error) throw error

  revalidatePath('/documents')
}
```

### Pattern: External API Integration with Caching
Always cache external API responses to minimize costs and improve performance.

```typescript
// Edge Function example
import { createClient } from '@supabase/supabase-js'

export async function getHomeValue(address: string) {
  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

  // Check cache first (24 hour TTL for home values)
  const { data: cached } = await supabase
    .from('api_cache')
    .select('value')
    .eq('key', `attom:value:${address}`)
    .gte('cached_at', new Date(Date.now() - 24*60*60*1000))
    .single()

  if (cached) return cached.value

  // Fetch from ATTOM API
  const response = await fetch(ATTOM_API_URL, {
    headers: { 'apikey': ATTOM_API_KEY }
  })
  const value = await response.json()

  // Store in cache
  await supabase.from('api_cache').upsert({
    key: `attom:value:${address}`,
    value,
    cached_at: new Date()
  })

  return value
}
```

## Key Architectural Decisions

### Decision: Supabase for MVP Backend
**Context:** Needed a backend that enables rapid development while maintaining a clear migration path to AWS at scale.

**Chosen:** Supabase (PostgreSQL + Auth + Storage + Functions)

**Rationale:**
- Built on PostgreSQL (industry standard, easy to migrate)
- Integrated authentication with RLS support
- Generous free tier, predictable pricing
- Edge Functions for serverless compute
- Real-time subscriptions for cross-device sync

**Trade-offs:**
- Storage limited to 100GB on Pro plan (requires R2 migration at ~10K users)
- Connection pool limits (requires RDS migration at ~200K users)
- Vendor dependency (mitigated by PostgreSQL standard and export tools)

### Decision: Separate Mobile and Web Codebases
**Context:** Need both mobile apps and a web dashboard.

**Chosen:** Flutter for mobile, Next.js for web (separate codebases sharing same API)

**Rationale:**
- Mobile and web have fundamentally different UX requirements
- Flutter excels at mobile but web experience is suboptimal
- Next.js provides superior web experience with SEO and server-side rendering
- Shared Supabase backend keeps business logic consistent

**Trade-offs:**
- Code duplication for UI components (mitigated by shared design system)
- Need to maintain two frontends (accepted for better UX)

### Decision: RevenueCat for Multi-Platform Payments
**Context:** Need to handle App Store, Play Store, and web payments with a single source of truth.

**Chosen:** RevenueCat + Stripe

**Rationale:**
- RevenueCat abstracts App Store and Play Store complexities
- Handles receipt validation, webhooks, and subscription status
- Single API for checking subscription state across platforms
- Stripe integration for web payments

**Trade-offs:**
- Additional service dependency (accepted for significantly reduced complexity)
- Small per-transaction fee (worth it for time saved)

## Testing Strategy

### Unit Tests
- **Flutter**: Write widget tests for all custom components
- **Next.js**: Test utility functions and API routes with Jest
- **Supabase**: Test RLS policies with `SET ROLE` queries

### Integration Tests
- **Critical flows**: Document upload → OCR → categorization
- **Payment flows**: Subscription purchase → webhook → entitlement grant
- **Offline scenarios**: Emergency Hub data availability without network

### Before Production Deployment
- [ ] All RLS policies tested and verified
- [ ] Offline Emergency Hub functionality confirmed
- [ ] Payment webhooks tested in sandbox
- [ ] Analytics events instrumented and validated
- [ ] Error tracking (Sentry) configured
- [ ] Performance monitoring enabled (PostHog)

## Feature-Specific Notes

### Document Vault
- OCR processing via Google Cloud Vision in Edge Function
- Category detection using keyword matching
- Expiration date extraction with regex patterns
- Full-text search on `ocr_text` column using PostgreSQL `to_tsvector`

### Maintenance Calendar
- Climate-based scheduling uses ZIP code → climate zone mapping
- Recurrence patterns stored as JSON: `{ frequency: 'monthly', interval: 6 }`
- Home Health Score calculated from overdue tasks percentage

### Emergency Hub
- **MUST work offline** - uses SQLite with Supabase sync
- High-contrast mode for emergency situations
- Photo compression to max 500KB per image
- One-tap calling for emergency contacts

### Home Value Tracking
- ATTOM API calls cached for 24 hours
- Equity calculation: `currentValue - mortgageBalance`
- Historical tracking stored in `home_value_history` table
- Monthly email notifications for >1% value changes

## Resource Files

For detailed information, refer to:
- [Keystona_TechnicalArchitecture.md](Keystona_TechnicalArchitecture.md) - Complete technical architecture
- [DocumentVault_FeatureSpec.md](DocumentVault_FeatureSpec.md) - Document management feature
- [MaintenanceCalendar_FeatureSpec.md](MaintenanceCalendar_FeatureSpec.md) - Maintenance scheduling
- [EmergencyHub_FeatureSpec.md](EmergencyHub_FeatureSpec.md) - Emergency information (offline-first)
- [HomeValueTracking_FeatureSpec.md](HomeValueTracking_FeatureSpec.md) - Property valuation tracking
- [HomeProfile_FeatureSpec.md](HomeProfile_FeatureSpec.md) - Home profile management
- [Keystona_Agent_Quick_Reference.md](Keystona_Agent_Quick_Reference.md) - Agent usage guide

## Custom Claude Code Commands

This repository includes custom slash commands in `.claude/skills/`:
- `/compound` - Extract and document patterns, decisions, and lessons from completed work
- `/quick-compound` - Fast learnings extraction for quick iterations
