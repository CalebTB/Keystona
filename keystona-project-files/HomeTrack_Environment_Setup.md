# HomeTrack Environment Setup Guide
## Zero to Running App

**Version 1.0 | February 2026**
**Status:** Active — Follow top to bottom for a working dev environment

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Repository Setup](#2-repository-setup)
3. [Supabase Setup](#3-supabase-setup)
4. [Flutter App Setup](#4-flutter-app-setup)
5. [Third-Party Accounts](#5-third-party-accounts)
6. [Environment Variables Reference](#6-environment-variables-reference)
7. [Verify Everything Works](#7-verify-everything-works)
8. [Development Workflow](#8-development-workflow)
9. [Git Flow & Branch Strategy](#9-git-flow--branch-strategy)
10. [Agent Parallel Development Guide](#10-agent-parallel-development-guide)
11. [Environment Differences (Dev / Staging / Prod)](#11-environment-differences)
12. [Common Issues & Fixes](#12-common-issues--fixes)
13. [Next.js Web Setup (Post-MVP)](#13-nextjs-web-setup-post-mvp)

---

## 1. Prerequisites

### Required Software

Install these in order. Versions listed are minimum — use latest stable.

| Software | Minimum Version | Install | Verify |
|----------|----------------|---------|--------|
| **Git** | 2.40+ | [git-scm.com](https://git-scm.com) | `git --version` |
| **Flutter SDK** | 3.22+ | [flutter.dev/get-started](https://flutter.dev/docs/get-started/install) | `flutter --version` |
| **Dart** | 3.4+ | Included with Flutter | `dart --version` |
| **Xcode** (macOS only) | 15.0+ | Mac App Store | `xcode-select --version` |
| **Android Studio** | 2024.1+ | [developer.android.com](https://developer.android.com/studio) | Open and verify SDK |
| **Node.js** | 20 LTS | [nodejs.org](https://nodejs.org) | `node --version` |
| **npm** | 10+ | Included with Node.js | `npm --version` |
| **Supabase CLI** | 1.150+ | `npm install -g supabase` | `supabase --version` |
| **Docker Desktop** | 4.25+ | [docker.com](https://www.docker.com/products/docker-desktop) | `docker --version` |
| **VS Code** | Latest | [code.visualstudio.com](https://code.visualstudio.com) | — |

### VS Code Extensions

Install these for the best development experience:

```
# Required
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
code --install-extension ms-vscode.vscode-typescript-next

# Highly Recommended
code --install-extension bradlc.vscode-tailwindcss
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
code --install-extension mtxr.sqltools
code --install-extension mtxr.sqltools-driver-pg

# Optional but helpful
code --install-extension eamodio.gitlens
code --install-extension gruntfuggly.todo-tree
code --install-extension usernamehw.errorlens
```

### Flutter Doctor

Run this and resolve any issues before proceeding:

```bash
flutter doctor -v
```

You need green checkmarks for:
- ✅ Flutter SDK
- ✅ Android toolchain
- ✅ Xcode (macOS only)
- ✅ Chrome (for web debugging later)
- ✅ VS Code

### Platform-Specific Setup

**macOS (recommended for iOS + Android development):**
```bash
# Install CocoaPods for iOS
sudo gem install cocoapods

# Accept Xcode license
sudo xcodebuild -license accept

# Install iOS simulator
xcodebuild -downloadPlatform iOS

# Open iOS simulator to verify
open -a Simulator
```

**Android Setup (all platforms):**
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Verify Android emulator exists
# Open Android Studio → Virtual Device Manager → Create device if needed
# Recommended: Pixel 7 with API 34 (Android 14)
```

---

## 2. Repository Setup

### 2.1 Clone and Initialize

```bash
# Clone the monorepo
git clone https://github.com/<your-username>/hometrack.git
cd hometrack

# If starting fresh, create the repo structure:
mkdir -p apps/mobile          # Flutter app
mkdir -p apps/web             # Next.js (post-MVP)
mkdir -p supabase             # Supabase project (migrations, functions, seed)
mkdir -p packages/shared      # Shared types, constants, utilities
mkdir -p docs                 # Documentation
mkdir -p scripts              # Dev scripts, CI helpers
```

### 2.2 Monorepo Structure

```
hometrack/
├── apps/
│   ├── mobile/                    # Flutter app (MVP)
│   │   ├── android/
│   │   ├── ios/
│   │   ├── lib/
│   │   │   ├── core/              # Theme, constants, utils
│   │   │   ├── features/          # Feature modules
│   │   │   │   ├── auth/
│   │   │   │   ├── documents/
│   │   │   │   ├── home_profile/
│   │   │   │   ├── maintenance/
│   │   │   │   ├── emergency/
│   │   │   │   ├── onboarding/
│   │   │   │   └── settings/
│   │   │   ├── models/            # Data models
│   │   │   ├── providers/         # Riverpod providers
│   │   │   ├── services/          # Supabase, storage, notifications
│   │   │   └── main.dart
│   │   ├── test/
│   │   ├── pubspec.yaml
│   │   └── .env                   # Flutter env (gitignored)
│   │
│   └── web/                       # Next.js (post-MVP, empty for now)
│       └── .gitkeep
│
├── supabase/
│   ├── migrations/                # SQL migration files
│   │   ├── 001_extensions_and_enums.sql
│   │   ├── 002_profiles.sql
│   │   ├── 003_properties.sql
│   │   ├── 004_document_vault.sql
│   │   ├── 005_home_profile.sql
│   │   ├── 006_maintenance_calendar.sql
│   │   ├── 007_emergency_hub.sql
│   │   ├── 008_household_members.sql
│   │   ├── 009_notification_preferences.sql
│   │   └── 010_seed_data.sql
│   ├── functions/                 # Edge Functions (Deno/TypeScript)
│   │   ├── process-document-ocr/
│   │   ├── generate-maintenance-tasks/
│   │   ├── schedule-next-task/
│   │   ├── check-expirations/
│   │   ├── check-overdue-tasks/
│   │   ├── detect-climate-zone/
│   │   ├── emergency-hub-sync/
│   │   ├── invite-household-member/
│   │   ├── accept-household-invite/
│   │   ├── request-account-deletion/
│   │   ├── cancel-account-deletion/
│   │   ├── export-user-data/
│   │   ├── revenuecat-webhook/
│   │   └── send-push-notification/
│   ├── seed/                      # Additional seed data files
│   ├── config.toml                # Supabase local config
│   └── .env                       # Supabase env (gitignored)
│
├── packages/
│   └── shared/                    # Shared constants (post-MVP)
│       └── .gitkeep
│
├── docs/                          # All project documentation
│   ├── HomeTrack_SRS.docx
│   ├── HomeTrack_Database_Schema.md
│   ├── HomeTrack_API_Contract.md
│   ├── HomeTrack_Environment_Setup.md   # This file
│   └── ...
│
├── scripts/
│   ├── setup.sh                   # One-command setup script
│   ├── reset-db.sh                # Reset local database
│   └── generate-types.sh          # Generate TypeScript types from schema
│
├── .gitignore
├── .gitflow                       # Git Flow config
├── README.md
└── Makefile                       # Common commands
```

### 2.3 Root .gitignore

```bash
# Create at repo root
cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.*.local
*.env

# Flutter
apps/mobile/.dart_tool/
apps/mobile/.packages
apps/mobile/build/
apps/mobile/.flutter-plugins
apps/mobile/.flutter-plugins-dependencies
apps/mobile/ios/Pods/
apps/mobile/ios/.symlinks/
apps/mobile/android/.gradle/
apps/mobile/android/app/debug/
apps/mobile/android/app/profile/
apps/mobile/android/app/release/

# Next.js (for later)
apps/web/.next/
apps/web/node_modules/
apps/web/out/

# Supabase
supabase/.temp/
supabase/.branches/

# Node
node_modules/

# IDE
.idea/
.vscode/settings.json
*.iml
.DS_Store
Thumbs.db

# Generated
*.g.dart
*.freezed.dart
*.mocks.dart
EOF
```

### 2.4 Makefile (Common Commands)

```makefile
# Create at repo root
cat > Makefile << 'EOF'
.PHONY: setup db-start db-stop db-reset db-types app-run app-test app-build

# ─── Setup ───────────────────────────────────
setup:
	@echo "🏠 Setting up HomeTrack development environment..."
	cd apps/mobile && flutter pub get
	supabase start
	supabase db reset
	@echo "✅ Setup complete! Run 'make app-run' to start the app."

# ─── Supabase ────────────────────────────────
db-start:
	supabase start

db-stop:
	supabase stop

db-reset:
	supabase db reset
	@echo "✅ Database reset with fresh migrations and seed data"

db-types:
	supabase gen types typescript --local > packages/shared/database.types.ts
	@echo "✅ TypeScript types generated"

db-diff:
	supabase db diff --use-migra -f $(name)
	@echo "✅ Migration file created: supabase/migrations/$(name).sql"

db-push:
	supabase db push
	@echo "✅ Migrations pushed to remote"

# ─── Flutter App ─────────────────────────────
app-run:
	cd apps/mobile && flutter run

app-test:
	cd apps/mobile && flutter test

app-build-apk:
	cd apps/mobile && flutter build apk --release

app-build-ios:
	cd apps/mobile && flutter build ios --release

app-analyze:
	cd apps/mobile && flutter analyze

app-clean:
	cd apps/mobile && flutter clean && flutter pub get

# ─── Edge Functions ──────────────────────────
functions-serve:
	supabase functions serve --no-verify-jwt

functions-deploy:
	supabase functions deploy

# ─── Code Generation ─────────────────────────
codegen:
	cd apps/mobile && dart run build_runner build --delete-conflicting-outputs

codegen-watch:
	cd apps/mobile && dart run build_runner watch --delete-conflicting-outputs
EOF
```

---

## 3. Supabase Setup

### 3.1 Link Existing Project

You already have a Supabase project created. Link it:

```bash
# Login to Supabase CLI
supabase login

# Link to your existing project
cd hometrack
supabase link --project-ref <your-project-ref>

# Your project ref is in the Supabase dashboard URL:
# https://supabase.com/dashboard/project/<project-ref>
```

### 3.2 Start Local Development

Supabase CLI runs a full local instance via Docker. This is where you develop — never against production.

```bash
# Make sure Docker Desktop is running first!

# Start local Supabase (first run downloads images ~2-3 min)
supabase start
```

After startup, you'll see output like:

```
         API URL: http://127.0.0.1:54321
     GraphQL URL: http://127.0.0.1:54321/graphql/v1
          DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
      Studio URL: http://127.0.0.1:54323
    Inbucket URL: http://127.0.0.1:54324
      JWT secret: super-secret-jwt-token-with-at-least-32-characters
        anon key: eyJhb...your-local-anon-key
service_role key: eyJhb...your-local-service-role-key
   S3 Storage URL: http://127.0.0.1:54321/storage/v1/s3
```

**Save these values** — you'll need the API URL and anon key for the Flutter app.

### 3.3 Run Migrations

Copy migration files from the Database Schema document into `supabase/migrations/`:

```bash
# Verify migration files exist
ls supabase/migrations/
# Should show: 001_extensions_and_enums.sql through 010_seed_data.sql

# Reset database (runs all migrations + seed data)
supabase db reset
```

### 3.4 Verify Database

Open Supabase Studio at `http://127.0.0.1:54323` and check:

- ✅ **Table Editor** → 20 tables visible
- ✅ **profiles** → empty (created on user signup)
- ✅ **document_categories** → 6 system categories seeded
- ✅ **document_types** → 40+ types seeded across categories
- ✅ **maintenance_task_templates** → 25+ templates seeded
- ✅ **Authentication** → Email + password enabled

### 3.5 Create Storage Buckets

In Supabase Studio (`http://127.0.0.1:54323`):

1. Go to **Storage** in the sidebar
2. Create these buckets (all **private**):

| Bucket Name | File Size Limit | Allowed MIME Types |
|-------------|----------------|--------------------|
| `documents` | 25 MB | `application/pdf, image/jpeg, image/png, image/heic, image/webp` |
| `item-photos` | 10 MB | `image/jpeg, image/png, image/heic, image/webp` |
| `shutoff-photos` | 5 MB | `image/jpeg, image/png` |
| `completion-photos` | 10 MB | `image/jpeg, image/png, image/heic, image/webp` |
| `property-photos` | 10 MB | `image/jpeg, image/png, image/heic, image/webp` |

Or via SQL in the SQL Editor:

```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('documents', 'documents', false, 26214400, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/heic', 'image/webp']),
  ('item-photos', 'item-photos', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/webp']),
  ('shutoff-photos', 'shutoff-photos', false, 5242880, ARRAY['image/jpeg', 'image/png']),
  ('completion-photos', 'completion-photos', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/webp']),
  ('property-photos', 'property-photos', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/webp']);
```

Then add storage policies (run in SQL Editor):

```sql
-- All buckets: users can only access their own files
-- File paths follow: {user_id}/{property_id}/...

CREATE POLICY "Users upload own files" ON storage.objects
  FOR INSERT WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users view own files" ON storage.objects
  FOR SELECT USING (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users delete own files" ON storage.objects
  FOR DELETE USING (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users update own files" ON storage.objects
  FOR UPDATE USING (auth.uid()::text = (storage.foldername(name))[1]);
```

### 3.6 Enable Auth Providers

In Supabase Studio → **Authentication** → **Providers**:

1. **Email** → Already enabled (default)
   - Enable "Confirm email" for production, disable for local dev
   - Enable "Allow new users"
2. **Google** → Enable when you have OAuth credentials (Section 5)
3. **Apple** → Enable when you have Apple Developer credentials (Section 5)

For local development, **email auth with auto-confirm is enough.**

### 3.7 Local Email Testing

Supabase local includes **Inbucket** for capturing emails (magic links, confirmations, password resets):

```
http://127.0.0.1:54324
```

All emails sent during local development go here instead of real inboxes.

---

## 4. Flutter App Setup

### 4.1 Create Flutter Project

```bash
cd apps/

# Create Flutter project
flutter create mobile --org com.hometrack --platforms ios,android
cd mobile
```

### 4.2 Install Dependencies

Replace `apps/mobile/pubspec.yaml` dependencies section:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ─── Supabase ───────────────────
  supabase_flutter: ^2.5.0

  # ─── State Management ──────────
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # ─── Navigation ─────────────────
  go_router: ^14.0.0

  # ─── UI Components ─────────────
  google_fonts: ^6.2.0           # Outfit + Plus Jakarta Sans
  flutter_svg: ^2.0.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0                # Loading skeletons

  # ─── Forms & Validation ────────
  flutter_form_builder: ^9.3.0
  form_builder_validators: ^10.0.0

  # ─── Local Storage & Offline ───
  sqflite: ^2.3.0                # SQLite for Emergency Hub offline
  shared_preferences: ^2.2.0     # Simple key-value storage
  hive_flutter: ^1.1.0           # Fast local cache
  path_provider: ^2.1.0

  # ─── File & Camera ─────────────
  image_picker: ^1.1.0
  file_picker: ^8.0.0
  image_cropper: ^7.1.0
  flutter_image_compress: ^2.3.0

  # ─── Notifications ─────────────
  firebase_core: ^3.1.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.2.0

  # ─── Analytics & Monitoring ────
  posthog_flutter: ^4.5.0
  sentry_flutter: ^8.2.0

  # ─── Payments ──────────────────
  purchases_flutter: ^7.0.0      # RevenueCat

  # ─── Utilities ─────────────────
  intl: ^0.19.0                  # Date formatting
  url_launcher: ^6.2.0
  share_plus: ^9.0.0
  connectivity_plus: ^6.0.0     # Network status
  permission_handler: ^11.3.0
  package_info_plus: ^8.0.0
  uuid: ^4.4.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mockito: ^5.4.0
  build_verify: ^3.1.0
```

```bash
# Install all dependencies
flutter pub get
```

### 4.3 Flutter Environment Configuration

Create `apps/mobile/.env`:

```bash
# ─── Supabase (Local Development) ───────────
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=eyJhb...your-local-anon-key

# ─── PostHog ─────────────────────────────────
POSTHOG_API_KEY=phc_your_posthog_key
POSTHOG_HOST=https://us.i.posthog.com

# ─── Sentry ──────────────────────────────────
SENTRY_DSN=https://your-sentry-dsn@sentry.io/123

# ─── RevenueCat ──────────────────────────────
REVENUECAT_APPLE_KEY=appl_your_key
REVENUECAT_GOOGLE_KEY=goog_your_key

# ─── App Config ──────────────────────────────
APP_ENV=development
```

**Load env vars in Flutter** using `--dart-define-from-file`:

```bash
# Run with env vars
flutter run --dart-define-from-file=.env
```

Create `apps/mobile/lib/core/config.dart`:

```dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String posthogHost = String.fromEnvironment('POSTHOG_HOST');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String revenuecatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const String revenuecatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging => appEnv == 'staging';
  static bool get isProduction => appEnv == 'production';
}
```

### 4.4 Initialize Supabase in Flutter

Create `apps/mobile/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: HomeTrackApp(),
    ),
  );
}

class HomeTrackApp extends StatelessWidget {
  const HomeTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A2B4A),  // Deep Navy
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('HomeTrack - Setup Complete ✅'),
        ),
      ),
    );
  }
}
```

### 4.5 Run the App

```bash
cd apps/mobile

# Run on iOS Simulator
flutter run --dart-define-from-file=.env

# Run on Android Emulator
flutter run --dart-define-from-file=.env -d emulator-5554

# Run on specific device
flutter devices                    # List available devices
flutter run --dart-define-from-file=.env -d <device-id>
```

---

## 5. Third-Party Accounts

Set up these accounts as needed. **Only Supabase is required to start development** — everything else can wait until you build the feature that needs it.

### Account Setup Checklist

| Service | When Needed | Free Tier? | Setup Time |
|---------|------------|------------|------------|
| ✅ **Supabase** | Now (already done) | Yes (generous) | Done |
| 🔲 **Firebase/FCM** | When building notifications | Yes | 30 min |
| 🔲 **Google Cloud (Vision API)** | When building OCR | $300 free credits | 45 min |
| 🔲 **RevenueCat** | When building payments | Yes (under $2.5K MRR) | 30 min |
| 🔲 **PostHog** | When adding analytics | Yes (1M events/mo) | 15 min |
| 🔲 **Sentry** | When adding error tracking | Yes (5K errors/mo) | 15 min |
| 🔲 **Resend** | When building email notifications | Yes (3K emails/mo) | 15 min |
| 🔲 **Apple Developer** | Before iOS App Store submission | $99/year | 1-2 days (approval) |
| 🔲 **Google Play Console** | Before Android submission | $25 one-time | 1-2 days (approval) |

### Firebase / FCM Setup (Push Notifications)

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project: "HomeTrack"
3. Add iOS app: bundle ID `com.hometrack.app`
4. Add Android app: package name `com.hometrack.app`
5. Download `GoogleService-Info.plist` → place in `apps/mobile/ios/Runner/`
6. Download `google-services.json` → place in `apps/mobile/android/app/`
7. Get **Server Key** for Supabase Edge Functions → save to `.env`

### Google Cloud Vision (OCR)

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create project: "HomeTrack"
3. Enable **Cloud Vision API**
4. Create **Service Account** with Vision API access
5. Download JSON key file
6. Store key as Supabase secret: `supabase secrets set GOOGLE_CLOUD_VISION_KEY='...'`

### RevenueCat (Subscriptions)

1. Go to [app.revenuecat.com](https://app.revenuecat.com)
2. Create project: "HomeTrack"
3. Create products matching tier structure:
   - `hometrack_premium_monthly` — $7.99/mo
   - `hometrack_premium_annual` — $79.99/yr
   - `hometrack_family_monthly` — $14.99/mo
   - `hometrack_family_annual` — $149.99/yr
4. Get API keys for Apple + Google platforms
5. Set up webhook → point to Supabase Edge Function URL

### PostHog (Analytics)

1. Go to [posthog.com](https://posthog.com)
2. Create project: "HomeTrack"
3. Select US Cloud (data residency requirement)
4. Get **Project API Key**
5. Add to `.env` files

### Sentry (Error Tracking)

1. Go to [sentry.io](https://sentry.io)
2. Create project: "HomeTrack" → Platform: Flutter
3. Get **DSN**
4. Add to `.env` files

---

## 6. Environment Variables Reference

### 6.1 Flutter App (`apps/mobile/.env`)

```bash
# ─── REQUIRED (to run the app) ────────────────────
SUPABASE_URL=http://127.0.0.1:54321          # Local: from 'supabase start'
SUPABASE_ANON_KEY=eyJhb...                   # Local: from 'supabase start'
APP_ENV=development                           # development | staging | production

# ─── OPTIONAL (add when features need them) ───────
POSTHOG_API_KEY=phc_...                       # PostHog project API key
POSTHOG_HOST=https://us.i.posthog.com         # PostHog US instance
SENTRY_DSN=https://...@sentry.io/...          # Sentry DSN
REVENUECAT_APPLE_KEY=appl_...                 # RevenueCat Apple API key
REVENUECAT_GOOGLE_KEY=goog_...                # RevenueCat Google API key
```

### 6.2 Supabase Edge Functions (`supabase/.env`)

```bash
# ─── Supabase (auto-available in Edge Functions) ──
# SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically

# ─── Third-Party API Keys ─────────────────────────
GOOGLE_CLOUD_VISION_KEY='{...}'               # JSON service account key
FCM_SERVER_KEY=AAAA...                        # Firebase Cloud Messaging
RESEND_API_KEY=re_...                         # Transactional email
REVENUECAT_WEBHOOK_SECRET=whsec_...           # Webhook verification

# ─── App Config ──────────────────────────────────
APP_URL=https://hometrack.app                 # For email links
SUPPORT_EMAIL=support@hometrack.app
```

Set secrets for remote (production) Edge Functions:

```bash
# Set secrets one at a time
supabase secrets set GOOGLE_CLOUD_VISION_KEY='...'
supabase secrets set FCM_SERVER_KEY='...'
supabase secrets set RESEND_API_KEY='...'

# Or from a file
supabase secrets set --env-file supabase/.env.production
```

### 6.3 Environment Files to Create

| File | Location | Gitignored | Purpose |
|------|----------|------------|---------|
| `.env` | `apps/mobile/` | ✅ Yes | Flutter app config |
| `.env.staging` | `apps/mobile/` | ✅ Yes | Staging overrides |
| `.env.production` | `apps/mobile/` | ✅ Yes | Production overrides |
| `.env` | `supabase/` | ✅ Yes | Local Edge Function secrets |
| `.env.example` | repo root | ❌ No (committed) | Template showing required vars |

### 6.4 Example .env Template (committed to repo)

```bash
# Create at repo root: .env.example
# Copy this file and fill in real values:
#   cp .env.example apps/mobile/.env

SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<from supabase start output>
APP_ENV=development
POSTHOG_API_KEY=<from posthog.com>
POSTHOG_HOST=https://us.i.posthog.com
SENTRY_DSN=<from sentry.io>
REVENUECAT_APPLE_KEY=<from revenuecat.com>
REVENUECAT_GOOGLE_KEY=<from revenuecat.com>
```

---

## 7. Verify Everything Works

Run through this checklist to confirm your setup is correct.

### 7.1 Supabase Running

```bash
# Check status
supabase status

# Expected: all services running
# API, DB, Studio, Inbucket, Realtime all show URLs
```

Open Studio at `http://127.0.0.1:54323` → should see all 20 tables.

### 7.2 Flutter App Launches

```bash
cd apps/mobile
flutter run --dart-define-from-file=.env
```

Expected: App launches on simulator/emulator showing "HomeTrack - Setup Complete ✅"

### 7.3 Auth Works

Test in Supabase Studio → **SQL Editor**:

```sql
-- Create a test user (or use the Auth UI in Studio)
-- Go to Authentication → Users → Add User
-- Email: test@hometrack.dev / Password: testpass123

-- After creating user, verify profile was auto-created:
SELECT * FROM profiles;
-- Should show one row with the user's email
```

### 7.4 Seed Data Loaded

```sql
-- Check categories
SELECT name, icon, color FROM document_categories ORDER BY sort_order;
-- Should return 6 rows: Ownership, Insurance, Warranties, Maintenance, Permits, Financial

-- Check document types
SELECT dc.name AS category, dt.name AS type
FROM document_types dt
JOIN document_categories dc ON dc.id = dt.category_id
ORDER BY dc.sort_order, dt.sort_order;
-- Should return 40+ rows

-- Check maintenance templates
SELECT name, category, season, difficulty FROM maintenance_task_templates ORDER BY season, category;
-- Should return 25+ rows
```

### 7.5 Storage Buckets Exist

```sql
SELECT id, name, public, file_size_limit FROM storage.buckets;
-- Should return 5 buckets: documents, item-photos, shutoff-photos, completion-photos, property-photos
```

### 7.6 RLS Working

```sql
-- This should return 0 rows (no authenticated user in SQL editor context)
SELECT * FROM properties;

-- Verify RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true;
-- Should list all user-data tables
```

---

## 8. Development Workflow

### Daily Workflow

```bash
# 1. Start your day
docker start                         # If Docker isn't running
supabase start                       # Start local Supabase
cd apps/mobile

# 2. Pull latest changes
git checkout develop
git pull origin develop

# 3. Create feature branch
git checkout -b feature/document-upload

# 4. Run the app
flutter run --dart-define-from-file=.env

# 5. Code → hot reload (automatic on save)

# 6. Run tests before committing
flutter test
flutter analyze

# 7. Commit and push
git add .
git commit -m "feat: implement document upload flow"
git push origin feature/document-upload

# 8. End of day
supabase stop                        # Stop local Supabase (saves Docker resources)
```

### Database Changes Workflow

```bash
# 1. Make schema changes in Supabase Studio (Table Editor or SQL Editor)

# 2. Generate migration file from diff
supabase db diff --use-migra -f add_document_tags

# 3. Review generated migration
cat supabase/migrations/*_add_document_tags.sql

# 4. Test by resetting
supabase db reset    # Runs all migrations from scratch

# 5. Commit migration file
git add supabase/migrations/
git commit -m "migration: add document tags table"
```

### Edge Function Development

```bash
# Create new function
supabase functions new process-document-ocr

# Develop locally (auto-reloads on save)
supabase functions serve process-document-ocr --no-verify-jwt

# Test locally
curl -X POST http://127.0.0.1:54321/functions/v1/process-document-ocr \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"document_id": "test-uuid"}'

# Deploy to production
supabase functions deploy process-document-ocr
```

---

## 9. Git Flow & Branch Strategy

### Branch Structure

```
main                          # Production-ready code only
├── develop                   # Integration branch for features
│   ├── feature/auth-flow           # Feature branches (from develop)
│   ├── feature/document-vault
│   ├── feature/maintenance-calendar
│   └── feature/emergency-hub
├── release/1.0.0             # Release prep (from develop)
└── hotfix/fix-login-crash    # Emergency fixes (from main)
```

### Git Flow Setup

```bash
# Install git-flow
# macOS: brew install git-flow-avh
# Ubuntu: apt-get install git-flow

# Initialize in repo
cd hometrack
git flow init

# Accept defaults:
# Production branch: main
# Development branch: develop
# Feature prefix: feature/
# Release prefix: release/
# Hotfix prefix: hotfix/
```

### Branch Naming Conventions

```
feature/document-upload          # New feature
feature/maintenance-quick-complete
feature/emergency-offline-sync

bugfix/fix-photo-rotation        # Bug fix (goes to develop)

release/1.0.0                    # Release preparation

hotfix/fix-login-crash           # Production hotfix (goes to main)
```

### Workflow Commands

```bash
# Start a feature
git flow feature start document-upload

# Finish a feature (merges to develop)
git flow feature finish document-upload

# Start a release
git flow release start 1.0.0

# Finish a release (merges to main AND develop, creates tag)
git flow release finish 1.0.0

# Emergency hotfix
git flow hotfix start fix-login-crash
git flow hotfix finish fix-login-crash
```

### Commit Message Convention

```
<type>: <description>

Types:
  feat:     New feature
  fix:      Bug fix
  docs:     Documentation changes
  style:    Code formatting (no logic change)
  refactor: Code restructuring
  test:     Adding or updating tests
  chore:    Build process, dependencies
  migration: Database migration

Examples:
  feat: implement document upload with camera capture
  fix: resolve photo rotation on Android devices
  migration: add document_tags table
  docs: update API contract with search endpoint
  chore: upgrade supabase_flutter to 2.6.0
```

---

## 10. Agent Parallel Development Guide

With AI agents working on different features simultaneously, coordination is critical. Here's how to structure parallel work without merge conflicts.

### Feature Independence Map

These features can be developed **in parallel** after the foundation is set:

```
Foundation (must be done first):
  ├── Auth flow (sign up, sign in, profile)
  ├── Property setup (onboarding)
  └── Core navigation shell

Then in parallel:
  ┌─────────────────┐  ┌────────────────────┐
  │ Agent A:         │  │ Agent B:            │
  │ Document Vault   │  │ Maintenance Calendar│
  │ - Upload flow    │  │ - Task list         │
  │ - Categories     │  │ - Quick complete    │
  │ - Search/OCR     │  │ - Task detail       │
  │ - Expiration     │  │ - Recurring tasks   │
  └─────────────────┘  └────────────────────┘

  ┌─────────────────┐  ┌────────────────────┐
  │ Agent C:         │  │ Agent D:            │
  │ Home Profile     │  │ Emergency Hub       │
  │ - Systems CRUD   │  │ - Shutoff setup     │
  │ - Appliances     │  │ - Contacts          │
  │ - Lifespan view  │  │ - Insurance         │
  │ - Photos         │  │ - Offline sync      │
  └─────────────────┘  └────────────────────┘
```

### Rules for Parallel Agent Work

1. **Each agent works on its own feature branch**
   ```
   feature/document-vault      (Agent A)
   feature/maintenance-calendar (Agent B)
   feature/home-profile         (Agent C)
   feature/emergency-hub        (Agent D)
   ```

2. **Each agent only modifies files in its feature directory**
   ```
   Agent A only touches: lib/features/documents/
   Agent B only touches: lib/features/maintenance/
   Agent C only touches: lib/features/home_profile/
   Agent D only touches: lib/features/emergency/
   ```

3. **Shared code goes through you (the integrator)**
   - `lib/core/` — theme, constants, shared widgets
   - `lib/services/` — Supabase client, storage service
   - `lib/models/` — shared data models
   - `lib/providers/` — shared Riverpod providers
   - Navigation routes (router config)

4. **Database migrations are sequential, never parallel**
   - Agents don't create migrations
   - Agents reference existing tables from the schema doc
   - If an agent needs a schema change, they flag it for you

5. **Integration order**
   ```
   develop ← feature/foundation (you build this first)
   develop ← feature/document-vault (merge first complete feature)
   develop ← feature/home-profile
   develop ← feature/maintenance-calendar
   develop ← feature/emergency-hub
   develop ← feature/cross-feature-integration (links between features)
   ```

### Foundation Layer (Build First, Before Agents Start)

You build this before giving features to agents:

```
lib/
├── core/
│   ├── config.dart              # Environment config
│   ├── theme/
│   │   ├── app_theme.dart       # Keystona theme (colors, typography)
│   │   ├── app_colors.dart      # Deep Navy, Gold, etc.
│   │   └── app_text_styles.dart
│   ├── constants/
│   │   ├── app_sizes.dart       # Spacing constants (4px base)
│   │   └── app_strings.dart
│   ├── widgets/                 # Shared widgets
│   │   ├── app_scaffold.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_view.dart
│   │   ├── empty_state.dart
│   │   └── status_badge.dart
│   └── utils/
│       ├── date_utils.dart
│       ├── formatters.dart
│       └── validators.dart
├── services/
│   ├── supabase_service.dart    # Supabase client singleton
│   ├── storage_service.dart     # File upload/download
│   ├── auth_service.dart        # Auth wrapper
│   └── connectivity_service.dart
├── models/
│   ├── profile.dart
│   └── property.dart
├── providers/
│   ├── auth_provider.dart
│   ├── profile_provider.dart
│   └── property_provider.dart
├── router/
│   └── app_router.dart          # GoRouter config with all routes
├── features/
│   ├── auth/                    # Sign in, sign up, forgot password
│   ├── onboarding/              # Welcome, property setup, first steps
│   └── settings/                # Profile, preferences, subscription
└── main.dart
```

### Agent Handoff Template

When assigning a feature to an agent, provide:

```markdown
## Feature Assignment: [Feature Name]

**Branch:** feature/[feature-name]
**Directory:** lib/features/[feature_name]/

**What to build:**
- [Screen 1]: [description]
- [Screen 2]: [description]
- ...

**Database tables you'll use:**
- [table_name] — see Database Schema doc, Section X
- [table_name] — see Database Schema doc, Section X

**API calls you'll make:**
- See API Contract doc, Section X

**Shared code available to you:**
- `AppTheme` for colors/typography
- `SupabaseService` for database calls
- `StorageService` for file uploads
- [List other shared utilities]

**Do NOT modify:**
- Any files outside lib/features/[feature_name]/
- Any database migrations
- The router (flag new routes for integration)

**When done, deliver:**
- All feature code in your directory
- Widget tests for key screens
- List of routes that need to be added to the router
- List of any shared code you needed but didn't have
```

---

## 11. Environment Differences

| Setting | Development | Staging | Production |
|---------|------------|---------|------------|
| Supabase URL | `localhost:54321` | `<staging-ref>.supabase.co` | `<prod-ref>.supabase.co` |
| Email confirmation | Disabled | Enabled | Enabled |
| OCR processing | Mock/skip | Real (Vision API) | Real (Vision API) |
| Push notifications | Local only | FCM Sandbox | FCM Production |
| Payments | RevenueCat Sandbox | RevenueCat Sandbox | RevenueCat Production |
| Analytics | Disabled | PostHog (dev project) | PostHog (prod project) |
| Error tracking | Console only | Sentry (staging) | Sentry (production) |
| Storage | Local Docker | Supabase Cloud | Supabase Cloud |
| Data | Seed data + test users | Copy of prod structure | Real user data |
| Logging | Verbose | Standard | Errors only |

### Switching Environments

```bash
# Development (default)
flutter run --dart-define-from-file=.env

# Staging
flutter run --dart-define-from-file=.env.staging

# Production build
flutter build apk --dart-define-from-file=.env.production
flutter build ios --dart-define-from-file=.env.production
```

### Staging Setup (When Ready)

1. Create second Supabase project: "HomeTrack Staging"
2. Push migrations: `supabase db push --linked`
3. Copy `.env` → `.env.staging`, update URLs and keys
4. Set up staging secrets: `supabase secrets set --env-file .env.staging`

---

## 12. Common Issues & Fixes

### Supabase Won't Start

```
Error: Cannot connect to the Docker daemon
```
**Fix:** Start Docker Desktop first, wait for it to fully load, then `supabase start`.

---

```
Error: Port 54321 already in use
```
**Fix:**
```bash
# Find what's using the port
lsof -i :54321
# Kill it or change Supabase port in supabase/config.toml
```

---

```
Error: Database migration failed
```
**Fix:**
```bash
# Reset everything
supabase db reset
# If still failing, check migration SQL syntax in the file listed in the error
```

### Flutter Issues

```
Error: CocoaPods not installed
```
**Fix:** `sudo gem install cocoapods` then `cd ios && pod install`

---

```
Error: Xcode build failed — signing issues
```
**Fix:**
1. Open `apps/mobile/ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Select your Team (personal or org)
4. Change Bundle Identifier to something unique for development

---

```
Error: Android Gradle build fails
```
**Fix:**
```bash
cd apps/mobile/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

```
Error: supabase_flutter connection refused
```
**Fix:** When running on a **physical Android device**, `localhost` doesn't work.
```dart
// Instead of http://127.0.0.1:54321, use your machine's local IP:
// Find it: ifconfig | grep "inet " | grep -v 127.0.0.1
SUPABASE_URL=http://192.168.1.XXX:54321
```

For **Android emulator**, use `10.0.2.2`:
```dart
SUPABASE_URL=http://10.0.2.2:54321
```

### Performance Issues

```
Flutter app slow in debug mode
```
**This is normal.** Debug mode is 10x slower than release. To test real performance:
```bash
flutter run --profile
```

---

```
Supabase queries slow locally
```
**Fix:** Docker Desktop may need more resources:
- Settings → Resources → increase Memory to 4GB+
- Settings → Resources → increase CPUs to 2+

---

## 13. Next.js Web Setup (Post-MVP)

**Not needed for MVP.** This section is a placeholder for when you're ready to build the web dashboard.

```bash
# When ready:
cd apps/web
npx create-next-app@latest . --typescript --tailwind --app --src-dir
npm install @supabase/supabase-js @supabase/ssr
npm install zod react-hook-form @hookform/resolvers
npm install recharts                    # For charts
```

Web environment vars will go in `apps/web/.env.local`:
```bash
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhb...
```

Full web setup guide will be written when this phase begins.

---

## Quick Start Summary

If you've read this whole doc and just want the commands:

```bash
# 1. Clone repo
git clone https://github.com/<username>/hometrack.git && cd hometrack

# 2. Start Supabase (Docker must be running)
supabase start

# 3. Run migrations
supabase db reset

# 4. Set up Flutter
cd apps/mobile && flutter pub get

# 5. Create .env file with Supabase URL + anon key from step 2

# 6. Run the app
flutter run --dart-define-from-file=.env

# 7. Open Supabase Studio to verify
open http://127.0.0.1:54323
```

**You're ready to build HomeTrack. 🏠**

---

*End of Environment Setup Guide*
*HomeTrack — Version 1.0 — February 2026*
