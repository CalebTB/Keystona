# HomeTrack Agent Quick Reference

> Fast lookup for agent prompts, commands, and patterns

---

## 🎯 Agent Selection Matrix

| I need to... | Use this agent | Key prompt starter |
|--------------|----------------|-------------------|
| Build a mobile screen | **Flutter UI Agent** | "Create a Flutter screen/widget for..." |
| Build a web page | **Next.js Web Agent** | "Build a Next.js page/component for..." |
| Create database tables | **Supabase Backend Agent** | "Design a database schema for..." |
| Connect an external API | **API Integration Agent** | "Integrate [service] API to..." |
| Process uploaded files | **Document Processing Agent** | "Create a pipeline that..." |
| Set up reminders/alerts | **Notification Agent** | "Build a notification system for..." |
| Write tests | **Testing & QA Agent** | "Generate tests for..." |
| Deploy code | **DevOps Agent** | "Set up CI/CD workflow for..." |
| Track user behavior | **Analytics Agent** | "Implement event tracking for..." |
| Write documentation | **Documentation Agent** | "Create a spec/ADR/guide for..." |

---

## 🚀 Starter Prompts by Feature

### Document Vault
```
Flutter UI: "Create the Document Vault list screen with category filters, 
search bar, and document cards. Use Keystona design system and Riverpod."

Backend: "Design the documents table with columns for file metadata, 
OCR text, category, expiration, and user relationship. Add RLS policies."

Processing: "Build the document upload pipeline: normalize format, 
generate thumbnail, run OCR, detect category, extract expiration date."
```

### Maintenance Calendar
```
Flutter UI: "Create the maintenance calendar screen with Home Health Score, 
task cards grouped by due date, and quick-complete buttons."

Backend: "Design maintenance_tasks table with recurrence rules, 
completion tracking, and property/system relationships."

Notification: "Generate personalized maintenance schedules based on 
home profile, climate zone, and system ages."
```

### Emergency Hub
```
Flutter UI: "Build the Emergency Hub with water/gas/electrical shutoff 
cards. Must work offline using SQLite. Include high-contrast mode."

Backend: "Create emergency_info table with shutoff locations, 
emergency contacts, and insurance quick-reference data."

Testing: "Test Emergency Hub offline functionality - verify data 
persists and displays correctly without network."
```

### Home Value Tracking
```
Flutter UI: "Create home value screen with value history chart, 
equity calculator, and mortgage balance input."

API: "Integrate ATTOM API to fetch property valuations with 24-hour 
caching. Handle missing properties gracefully."

Analytics: "Track home_value_checked events with property_id and 
whether user updated mortgage balance."
```

---

## 💻 Essential Commands

### Flutter
```bash
# Development
flutter pub get                    # Install packages
flutter run                        # Run on connected device
flutter run -d chrome              # Run on web

# Quality
flutter analyze                    # Static analysis
flutter test                       # Run unit tests
flutter test integration_test/     # Run integration tests

# Build
flutter build apk --release        # Android APK
flutter build appbundle            # Android App Bundle
flutter build ios --release        # iOS build
```

### Next.js
```bash
# Development
npm run dev                        # Start dev server (localhost:3000)
npm run build                      # Production build
npm run start                      # Start production server

# Quality
npm run lint                       # ESLint
npm run type-check                 # TypeScript check
npm run test                       # Jest tests
```

### Supabase
```bash
# Local development
npx supabase start                 # Start local Supabase
npx supabase stop                  # Stop local Supabase
npx supabase status                # Show local URLs/keys

# Database
npx supabase db reset              # Reset to clean state
npx supabase db push               # Push migrations to remote
npx supabase db pull               # Pull remote schema

# Edge Functions
npx supabase functions serve       # Run functions locally
npx supabase functions deploy      # Deploy all functions

# Migrations
npx supabase migration new <name>  # Create new migration
npx supabase db diff               # Generate migration from changes
```

### Git/GitHub
```bash
# Feature branch workflow
git checkout -b feature/document-vault
git add .
git commit -m "feat: implement document list screen"
git push -u origin feature/document-vault
# Then create PR on GitHub
```

---

## 📁 Project Structure

### Flutter App
```
lib/
├── core/
│   ├── theme/
│   │   └── keystona_theme.dart     # Design system
│   ├── widgets/                     # Shared widgets
│   ├── providers/                   # Global providers
│   └── utils/                       # Helpers
├── features/
│   ├── document_vault/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── home_profile/
│   ├── maintenance/
│   ├── emergency_hub/
│   └── home_value/
└── main.dart
```

### Next.js Web
```
app/
├── (dashboard)/
│   ├── documents/
│   │   ├── page.tsx
│   │   └── [id]/page.tsx
│   ├── maintenance/
│   ├── home-profile/
│   └── layout.tsx
├── api/
│   ├── documents/
│   └── auth/
└── layout.tsx
components/
├── ui/                              # Base components
└── features/                        # Feature-specific
lib/
├── supabase/
│   ├── client.ts
│   └── server.ts
└── utils/
```

### Supabase
```
supabase/
├── migrations/
│   ├── 001_initial_schema.sql
│   ├── 002_documents.sql
│   └── 003_maintenance.sql
├── functions/
│   ├── ocr-processor/
│   ├── weather-alerts/
│   └── daily-reminders/
└── config.toml
```

---

## 🎨 Keystona Design Tokens

### Colors
```dart
// Primary
primaryBlue: Color(0xFF1E3A5F)      // Headers, primary buttons
secondaryBlue: Color(0xFF2E5A8B)    // Secondary elements
accentBlue: Color(0xFF4A90D9)       // Links, highlights

// Accent
warmGold: Color(0xFFD4A574)         // CTAs, important actions
lightGold: Color(0xFFF5E6D3)        // Backgrounds, highlights

// Status
success: Color(0xFF2E7D32)          // Completed, positive
warning: Color(0xFFF57C00)          // Due soon, attention
error: Color(0xFFD32F2F)            // Overdue, errors
```

### Spacing (4px base)
```
4px   - Tight spacing (icon padding)
8px   - Small spacing (between related items)
12px  - Medium-small (list item padding)
16px  - Medium (card padding, section gaps)
24px  - Large (between sections)
32px  - Extra large (major section breaks)
48px  - Page margins
```

### Typography
```
Heading 1: SF Pro Display, 28px, Bold
Heading 2: SF Pro Display, 24px, Semibold
Heading 3: SF Pro Display, 20px, Semibold
Body: SF Pro Text, 16px, Regular
Caption: SF Pro Text, 14px, Regular
Small: SF Pro Text, 12px, Regular
```

---

## 🗄️ Database Quick Reference

### Core Tables
```sql
-- User profile (extends auth.users)
profiles (id, display_name, subscription_tier, created_at)

-- Properties owned by user
properties (id, user_id, address, city, state, zip, purchase_date, purchase_price)

-- Documents in vault
documents (id, property_id, name, category, file_path, ocr_text, expires_at)

-- Maintenance tasks
maintenance_tasks (id, property_id, name, category, due_date, recurrence, completed_at)

-- Emergency info
emergency_info (id, property_id, type, location, photo_path, instructions)
```

### RLS Pattern
```sql
-- Enable RLS
ALTER TABLE [table] ENABLE ROW LEVEL SECURITY;

-- User can only see their own data
CREATE POLICY "Users see own data" ON [table]
  FOR SELECT USING (
    user_id = auth.uid() OR 
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );
```

---

## 🔔 Notification Triggers

| Event | Timing | Channel |
|-------|--------|---------|
| Document expiring | 90, 30, 7 days before | Push + Email |
| Maintenance due | 7, 1 day before | Push |
| Maintenance overdue | 1, 7 days after | Push |
| Weather alert | When forecast detected | Push |
| Home value change | Monthly if > 1% change | Email |
| Subscription expiring | 7, 1 day before | Push + Email |

---

## 📊 Key Analytics Events

```javascript
// Engagement events
'document_uploaded'     // { category, file_size, is_ocr_enabled }
'document_searched'     // { query, results_count }
'task_completed'        // { category, is_diy, cost }
'emergency_hub_viewed'  // { is_offline }

// Conversion events
'subscription_started'  // { tier, is_trial, source }
'subscription_cancelled' // { tier, reason, days_active }

// Feature usage
'home_value_checked'    // { }
'document_shared'       // { method, recipient_type }
```

---

## ✅ PR Checklist

Before submitting a PR, verify:

- [ ] Code compiles without errors
- [ ] `flutter analyze` / `npm run lint` passes
- [ ] Tests added for new functionality
- [ ] Tests pass locally
- [ ] UI matches Keystona design system
- [ ] RLS policies added for new tables
- [ ] Analytics events instrumented
- [ ] Documentation updated if needed
- [ ] No hardcoded secrets or API keys
- [ ] Responsive/accessible on all screen sizes

---

## 🆘 Troubleshooting

### Flutter
| Issue | Solution |
|-------|----------|
| Pub get fails | `flutter clean && flutter pub get` |
| iOS build fails | `cd ios && pod install --repo-update` |
| Android build fails | Check `minSdkVersion` in `android/app/build.gradle` |

### Supabase
| Issue | Solution |
|-------|----------|
| RLS blocking queries | Check `auth.uid()` matches, test with `SET ROLE` |
| Migration fails | `npx supabase db reset` and re-run |
| Edge Function 500 | Check logs: `npx supabase functions logs` |

### Next.js
| Issue | Solution |
|-------|----------|
| Hydration mismatch | Check for client-only code in Server Components |
| Build OOM | Increase Node memory: `NODE_OPTIONS=--max-old-space-size=4096` |
| Vercel deploy fails | Check environment variables are set |

---

*Generated for HomeTrack • January 2026*

12. Agent Orchestration Patterns
Understanding how to coordinate multiple agents for complex tasks.

Pattern 1: Feature Implementation Flow
Documentation Agent creates or updates feature spec
Flutter UI Agent builds mobile interface
Next.js Web Agent builds web interface (parallel with mobile)
Supabase Backend Agent creates database schema and APIs
API Integration Agent connects external services
Testing Agent writes and runs tests
DevOps Agent deploys to staging
Analytics Agent instruments tracking
Pattern 2: Bug Fix Flow
Identify bug location (UI, backend, API)
Relevant agent investigates and proposes fix
Testing Agent creates regression test
Fix is implemented and tested
DevOps Agent deploys hotfix
Documentation Agent updates if needed
Pattern 3: New Integration Flow
API Integration Agent researches new service
Documentation Agent creates integration spec
Supabase Backend Agent creates data models
API Integration Agent implements connection
UI Agents add interface components
Testing Agent validates integration
Analytics Agent tracks usage
13. Quick Reference & Cheatsheets
Agent Selection Guide
Task Type

Primary Agent

Supporting Agents

Build mobile UI

Flutter UI Agent

Testing, Analytics

Build web UI

Next.js Web Agent

Testing, Analytics

Create database table

Supabase Backend Agent

Documentation

Connect external API

API Integration Agent

Backend, Testing

Process documents

Document Processing Agent

Backend, API

Set up notifications

Notification Agent

Backend, DevOps

Write tests

Testing & QA Agent

All other agents

Deploy changes

DevOps Agent

Testing

Track metrics

Analytics Agent

All other agents

Write documentation

Documentation Agent

All other agents

Common Commands
Flutter
flutter pub get # Install dependencies flutter analyze # Check for issues flutter test # Run tests flutter build apk # Build Android flutter build ios # Build iOS

Next.js
npm run dev # Start dev server npm run build # Production build npm run lint # Check for issues npm run test # Run tests

Supabase
npx supabase start # Start local instance npx supabase db reset # Reset database npx supabase db push # Push migrations npx supabase functions serve # Run Edge Functions locally

Document generated for HomeTrack development. For questions or updates, refer to project documentation.