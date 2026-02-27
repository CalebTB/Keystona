# HomeTrack Database Schema
## Complete Migration Reference

**Version 1.0 | February 2026**
**Status:** Active — Authoritative schema for MVP development

---

## Table of Contents

1. [Schema Overview](#1-schema-overview)
2. [Migration 001: Extensions & Enums](#2-migration-001-extensions--enums)
3. [Migration 002: Profiles](#3-migration-002-profiles)
4. [Migration 003: Properties](#4-migration-003-properties)
5. [Migration 004: Document Vault](#5-migration-004-document-vault)
6. [Migration 005: Home Profile (Systems & Appliances)](#6-migration-005-home-profile)
7. [Migration 006: Maintenance Calendar](#7-migration-006-maintenance-calendar)
8. [Migration 007: Emergency Hub](#8-migration-007-emergency-hub)
9. [Migration 008: Household Members](#9-migration-008-household-members)
10. [Migration 009: Notification Preferences](#10-migration-009-notification-preferences)
11. [Migration 010: Seed Data](#11-migration-010-seed-data)
12. [Storage Buckets](#12-storage-buckets)
13. [Entity Relationship Diagram](#13-entity-relationship-diagram)
14. [RLS Policy Reference](#14-rls-policy-reference)
15. [Index Reference](#15-index-reference)
16. [Rollback Scripts](#16-rollback-scripts)

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Primary Keys | UUID (`gen_random_uuid()`) | No sequential ID guessing, safe for client exposure |
| Soft Deletes | `deleted_at` timestamp | Data recovery, audit trail, 30-day grace period |
| Audit Columns | `created_at`, `updated_at` on all tables | Track data changes, debug issues |
| Multi-Property | Single property per user for MVP | Simplicity; schema supports multi-property via `properties` table |
| Categories | Separate lookup table | Flexible — add/edit categories without code deploy |
| Task Templates | Database seed table | Easy to update templates without app update |
| RLS | All user-data tables | Enforced at database level, not application level |
| Timestamps | `timestamptz` | Always store in UTC, convert in app |

---

## 1. Schema Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        SCHEMA OVERVIEW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  auth.users (Supabase managed)                                  │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────┐                                                   │
│  │ profiles │ ◄── extends auth.users                            │
│  └────┬─────┘                                                   │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────┐                                               │
│  │  properties   │ ◄── one per user (MVP)                       │
│  └──────┬───────┘                                               │
│         │                                                       │
│    ┌────┼────────────┬──────────────┬────────────────┐          │
│    ▼    ▼            ▼              ▼                ▼          │
│  docs  systems    maint_tasks  emergency_info   household       │
│        appliances  completions  contacts         members        │
│                    templates    insurance                        │
│                                                                 │
│  Lookup Tables (no RLS):                                        │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ doc_categories│  │ doc_types        │  │ maint_templates  │  │
│  └──────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Migration 001: Extensions & Enums

**File:** `supabase/migrations/001_extensions_and_enums.sql`

```sql
-- ============================================================
-- Migration 001: Extensions & Enums
-- HomeTrack MVP Database Schema
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Fuzzy text search

-- ============================================================
-- ENUMS
-- ============================================================

-- Subscription tiers
CREATE TYPE subscription_tier AS ENUM ('free', 'premium', 'family');

-- Account status
CREATE TYPE account_status AS ENUM ('active', 'deactivated', 'pending_deletion');

-- System categories (HVAC, plumbing, etc.)
CREATE TYPE system_category AS ENUM (
  'hvac',
  'plumbing',
  'electrical',
  'roofing',
  'foundation',
  'siding',
  'windows_doors',
  'insulation',
  'garage',
  'other'
);

-- System status
CREATE TYPE item_status AS ENUM ('active', 'needs_repair', 'replaced', 'removed');

-- Appliance categories
CREATE TYPE appliance_category AS ENUM (
  'kitchen',
  'laundry',
  'climate',
  'cleaning',
  'outdoor',
  'bathroom',
  'other'
);

-- Maintenance task status
CREATE TYPE task_status AS ENUM ('scheduled', 'due', 'overdue', 'completed', 'skipped');

-- Task origin
CREATE TYPE task_origin AS ENUM (
  'system_generated',   -- Created when a system is added
  'climate_triggered',  -- Based on climate zone
  'seasonal',           -- Seasonal checklist
  'custom',             -- User created
  'one_time'            -- One-off task
);

-- Task difficulty
CREATE TYPE task_difficulty AS ENUM ('easy', 'moderate', 'involved', 'professional');

-- DIY or professional
CREATE TYPE diy_or_pro AS ENUM ('diy', 'either', 'professional');

-- Task priority
CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high', 'critical');

-- Recurrence pattern
CREATE TYPE recurrence_type AS ENUM (
  'none',
  'weekly',
  'biweekly',
  'monthly',
  'quarterly',
  'biannual',
  'annual'
);

-- Emergency utility type
CREATE TYPE utility_type AS ENUM ('water', 'gas', 'electrical');

-- Emergency contact category
CREATE TYPE contact_category AS ENUM (
  'plumber',
  'electrician',
  'hvac_tech',
  'general_contractor',
  'roofer',
  'pest_control',
  'locksmith',
  'insurance_agent',
  'neighbor',
  'other'
);

-- Notification channel
CREATE TYPE notification_channel AS ENUM ('push', 'email', 'both');
```

---

## 3. Migration 002: Profiles

**File:** `supabase/migrations/002_profiles.sql`

```sql
-- ============================================================
-- Migration 002: User Profiles
-- Extends Supabase auth.users with app-specific data
-- ============================================================

CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    TEXT,
  email           TEXT,
  avatar_url      TEXT,
  
  -- Subscription
  subscription_tier   subscription_tier NOT NULL DEFAULT 'free',
  subscription_id     TEXT,                -- RevenueCat subscription ID
  trial_started_at    TIMESTAMPTZ,
  trial_ends_at       TIMESTAMPTZ,
  
  -- Account
  account_status      account_status NOT NULL DEFAULT 'active',
  deletion_requested_at TIMESTAMPTZ,       -- 30-day grace period start
  deletion_scheduled_at TIMESTAMPTZ,       -- When hard delete happens
  
  -- Onboarding
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  onboarding_step     TEXT DEFAULT 'welcome',
  
  -- Preferences
  timezone            TEXT DEFAULT 'America/Chicago',
  climate_zone        SMALLINT,            -- IECC zone (1-8)
  
  -- Audit
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Indexes
CREATE INDEX idx_profiles_subscription ON profiles(subscription_tier);
CREATE INDEX idx_profiles_account_status ON profiles(account_status);
CREATE INDEX idx_profiles_deletion ON profiles(deletion_scheduled_at) WHERE deletion_scheduled_at IS NOT NULL;
```

---

## 4. Migration 003: Properties

**File:** `supabase/migrations/003_properties.sql`

```sql
-- ============================================================
-- Migration 003: Properties
-- Home details, address, and purchase information
-- MVP: One property per user (enforced by unique constraint)
-- ============================================================

CREATE TABLE properties (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Address
  address_line1   TEXT NOT NULL,
  address_line2   TEXT,
  city            TEXT NOT NULL,
  state           TEXT NOT NULL,       -- 2-letter abbreviation
  zip_code        TEXT NOT NULL,
  county          TEXT,
  
  -- Property Details
  property_type   TEXT DEFAULT 'single_family',  -- single_family, condo, townhouse, multi_family
  year_built      SMALLINT,
  square_feet     INTEGER,
  lot_size_sqft   INTEGER,
  bedrooms        SMALLINT,
  bathrooms       NUMERIC(3,1),        -- e.g., 2.5
  stories         SMALLINT,
  garage_type     TEXT,                 -- attached, detached, carport, none
  garage_spaces   SMALLINT,
  
  -- Purchase Info
  purchase_date   DATE,
  purchase_price  NUMERIC(12,2),
  down_payment    NUMERIC(12,2),
  
  -- Climate
  climate_zone    SMALLINT,            -- IECC zone (1-8), auto-detected from ZIP
  
  -- Photo
  exterior_photo_path TEXT,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

-- MVP: One property per user
CREATE UNIQUE INDEX idx_properties_one_per_user
  ON properties(user_id) WHERE deleted_at IS NULL;

CREATE TRIGGER properties_updated_at
  BEFORE UPDATE ON properties
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own properties"
  ON properties FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own properties"
  ON properties FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own properties"
  ON properties FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can soft-delete own properties"
  ON properties FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_properties_user ON properties(user_id);
CREATE INDEX idx_properties_zip ON properties(zip_code);
CREATE INDEX idx_properties_state ON properties(state);
```

---

## 5. Migration 004: Document Vault

**File:** `supabase/migrations/004_document_vault.sql`

```sql
-- ============================================================
-- Migration 004: Document Vault
-- Categories (lookup table), documents, and document files
-- ============================================================

-- ---- DOCUMENT CATEGORIES (lookup table, no RLS) ----

CREATE TABLE document_categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES profiles(id) ON DELETE CASCADE,  -- NULL = system category
  name            TEXT NOT NULL,
  icon            TEXT NOT NULL DEFAULT 'document',
  color           TEXT NOT NULL DEFAULT '#1565C0',
  is_system       BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order      SMALLINT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- System categories are readable by all; custom ones only by owner
ALTER TABLE document_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view system categories"
  ON document_categories FOR SELECT
  USING (is_system = TRUE);

CREATE POLICY "Users can view own custom categories"
  ON document_categories FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert custom categories"
  ON document_categories FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_system = FALSE);

CREATE POLICY "Users can update own custom categories"
  ON document_categories FOR UPDATE
  USING (user_id = auth.uid() AND is_system = FALSE);

CREATE POLICY "Users can delete own custom categories"
  ON document_categories FOR DELETE
  USING (user_id = auth.uid() AND is_system = FALSE);


-- ---- DOCUMENT TYPES (lookup table within categories) ----

CREATE TABLE document_types (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id     UUID NOT NULL REFERENCES document_categories(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  description     TEXT,
  metadata_schema JSONB,              -- Defines which metadata fields apply
  sort_order      SMALLINT NOT NULL DEFAULT 0
);

ALTER TABLE document_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view document types"
  ON document_types FOR SELECT
  USING (TRUE);


-- ---- DOCUMENTS ----

CREATE TABLE documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Classification
  name            TEXT NOT NULL,
  category_id     UUID NOT NULL REFERENCES document_categories(id),
  document_type_id UUID REFERENCES document_types(id),
  
  -- Files
  file_path       TEXT NOT NULL,       -- Supabase Storage path
  thumbnail_path  TEXT,
  file_size_bytes INTEGER,
  mime_type       TEXT,
  page_count      SMALLINT DEFAULT 1,
  
  -- OCR
  ocr_text        TEXT,
  ocr_status      TEXT NOT NULL DEFAULT 'pending',  -- pending, processing, complete, failed
  search_vector   TSVECTOR,            -- Full-text search index
  
  -- Metadata (flexible, varies by document type)
  metadata        JSONB DEFAULT '{}',
  
  -- Expiration Tracking
  expiration_date DATE,
  expiration_reminded_90 BOOLEAN DEFAULT FALSE,
  expiration_reminded_30 BOOLEAN DEFAULT FALSE,
  expiration_reminded_7  BOOLEAN DEFAULT FALSE,
  
  -- Links to systems/appliances
  linked_system_id    UUID,            -- FK added after systems table exists
  linked_appliance_id UUID,            -- FK added after appliances table exists
  
  -- Notes
  notes           TEXT,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-generate search vector
CREATE OR REPLACE FUNCTION update_document_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    COALESCE(NEW.name, '') || ' ' ||
    COALESCE(NEW.ocr_text, '') || ' ' ||
    COALESCE(NEW.notes, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER documents_search_vector
  BEFORE INSERT OR UPDATE OF name, ocr_text, notes ON documents
  FOR EACH ROW EXECUTE FUNCTION update_document_search_vector();

-- RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid() AND deleted_at IS NULL)
  );

CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can soft-delete own documents"
  ON documents FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Indexes
CREATE INDEX idx_documents_property ON documents(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_user ON documents(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_category ON documents(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_expiration ON documents(expiration_date) WHERE expiration_date IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_documents_ocr_status ON documents(ocr_status) WHERE ocr_status IN ('pending', 'processing');
CREATE INDEX idx_documents_search ON documents USING GIN(search_vector);
CREATE INDEX idx_documents_name_trgm ON documents USING GIN(name gin_trgm_ops);
```

---

## 6. Migration 005: Home Profile

**File:** `supabase/migrations/005_home_profile.sql`

```sql
-- ============================================================
-- Migration 005: Home Profile (Systems & Appliances)
-- Major home systems and appliance tracking with lifespan data
-- ============================================================

-- ---- SYSTEMS ----

CREATE TABLE systems (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Classification
  category        system_category NOT NULL,
  system_type     TEXT NOT NULL,        -- e.g., 'furnace_gas', 'central_ac', 'tankless_water_heater'
  name            TEXT NOT NULL,        -- Display name, e.g., 'Main Furnace'
  status          item_status NOT NULL DEFAULT 'active',
  
  -- Identification
  brand           TEXT,
  model           TEXT,
  serial_number   TEXT,
  
  -- Installation / Purchase
  installation_date DATE,
  purchase_price  NUMERIC(10,2),
  installer       TEXT,                 -- Company that installed
  
  -- Location
  location        TEXT,                 -- e.g., 'Basement', 'Attic', 'Garage'
  
  -- Lifespan
  expected_lifespan_min SMALLINT,      -- Years (from NAHB data or user override)
  expected_lifespan_max SMALLINT,      -- Years
  lifespan_override     SMALLINT,      -- User can override default
  
  -- Warranty
  warranty_expiration   DATE,
  warranty_provider     TEXT,
  linked_warranty_doc_id UUID,         -- FK to documents
  
  -- Replacement
  estimated_replacement_cost NUMERIC(10,2),
  replaced_by_system_id     UUID REFERENCES systems(id),
  
  -- Notes
  notes           TEXT,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER systems_updated_at
  BEFORE UPDATE ON systems
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE systems ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own systems"
  ON systems FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own systems"
  ON systems FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update own systems"
  ON systems FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

-- Indexes
CREATE INDEX idx_systems_property ON systems(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_systems_category ON systems(property_id, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_systems_warranty ON systems(warranty_expiration) WHERE warranty_expiration IS NOT NULL AND deleted_at IS NULL;


-- ---- APPLIANCES ----

CREATE TABLE appliances (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Classification
  category        appliance_category NOT NULL,
  appliance_type  TEXT NOT NULL,        -- e.g., 'refrigerator', 'washer', 'dishwasher'
  name            TEXT NOT NULL,        -- Display name
  status          item_status NOT NULL DEFAULT 'active',
  
  -- Identification
  brand           TEXT,
  model           TEXT,
  serial_number   TEXT,
  color           TEXT,
  
  -- Purchase
  purchase_date   DATE,
  purchase_price  NUMERIC(10,2),
  retailer        TEXT,
  
  -- Location
  location        TEXT,                 -- Room name
  
  -- Lifespan
  expected_lifespan_min SMALLINT,
  expected_lifespan_max SMALLINT,
  lifespan_override     SMALLINT,
  
  -- Warranty
  warranty_expiration   DATE,
  warranty_provider     TEXT,
  linked_warranty_doc_id UUID,
  
  -- Type-specific specs (flexible)
  specifications  JSONB DEFAULT '{}',
  
  -- Replacement
  estimated_replacement_cost NUMERIC(10,2),
  replaced_by_appliance_id  UUID REFERENCES appliances(id),
  
  -- Notes
  notes           TEXT,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER appliances_updated_at
  BEFORE UPDATE ON appliances
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE appliances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own appliances"
  ON appliances FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own appliances"
  ON appliances FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update own appliances"
  ON appliances FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

-- Indexes
CREATE INDEX idx_appliances_property ON appliances(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_appliances_category ON appliances(property_id, category) WHERE deleted_at IS NULL;
CREATE INDEX idx_appliances_warranty ON appliances(warranty_expiration) WHERE warranty_expiration IS NOT NULL AND deleted_at IS NULL;


-- ---- PHOTOS (shared for systems & appliances) ----

CREATE TABLE item_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Polymorphic: either system or appliance
  system_id       UUID REFERENCES systems(id) ON DELETE CASCADE,
  appliance_id    UUID REFERENCES appliances(id) ON DELETE CASCADE,
  
  -- Photo
  file_path       TEXT NOT NULL,
  thumbnail_path  TEXT,
  photo_type      TEXT NOT NULL DEFAULT 'overview',  -- overview, model_label, location, condition, maintenance, other
  caption         TEXT,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Ensure photo belongs to exactly one parent
  CONSTRAINT photo_has_one_parent CHECK (
    (system_id IS NOT NULL AND appliance_id IS NULL) OR
    (system_id IS NULL AND appliance_id IS NOT NULL)
  )
);

ALTER TABLE item_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own item photos"
  ON item_photos FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own item photos"
  ON item_photos FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own item photos"
  ON item_photos FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_item_photos_system ON item_photos(system_id) WHERE system_id IS NOT NULL;
CREATE INDEX idx_item_photos_appliance ON item_photos(appliance_id) WHERE appliance_id IS NOT NULL;


-- ---- Add FK from documents to systems/appliances ----

ALTER TABLE documents
  ADD CONSTRAINT fk_documents_system FOREIGN KEY (linked_system_id) REFERENCES systems(id) ON DELETE SET NULL;

ALTER TABLE documents
  ADD CONSTRAINT fk_documents_appliance FOREIGN KEY (linked_appliance_id) REFERENCES appliances(id) ON DELETE SET NULL;
```

---

## 7. Migration 006: Maintenance Calendar

**File:** `supabase/migrations/006_maintenance_calendar.sql`

```sql
-- ============================================================
-- Migration 006: Maintenance Calendar
-- Task templates (seed table), tasks, and completion records
-- ============================================================

-- ---- MAINTENANCE TASK TEMPLATES (seed table, no RLS) ----

CREATE TABLE maintenance_task_templates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Classification
  name            TEXT NOT NULL,
  description     TEXT,
  instructions    TEXT,
  category        TEXT NOT NULL,        -- 'hvac', 'plumbing', 'exterior', 'interior', 'safety', 'seasonal'
  
  -- Scheduling
  season          TEXT,                 -- 'spring', 'summer', 'fall', 'winter', NULL for year-round
  recurrence      recurrence_type NOT NULL DEFAULT 'annual',
  default_month   SMALLINT,            -- 1-12, suggested month
  
  -- Task details
  difficulty      task_difficulty NOT NULL DEFAULT 'easy',
  diy_or_pro      diy_or_pro NOT NULL DEFAULT 'diy',
  priority        task_priority NOT NULL DEFAULT 'medium',
  estimated_minutes SMALLINT DEFAULT 30,
  tools_needed    JSONB DEFAULT '[]',
  supplies_needed JSONB DEFAULT '[]',
  
  -- Targeting
  climate_zones   SMALLINT[],          -- Which climate zones this applies to (NULL = all)
  system_category system_category,     -- If linked to a system type
  appliance_type  TEXT,                -- If linked to an appliance type
  
  -- Active
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order      SMALLINT DEFAULT 0,
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- No RLS needed — templates are read-only reference data
ALTER TABLE maintenance_task_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view templates"
  ON maintenance_task_templates FOR SELECT
  USING (TRUE);


-- ---- MAINTENANCE TASKS ----

CREATE TABLE maintenance_tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Source
  template_id     UUID REFERENCES maintenance_task_templates(id),
  task_origin     task_origin NOT NULL DEFAULT 'custom',
  
  -- Task Info
  name            TEXT NOT NULL,
  description     TEXT,
  instructions    TEXT,
  category        TEXT NOT NULL,
  
  -- Linked system/appliance
  linked_system_id    UUID REFERENCES systems(id) ON DELETE SET NULL,
  linked_appliance_id UUID REFERENCES appliances(id) ON DELETE SET NULL,
  
  -- Scheduling
  due_date        DATE NOT NULL,
  recurrence      recurrence_type NOT NULL DEFAULT 'none',
  season          TEXT,
  climate_adjusted BOOLEAN DEFAULT FALSE,
  
  -- Status
  status          task_status NOT NULL DEFAULT 'scheduled',
  
  -- Task details
  difficulty      task_difficulty NOT NULL DEFAULT 'easy',
  diy_or_pro      diy_or_pro NOT NULL DEFAULT 'diy',
  priority        task_priority NOT NULL DEFAULT 'medium',
  estimated_minutes SMALLINT,
  tools_needed    JSONB DEFAULT '[]',
  supplies_needed JSONB DEFAULT '[]',
  
  -- Reminders
  reminder_days_before SMALLINT DEFAULT 7,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  reminded_7day   BOOLEAN DEFAULT FALSE,
  reminded_1day   BOOLEAN DEFAULT FALSE,
  
  -- Skip tracking
  skip_reason     TEXT,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER maintenance_tasks_updated_at
  BEFORE UPDATE ON maintenance_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tasks"
  ON maintenance_tasks FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own tasks"
  ON maintenance_tasks FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    property_id IN (SELECT id FROM properties WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can update own tasks"
  ON maintenance_tasks FOR UPDATE
  USING (user_id = auth.uid() AND deleted_at IS NULL);

-- Indexes
CREATE INDEX idx_tasks_property ON maintenance_tasks(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_due ON maintenance_tasks(due_date, status) WHERE deleted_at IS NULL AND status NOT IN ('completed', 'skipped');
CREATE INDEX idx_tasks_status ON maintenance_tasks(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tasks_system ON maintenance_tasks(linked_system_id) WHERE linked_system_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_tasks_overdue ON maintenance_tasks(due_date) WHERE status = 'scheduled' AND deleted_at IS NULL;


-- ---- TASK COMPLETIONS ----

CREATE TABLE task_completions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id         UUID NOT NULL REFERENCES maintenance_tasks(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  
  -- Completion details
  completed_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  completed_by    TEXT NOT NULL DEFAULT 'diy',  -- 'diy' or 'contractor'
  
  -- Contractor info (if applicable)
  contractor_name TEXT,
  contractor_company TEXT,
  contractor_phone TEXT,
  
  -- Costs
  service_cost    NUMERIC(10,2),
  materials_cost  NUMERIC(10,2),
  
  -- Details
  time_spent_minutes SMALLINT,
  notes           TEXT,
  
  -- Linked documents (receipts, invoices)
  linked_document_ids UUID[] DEFAULT '{}',
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own completions"
  ON task_completions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own completions"
  ON task_completions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own completions"
  ON task_completions FOR UPDATE
  USING (user_id = auth.uid());

CREATE INDEX idx_completions_task ON task_completions(task_id);
CREATE INDEX idx_completions_property ON task_completions(property_id);
CREATE INDEX idx_completions_date ON task_completions(completed_date);


-- ---- COMPLETION PHOTOS ----

CREATE TABLE completion_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  completion_id   UUID NOT NULL REFERENCES task_completions(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_path       TEXT NOT NULL,
  thumbnail_path  TEXT,
  caption         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE completion_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own completion photos"
  ON completion_photos FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own completion photos"
  ON completion_photos FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE INDEX idx_completion_photos ON completion_photos(completion_id);
```

---

## 8. Migration 007: Emergency Hub

**File:** `supabase/migrations/007_emergency_hub.sql`

```sql
-- ============================================================
-- Migration 007: Emergency Hub
-- Shutoff locations, emergency contacts, insurance quick-ref
-- All data designed to sync to local SQLite for offline access
-- ============================================================

-- ---- UTILITY SHUTOFFS ----

CREATE TABLE utility_shutoffs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Shutoff info
  utility_type    utility_type NOT NULL,
  location_description TEXT NOT NULL,    -- e.g., 'Basement, left wall near water heater'
  
  -- Water-specific
  valve_type      TEXT,                  -- gate, ball, quarter-turn
  turn_direction  TEXT,                  -- clockwise, counterclockwise
  
  -- Gas-specific
  gas_company_phone TEXT,
  
  -- Electrical-specific
  main_breaker_location TEXT,
  main_breaker_amperage SMALLINT,
  circuit_directory JSONB,               -- [{breaker: 1, label: 'Kitchen'}]
  
  -- General
  tools_required  JSONB DEFAULT '[]',    -- ['wrench', 'flashlight']
  special_instructions TEXT,
  
  -- Completion tracking
  is_complete     BOOLEAN DEFAULT FALSE,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER shutoffs_updated_at
  BEFORE UPDATE ON utility_shutoffs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE utility_shutoffs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own shutoffs"
  ON utility_shutoffs FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own shutoffs"
  ON utility_shutoffs FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own shutoffs"
  ON utility_shutoffs FOR UPDATE
  USING (user_id = auth.uid());

CREATE INDEX idx_shutoffs_property ON utility_shutoffs(property_id);


-- ---- SHUTOFF PHOTOS ----

CREATE TABLE shutoff_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shutoff_id      UUID NOT NULL REFERENCES utility_shutoffs(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_path       TEXT NOT NULL,
  thumbnail_path  TEXT,
  photo_type      TEXT DEFAULT 'location',  -- location, detail, valve, panel
  caption         TEXT,
  file_size_bytes INTEGER,                  -- Track for offline storage budget
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE shutoff_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own shutoff photos"
  ON shutoff_photos FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own shutoff photos"
  ON shutoff_photos FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own shutoff photos"
  ON shutoff_photos FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_shutoff_photos ON shutoff_photos(shutoff_id);


-- ---- EMERGENCY CONTACTS ----

CREATE TABLE emergency_contacts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Contact info
  name            TEXT NOT NULL,
  company_name    TEXT,
  category        contact_category NOT NULL,
  phone_primary   TEXT NOT NULL,
  phone_secondary TEXT,
  email           TEXT,
  
  -- Availability
  available_hours TEXT,                  -- e.g., 'M-F 8am-5pm'
  is_24x7         BOOLEAN DEFAULT FALSE,
  
  -- Preference
  is_favorite     BOOLEAN DEFAULT FALSE,
  notes           TEXT,
  
  -- Usage tracking
  times_used      INTEGER DEFAULT 0,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER contacts_updated_at
  BEFORE UPDATE ON emergency_contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own contacts"
  ON emergency_contacts FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own contacts"
  ON emergency_contacts FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own contacts"
  ON emergency_contacts FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own contacts"
  ON emergency_contacts FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_contacts_property ON emergency_contacts(property_id);
CREATE INDEX idx_contacts_category ON emergency_contacts(property_id, category);


-- ---- INSURANCE QUICK REFERENCE ----

CREATE TABLE insurance_info (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Policy info
  policy_type     TEXT NOT NULL,          -- 'homeowners', 'flood', 'earthquake', 'umbrella', 'home_warranty'
  carrier         TEXT NOT NULL,
  policy_number   TEXT,
  
  -- Coverage
  coverage_amount NUMERIC(12,2),
  deductible      NUMERIC(10,2),
  premium_annual  NUMERIC(10,2),
  
  -- Agent
  agent_name      TEXT,
  agent_phone     TEXT,
  agent_email     TEXT,
  
  -- Claims
  claims_phone    TEXT,
  
  -- Dates
  effective_date  DATE,
  expiration_date DATE,
  
  -- Linked doc
  linked_document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER insurance_updated_at
  BEFORE UPDATE ON insurance_info
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE insurance_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own insurance"
  ON insurance_info FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own insurance"
  ON insurance_info FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own insurance"
  ON insurance_info FOR UPDATE
  USING (user_id = auth.uid());

CREATE INDEX idx_insurance_property ON insurance_info(property_id);
CREATE INDEX idx_insurance_expiration ON insurance_info(expiration_date) WHERE expiration_date IS NOT NULL;
```

---

## 9. Migration 008: Household Members

**File:** `supabase/migrations/008_household_members.sql`

```sql
-- ============================================================
-- Migration 008: Household Members
-- Invite family members with full access to property
-- ============================================================

CREATE TABLE household_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  owner_user_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Member info
  member_user_id  UUID REFERENCES profiles(id) ON DELETE CASCADE,  -- NULL until invite accepted
  invited_email   TEXT NOT NULL,
  invite_status   TEXT NOT NULL DEFAULT 'pending',  -- pending, accepted, declined, removed
  invite_token    TEXT,                              -- Unique token for invite link
  invited_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at     TIMESTAMPTZ,
  
  -- Access level (full access for MVP per Caleb's decision)
  access_level    TEXT NOT NULL DEFAULT 'full',  -- 'full' for MVP
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER household_updated_at
  BEFORE UPDATE ON household_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;

-- Owner can manage all household members for their property
CREATE POLICY "Owners can view household members"
  ON household_members FOR SELECT
  USING (owner_user_id = auth.uid());

CREATE POLICY "Members can view their own membership"
  ON household_members FOR SELECT
  USING (member_user_id = auth.uid() AND invite_status = 'accepted');

CREATE POLICY "Owners can invite members"
  ON household_members FOR INSERT
  WITH CHECK (owner_user_id = auth.uid());

CREATE POLICY "Owners can update members"
  ON household_members FOR UPDATE
  USING (owner_user_id = auth.uid());

-- Members can accept/decline their own invites
CREATE POLICY "Members can update own invite"
  ON household_members FOR UPDATE
  USING (member_user_id = auth.uid() OR invited_email = (SELECT email FROM profiles WHERE id = auth.uid()));

CREATE INDEX idx_household_property ON household_members(property_id);
CREATE INDEX idx_household_owner ON household_members(owner_user_id);
CREATE INDEX idx_household_member ON household_members(member_user_id) WHERE member_user_id IS NOT NULL;
CREATE INDEX idx_household_invite_token ON household_members(invite_token) WHERE invite_token IS NOT NULL;


-- ============================================================
-- Update RLS policies on data tables to include household members
-- Household members get the same access as owners
-- ============================================================

-- Helper function: check if user has access to a property
CREATE OR REPLACE FUNCTION user_has_property_access(p_property_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM properties WHERE id = p_property_id AND user_id = auth.uid() AND deleted_at IS NULL
  ) OR EXISTS (
    SELECT 1 FROM household_members
    WHERE property_id = p_property_id
      AND member_user_id = auth.uid()
      AND invite_status = 'accepted'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- NOTE: In production, update all existing SELECT policies on
-- documents, systems, appliances, maintenance_tasks, etc.
-- to use user_has_property_access(property_id) instead of
-- just checking user_id = auth.uid().
--
-- Example (apply to all property-scoped tables):
--
-- DROP POLICY "Users can view own documents" ON documents;
-- CREATE POLICY "Users can view own documents"
--   ON documents FOR SELECT
--   USING (
--     (user_id = auth.uid() OR user_has_property_access(property_id))
--     AND deleted_at IS NULL
--   );
--
-- This is commented out to keep initial migration clean.
-- Apply as Migration 008b after household feature is built.
```

---

## 10. Migration 009: Notification Preferences

**File:** `supabase/migrations/009_notification_preferences.sql`

```sql
-- ============================================================
-- Migration 009: Notification Preferences
-- Per-user notification settings and push token management
-- ============================================================

CREATE TABLE notification_preferences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Global
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  quiet_hours_start TIME,               -- e.g., '22:00'
  quiet_hours_end   TIME,               -- e.g., '08:00'
  preferred_day     TEXT DEFAULT 'saturday',  -- For non-urgent maintenance reminders
  preferred_time    TIME DEFAULT '09:00',
  
  -- Category toggles
  maintenance_reminders   BOOLEAN DEFAULT TRUE,
  expiration_alerts       BOOLEAN DEFAULT TRUE,
  weather_alerts          BOOLEAN DEFAULT TRUE,   -- v1.5
  financial_alerts        BOOLEAN DEFAULT TRUE,   -- v1.5
  system_updates          BOOLEAN DEFAULT TRUE,
  
  -- Channel preferences
  maintenance_channel     notification_channel DEFAULT 'push',
  expiration_channel      notification_channel DEFAULT 'both',
  weather_channel         notification_channel DEFAULT 'push',
  
  -- Audit
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER notification_prefs_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences"
  ON notification_preferences FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own preferences"
  ON notification_preferences FOR UPDATE
  USING (user_id = auth.uid());

CREATE UNIQUE INDEX idx_notif_prefs_user ON notification_preferences(user_id);


-- ---- PUSH TOKENS ----

CREATE TABLE push_tokens (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token           TEXT NOT NULL,
  platform        TEXT NOT NULL,         -- 'ios', 'android', 'web'
  device_id       TEXT,                  -- Unique device identifier
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER push_tokens_updated_at
  BEFORE UPDATE ON push_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own tokens"
  ON push_tokens FOR ALL
  USING (user_id = auth.uid());

CREATE UNIQUE INDEX idx_push_tokens_unique ON push_tokens(user_id, token);
CREATE INDEX idx_push_tokens_active ON push_tokens(user_id) WHERE is_active = TRUE;


-- ---- NOTIFICATION LOG ----

CREATE TABLE notification_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Content
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  category        TEXT NOT NULL,         -- maintenance, expiration, weather, system
  
  -- Delivery
  channel         notification_channel NOT NULL,
  sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at         TIMESTAMPTZ,
  
  -- Reference
  reference_type  TEXT,                  -- 'task', 'document', 'weather_alert'
  reference_id    UUID,
  
  -- Metadata
  metadata        JSONB DEFAULT '{}'
);

ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notification_log FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notification_log FOR UPDATE
  USING (user_id = auth.uid());

CREATE INDEX idx_notif_log_user ON notification_log(user_id, sent_at DESC);
CREATE INDEX idx_notif_log_unread ON notification_log(user_id) WHERE read_at IS NULL;
```

---

## 11. Migration 010: Seed Data

**File:** `supabase/migrations/010_seed_data.sql`

```sql
-- ============================================================
-- Migration 010: Seed Data
-- System document categories, document types, and
-- maintenance task templates
-- ============================================================

-- ---- DOCUMENT CATEGORIES ----

INSERT INTO document_categories (id, name, icon, color, is_system, sort_order) VALUES
  (gen_random_uuid(), 'Ownership Documents', 'home', '#1565C0', TRUE, 1),
  (gen_random_uuid(), 'Insurance', 'shield', '#7B1FA2', TRUE, 2),
  (gen_random_uuid(), 'Warranties & Manuals', 'clipboard', '#F57C00', TRUE, 3),
  (gen_random_uuid(), 'Maintenance Records', 'wrench', '#388E3C', TRUE, 4),
  (gen_random_uuid(), 'Permits & Compliance', 'scroll', '#D32F2F', TRUE, 5),
  (gen_random_uuid(), 'Financial Documents', 'dollar', '#00796B', TRUE, 6);

-- Store category IDs for document type inserts
DO $$
DECLARE
  cat_ownership UUID;
  cat_insurance UUID;
  cat_warranties UUID;
  cat_maintenance UUID;
  cat_permits UUID;
  cat_financial UUID;
BEGIN
  SELECT id INTO cat_ownership FROM document_categories WHERE name = 'Ownership Documents';
  SELECT id INTO cat_insurance FROM document_categories WHERE name = 'Insurance';
  SELECT id INTO cat_warranties FROM document_categories WHERE name = 'Warranties & Manuals';
  SELECT id INTO cat_maintenance FROM document_categories WHERE name = 'Maintenance Records';
  SELECT id INTO cat_permits FROM document_categories WHERE name = 'Permits & Compliance';
  SELECT id INTO cat_financial FROM document_categories WHERE name = 'Financial Documents';

  -- ---- DOCUMENT TYPES ----

  -- Ownership
  INSERT INTO document_types (category_id, name, sort_order) VALUES
    (cat_ownership, 'Deed', 1),
    (cat_ownership, 'Title Insurance Policy', 2),
    (cat_ownership, 'Purchase Contract', 3),
    (cat_ownership, 'Closing Disclosure', 4),
    (cat_ownership, 'Survey / Plat Map', 5),
    (cat_ownership, 'HOA Documents', 6),
    (cat_ownership, 'Property Tax Assessment', 7),
    (cat_ownership, 'Other Ownership Document', 99);

  -- Insurance
  INSERT INTO document_types (category_id, name, sort_order) VALUES
    (cat_insurance, 'Homeowners Policy', 1),
    (cat_insurance, 'Flood Insurance', 2),
    (cat_insurance, 'Earthquake Insurance', 3),
    (cat_insurance, 'Umbrella Policy', 4),
    (cat_insurance, 'Home Warranty Policy', 5),
    (cat_insurance, 'Insurance Claim Record', 6),
    (cat_insurance, 'Insurance Photos', 7),
    (cat_insurance, 'Other Insurance Document', 99);

  -- Warranties & Manuals
  INSERT INTO document_types (category_id, name, sort_order) VALUES
    (cat_warranties, 'Appliance Warranty', 1),
    (cat_warranties, 'System Warranty', 2),
    (cat_warranties, 'Builder Warranty', 3),
    (cat_warranties, 'Roof Warranty', 4),
    (cat_warranties, 'Product Manual', 5),
    (cat_warranties, 'Extended Warranty', 6),
    (cat_warranties, 'Other Warranty Document', 99);

  -- Maintenance Records
  INSERT INTO document_types (category_id, name, sort_order) VALUES
    (cat_maintenance, 'Service Receipt', 1),
    (cat_maintenance, 'Inspection Report', 2),
    (cat_maintenance, 'Repair Invoice', 3),
    (cat_maintenance, 'Maintenance Log', 4),
    (cat_maintenance, 'Contractor Agreement', 5),
    (cat_maintenance, 'Other Maintenance Document', 99);

  -- Permits & Compliance
  INSERT INTO document_types (category_id, name, sort_order) VALUES
    (cat_permits, 'Building Permit', 1),
    (cat_permits, 'Certificate of Occupancy', 2),
    (cat_permits, 'Inspection Certificate', 3),
    (cat_permits, 'Renovation Permit', 4),
    (cat_permits, 'Code Compliance Letter', 5),
    (cat_permits, 'Other Permit Document', 99);

  -- Financial
  INSERT INTO document_types (category_id, name, sort_order) VALUES
    (cat_financial, 'Mortgage Documents', 1),
    (cat_financial, 'Property Tax Bill', 2),
    (cat_financial, 'Improvement Receipt', 3),
    (cat_financial, 'Appraisal', 4),
    (cat_financial, 'Refinance Documents', 5),
    (cat_financial, 'HELOC Documents', 6),
    (cat_financial, 'Other Financial Document', 99);
END $$;


-- ---- MAINTENANCE TASK TEMPLATES ----
-- Organized by season, then category

-- SPRING TASKS
INSERT INTO maintenance_task_templates (name, description, instructions, category, season, recurrence, default_month, difficulty, diy_or_pro, priority, estimated_minutes, tools_needed, supplies_needed, climate_zones) VALUES
  ('Service air conditioner', 'Annual AC tune-up before summer', 'Schedule professional HVAC service to inspect refrigerant levels, clean coils, check electrical connections, and test thermostat calibration.', 'hvac', 'spring', 'annual', 4, 'professional', 'professional', 'high', 60, '[]', '[]', '{2,3,4,5,6,7,8}'),
  ('Clean gutters and downspouts', 'Remove debris from winter and spring blooms', 'Remove leaves and debris from all gutters. Flush with hose to verify proper drainage. Check downspout extensions direct water away from foundation.', 'exterior', 'spring', 'biannual', 4, 'moderate', 'either', 'medium', 90, '["ladder", "garden hose", "gloves", "trowel"]', '["gutter sealant"]', NULL),
  ('Inspect roof for winter damage', 'Check for missing, cracked, or curling shingles', 'Use binoculars from ground or carefully climb ladder to inspect. Look for missing shingles, damaged flashing around vents/chimney, and signs of sagging.', 'exterior', 'spring', 'annual', 3, 'moderate', 'either', 'high', 30, '["binoculars", "ladder"]', '[]', NULL),
  ('Check exterior caulking and weatherstripping', 'Inspect and repair seals around windows and doors', 'Check caulking around all windows, doors, and exterior penetrations. Replace any cracked or missing caulk. Check weatherstripping on all doors.', 'exterior', 'spring', 'annual', 4, 'easy', 'diy', 'medium', 60, '["caulk gun"]', '["exterior caulk", "weatherstripping"]', NULL),
  ('Test and activate sprinkler system', 'Restart irrigation after winter', 'Slowly open main water valve. Run each zone manually and check for broken heads, leaks, and proper coverage. Adjust spray patterns as needed.', 'exterior', 'spring', 'annual', 4, 'easy', 'diy', 'medium', 45, '[]', '["replacement sprinkler heads"]', '{3,4,5,6,7,8}'),
  ('Power wash exterior surfaces', 'Clean siding, driveway, walkways, and deck', 'Power wash siding (appropriate pressure for material), concrete surfaces, and deck/patio. Check for any damage revealed after cleaning.', 'exterior', 'spring', 'annual', 5, 'moderate', 'either', 'low', 180, '["pressure washer"]', '["cleaning solution"]', NULL),

-- SUMMER TASKS
  ('Clean dryer vent and ductwork', 'Prevent fire hazard from lint buildup', 'Disconnect dryer vent from back of dryer. Use dryer vent brush to clean entire duct run to exterior. Clean lint trap housing. Verify exterior vent flap opens properly.', 'interior', 'summer', 'annual', 6, 'moderate', 'either', 'high', 45, '["dryer vent brush", "vacuum", "screwdriver"]', '[]', NULL),
  ('Inspect and stain/seal deck', 'Protect wood deck from weather damage', 'Inspect deck boards for rot, loose nails, or structural issues. Sand rough spots. Apply wood stain or sealant per product instructions.', 'exterior', 'summer', 'annual', 6, 'moderate', 'diy', 'medium', 240, '["sander", "paintbrush", "roller"]', '["deck stain or sealant"]', NULL),
  ('Check exterior paint for peeling', 'Maintain exterior finish and prevent rot', 'Walk around entire house looking for peeling, bubbling, or fading paint. Scrape loose paint, prime, and touch up as needed.', 'exterior', 'summer', 'annual', 7, 'moderate', 'diy', 'medium', 120, '["scraper", "paintbrush"]', '["primer", "exterior paint"]', NULL),
  ('Inspect garage door operation', 'Ensure safe and smooth operation', 'Test auto-reverse safety feature (place 2x4 under door). Lubricate rollers, hinges, and tracks. Check weatherstripping at bottom. Inspect springs for wear.', 'exterior', 'summer', 'annual', 7, 'easy', 'diy', 'medium', 30, '[]', '["garage door lubricant"]', NULL),
  ('Clean refrigerator condenser coils', 'Improve efficiency and extend lifespan', 'Pull refrigerator out, unplug it, and vacuum the condenser coils on the back or bottom. Remove dust and pet hair buildup.', 'interior', 'summer', 'biannual', 6, 'easy', 'diy', 'low', 20, '["vacuum with brush attachment"]', '[]', NULL),

-- FALL TASKS
  ('Service furnace / heating system', 'Annual heating tune-up before winter', 'Schedule professional HVAC service to inspect heat exchanger, clean burners, check gas connections, test safety controls, and replace filter.', 'hvac', 'fall', 'annual', 10, 'professional', 'professional', 'high', 60, '[]', '[]', '{2,3,4,5,6,7,8}'),
  ('Clean gutters and downspouts (fall)', 'Remove fallen leaves before winter', 'Thorough gutter cleaning after leaves have fallen. This is the most critical gutter cleaning of the year to prevent ice dams.', 'exterior', 'fall', 'annual', 11, 'moderate', 'either', 'high', 90, '["ladder", "garden hose", "gloves", "trowel"]', '["gutter sealant"]', NULL),
  ('Winterize sprinkler system', 'Blow out lines to prevent freeze damage', 'Shut off water supply to sprinkler system. Use air compressor to blow out all water from lines. Insulate above-ground pipes and backflow preventer.', 'exterior', 'fall', 'annual', 10, 'moderate', 'either', 'high', 60, '["air compressor"]', '["pipe insulation"]', '{4,5,6,7,8}'),
  ('Inspect and clean chimney', 'Remove creosote and check for damage', 'Schedule professional chimney sweep and inspection. Check flue for creosote buildup, cracks, and proper draft. Inspect chimney cap and crown.', 'interior', 'fall', 'annual', 10, 'professional', 'professional', 'high', 60, '[]', '[]', '{3,4,5,6,7,8}'),
  ('Test heating system before cold weather', 'Verify heat works before you need it', 'Turn on heating system and run for 30+ minutes. Check all vents for airflow. Listen for unusual sounds. Check for burning smells (normal briefly for first use).', 'hvac', 'fall', 'annual', 10, 'easy', 'diy', 'high', 15, '[]', '[]', '{3,4,5,6,7,8}'),
  ('Disconnect and drain outdoor hoses', 'Prevent frozen pipes and hose bibb damage', 'Disconnect all garden hoses. Drain water from hose bibbs. Install insulated covers on exterior faucets. Close interior shutoff valves to outdoor faucets if available.', 'exterior', 'fall', 'annual', 11, 'easy', 'diy', 'high', 20, '[]', '["hose bibb covers"]', '{4,5,6,7,8}'),

-- WINTER TASKS
  ('Check for ice dams', 'Prevent roof and water damage from ice buildup', 'After snowfall, check eaves for icicle formation and ice dams. If present, use roof rake to remove snow from first 3 feet of roof edge. Do NOT chip ice.', 'exterior', 'winter', 'monthly', 1, 'moderate', 'diy', 'high', 30, '["roof rake"]', '["ice melt (calcium chloride)"]', '{5,6,7,8}'),
  ('Inspect pipe insulation', 'Prevent frozen pipes during cold snaps', 'Check insulation on pipes in unheated areas: garage, crawlspace, attic, exterior walls. Add insulation where missing. Open cabinets under sinks on exterior walls during extreme cold.', 'interior', 'winter', 'annual', 12, 'easy', 'diy', 'high', 30, '[]', '["pipe insulation"]', '{4,5,6,7,8}'),
  ('Check for drafts around windows and doors', 'Reduce heating costs and improve comfort', 'On a windy day, hold a candle or incense near window and door frames. Seal any drafts with caulk or weatherstripping.', 'interior', 'winter', 'annual', 12, 'easy', 'diy', 'medium', 45, '["caulk gun"]', '["interior caulk", "weatherstripping"]', '{4,5,6,7,8}'),

-- MONTHLY TASKS (year-round)
  ('Replace HVAC filter', 'Maintain air quality and system efficiency', 'Check filter condition. Replace if dirty (most filters need replacement every 1-3 months). Write the date on the new filter with a marker.', 'hvac', NULL, 'monthly', NULL, 'easy', 'diy', 'high', 5, '[]', '["HVAC filter (check size)"]', NULL),
  ('Test smoke and CO detectors', 'Ensure life safety devices are working', 'Press test button on each smoke and carbon monoxide detector. Replace batteries if needed. Detectors older than 10 years should be replaced entirely.', 'interior', NULL, 'monthly', NULL, 'easy', 'diy', 'critical', 10, '[]', '["9V batteries"]', NULL),
  ('Run water in unused drains', 'Prevent sewer gas from entering home', 'Run water for 30 seconds in any sink, tub, or floor drain that has not been used in the past month. This refills the P-trap seal.', 'plumbing', NULL, 'monthly', NULL, 'easy', 'diy', 'low', 5, '[]', '[]', NULL),
  ('Clean garbage disposal', 'Remove buildup and odors', 'Run ice cubes through disposal to clean blades. Follow with lemon or orange peels for freshening. Alternatively, use baking soda and vinegar.', 'interior', NULL, 'monthly', NULL, 'easy', 'diy', 'low', 5, '[]', '["ice cubes", "citrus peels"]', NULL);
```

---

## 12. Storage Buckets

**Configure in Supabase Dashboard or via CLI:**

```sql
-- Document Vault files
-- Bucket: documents
-- Max file size: 25MB
-- Allowed MIME types: application/pdf, image/jpeg, image/png, image/heic, image/webp
-- Access: Private (signed URLs only)

-- Item photos (systems, appliances)
-- Bucket: item-photos
-- Max file size: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/heic, image/webp
-- Access: Private (signed URLs only)

-- Shutoff photos (Emergency Hub)
-- Bucket: shutoff-photos
-- Max file size: 5MB (compressed for offline sync)
-- Allowed MIME types: image/jpeg, image/png
-- Access: Private (signed URLs only)

-- Completion photos (maintenance task completions)
-- Bucket: completion-photos
-- Max file size: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/heic, image/webp
-- Access: Private (signed URLs only)

-- Property exterior photos
-- Bucket: property-photos
-- Max file size: 10MB
-- Allowed MIME types: image/jpeg, image/png, image/heic, image/webp
-- Access: Private (signed URLs only)
```

**Bucket Policies (apply to all buckets):**

```sql
-- Users can only access their own files
-- File paths follow: {user_id}/{property_id}/filename
CREATE POLICY "Users can upload own files"
  ON storage.objects FOR INSERT
  WITH CHECK (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own files"
  ON storage.objects FOR SELECT
  USING (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own files"
  ON storage.objects FOR DELETE
  USING (auth.uid()::text = (storage.foldername(name))[1]);
```

---

## 13. Entity Relationship Diagram

```
┌──────────────┐
│  auth.users  │
│  (Supabase)  │
└──────┬───────┘
       │ 1:1
       ▼
┌──────────────┐     1:N     ┌─────────────────────┐
│   profiles   │─────────────│  notification_prefs  │
│              │             └─────────────────────┘
│  id (PK/FK)  │     1:N     ┌─────────────────────┐
│  sub_tier    │─────────────│    push_tokens       │
│  status      │             └─────────────────────┘
└──────┬───────┘
       │ 1:1 (MVP)
       ▼
┌──────────────┐
│  properties  │
│              │
│  address     │
│  year_built  │
│  climate_zone│
└──┬───┬───┬───┘
   │   │   │
   │   │   │  1:N   ┌──────────────────┐  1:N  ┌──────────────┐
   │   │   ├────────│    systems       │───────│  item_photos  │
   │   │   │        │  (HVAC, roof...) │       └──────────────┘
   │   │   │        └──────────────────┘
   │   │   │
   │   │   │  1:N   ┌──────────────────┐  1:N  ┌──────────────┐
   │   │   ├────────│   appliances     │───────│  item_photos  │
   │   │   │        │ (fridge, wash..) │       └──────────────┘
   │   │   │        └──────────────────┘
   │   │   │
   │   │   │  1:N   ┌──────────────────┐  1:N  ┌──────────────────┐
   │   │   ├────────│maintenance_tasks │───────│ task_completions  │
   │   │   │        │ (scheduled work) │       │  (done records)   │
   │   │   │        └──────────────────┘       └────────┬─────────┘
   │   │   │                                            │ 1:N
   │   │   │                                   ┌────────┴─────────┐
   │   │   │                                   │ completion_photos │
   │   │   │                                   └──────────────────┘
   │   │   │
   │   │  1:N  ┌──────────────────┐
   │   ├───────│    documents     │
   │   │       │ (vault files)    │
   │   │       └──────────────────┘
   │   │           ▲         ▲
   │   │           │         │
   │   │    ┌──────┴──┐  ┌───┴──────────┐
   │   │    │doc_types│  │doc_categories│
   │   │    └─────────┘  └──────────────┘
   │   │
   │  1:N  ┌──────────────────┐  1:N  ┌──────────────┐
   ├───────│ utility_shutoffs  │───────│shutoff_photos│
   │       └──────────────────┘       └──────────────┘
   │
   │  1:N  ┌──────────────────┐
   ├───────│emergency_contacts│
   │       └──────────────────┘
   │
   │  1:N  ┌──────────────────┐
   ├───────│  insurance_info  │
   │       └──────────────────┘
   │
   │  1:N  ┌──────────────────┐
   └───────│household_members │
           └──────────────────┘

LOOKUP TABLES (no user ownership):
┌──────────────────────────┐
│maintenance_task_templates│
│  (50+ pre-built tasks)   │
└──────────────────────────┘
```

---

## 14. RLS Policy Reference

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | Own only | Auto (trigger) | Own only | N/A (cascade) |
| `properties` | Own, not deleted | Own | Own, not deleted | Soft delete only |
| `documents` | Own, not deleted | Own + valid property | Own, not deleted | Soft delete only |
| `document_categories` | System = all; Custom = own | Own + not system | Own + not system | Own + not system |
| `document_types` | All | N/A (seed only) | N/A | N/A |
| `systems` | Own, not deleted | Own + valid property | Own, not deleted | Soft delete only |
| `appliances` | Own, not deleted | Own + valid property | Own, not deleted | Soft delete only |
| `item_photos` | Own | Own | N/A | Own |
| `maintenance_tasks` | Own, not deleted | Own + valid property | Own, not deleted | Soft delete only |
| `maintenance_task_templates` | All (read-only) | N/A | N/A | N/A |
| `task_completions` | Own | Own | Own | N/A |
| `completion_photos` | Own | Own | N/A | N/A |
| `utility_shutoffs` | Own | Own | Own | N/A |
| `shutoff_photos` | Own | Own | N/A | Own |
| `emergency_contacts` | Own | Own | Own | Own |
| `insurance_info` | Own | Own | Own | N/A |
| `household_members` | Owner or accepted member | Owner only | Owner or invited member | N/A |
| `notification_preferences` | Own | Own | Own | N/A |
| `push_tokens` | Own | Own | Own | Own |
| `notification_log` | Own | System only | Own (mark read) | N/A |

---

## 15. Index Reference

| Table | Index | Columns | Condition |
|-------|-------|---------|-----------|
| `profiles` | `idx_profiles_subscription` | subscription_tier | — |
| `profiles` | `idx_profiles_deletion` | deletion_scheduled_at | WHERE NOT NULL |
| `properties` | `idx_properties_one_per_user` | user_id (UNIQUE) | WHERE deleted_at IS NULL |
| `properties` | `idx_properties_zip` | zip_code | — |
| `documents` | `idx_documents_property` | property_id | WHERE deleted_at IS NULL |
| `documents` | `idx_documents_expiration` | expiration_date | WHERE NOT NULL, not deleted |
| `documents` | `idx_documents_search` | search_vector (GIN) | — |
| `documents` | `idx_documents_name_trgm` | name (GIN trgm) | — |
| `documents` | `idx_documents_ocr_status` | ocr_status | WHERE pending/processing |
| `systems` | `idx_systems_property` | property_id | WHERE deleted_at IS NULL |
| `systems` | `idx_systems_warranty` | warranty_expiration | WHERE NOT NULL, not deleted |
| `appliances` | `idx_appliances_property` | property_id | WHERE deleted_at IS NULL |
| `maintenance_tasks` | `idx_tasks_due` | due_date, status | WHERE not completed/skipped |
| `maintenance_tasks` | `idx_tasks_overdue` | due_date | WHERE scheduled, not deleted |
| `task_completions` | `idx_completions_property` | property_id | — |
| `task_completions` | `idx_completions_date` | completed_date | — |
| `utility_shutoffs` | `idx_shutoffs_property` | property_id | — |
| `emergency_contacts` | `idx_contacts_property` | property_id | — |
| `insurance_info` | `idx_insurance_expiration` | expiration_date | WHERE NOT NULL |
| `household_members` | `idx_household_invite_token` | invite_token | WHERE NOT NULL |
| `notification_log` | `idx_notif_log_unread` | user_id | WHERE read_at IS NULL |

---

## 16. Rollback Scripts

Each migration has a corresponding rollback. Run in reverse order.

```sql
-- Rollback 010: Seed Data
DELETE FROM maintenance_task_templates;
DELETE FROM document_types;
DELETE FROM document_categories WHERE is_system = TRUE;

-- Rollback 009: Notification Preferences
DROP TABLE IF EXISTS notification_log;
DROP TABLE IF EXISTS push_tokens;
DROP TABLE IF EXISTS notification_preferences;

-- Rollback 008: Household Members
DROP FUNCTION IF EXISTS user_has_property_access;
DROP TABLE IF EXISTS household_members;

-- Rollback 007: Emergency Hub
DROP TABLE IF EXISTS insurance_info;
DROP TABLE IF EXISTS emergency_contacts;
DROP TABLE IF EXISTS shutoff_photos;
DROP TABLE IF EXISTS utility_shutoffs;

-- Rollback 006: Maintenance Calendar
DROP TABLE IF EXISTS completion_photos;
DROP TABLE IF EXISTS task_completions;
DROP TABLE IF EXISTS maintenance_tasks;
DROP TABLE IF EXISTS maintenance_task_templates;

-- Rollback 005: Home Profile
ALTER TABLE documents DROP CONSTRAINT IF EXISTS fk_documents_system;
ALTER TABLE documents DROP CONSTRAINT IF EXISTS fk_documents_appliance;
DROP TABLE IF EXISTS item_photos;
DROP TABLE IF EXISTS appliances;
DROP TABLE IF EXISTS systems;

-- Rollback 004: Document Vault
DROP TABLE IF EXISTS documents;
DROP TABLE IF EXISTS document_types;
DROP TABLE IF EXISTS document_categories;
DROP FUNCTION IF EXISTS update_document_search_vector;

-- Rollback 003: Properties
DROP TABLE IF EXISTS properties;

-- Rollback 002: Profiles
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user;
DROP FUNCTION IF EXISTS update_updated_at;
DROP TABLE IF EXISTS profiles;

-- Rollback 001: Enums
DROP TYPE IF EXISTS notification_channel;
DROP TYPE IF EXISTS contact_category;
DROP TYPE IF EXISTS utility_type;
DROP TYPE IF EXISTS recurrence_type;
DROP TYPE IF EXISTS task_priority;
DROP TYPE IF EXISTS diy_or_pro;
DROP TYPE IF EXISTS task_difficulty;
DROP TYPE IF EXISTS task_origin;
DROP TYPE IF EXISTS task_status;
DROP TYPE IF EXISTS appliance_category;
DROP TYPE IF EXISTS item_status;
DROP TYPE IF EXISTS system_category;
DROP TYPE IF EXISTS account_status;
DROP TYPE IF EXISTS subscription_tier;
```

---

## Table Count Summary

| Category | Tables | Purpose |
|----------|--------|---------|
| User | 3 | profiles, notification_preferences, push_tokens |
| Property | 1 | properties |
| Document Vault | 3 | document_categories, document_types, documents |
| Home Profile | 3 | systems, appliances, item_photos |
| Maintenance | 4 | maintenance_task_templates, maintenance_tasks, task_completions, completion_photos |
| Emergency Hub | 4 | utility_shutoffs, shutoff_photos, emergency_contacts, insurance_info |
| Household | 1 | household_members |
| Notifications | 1 | notification_log |
| **Total** | **20** | |

> **Upcoming Migration 012 (Notification Priority System):** The Notification Priority spec defines additional tables and columns needed before Phase 7 implementation:
> - **New table:** `notification_back_off` — tracks per-item, per-event-type back-off counters (consecutive_ignored count, backed_off flag)
> - **New table:** `task_notification_mutes` — per-task push notification silencing
> - **New table:** `document_notification_mutes` — per-document expiration reminder silencing
> - **New columns on `notification_log`:** `tier` (p1/p2/p3), `delivery_status` (pending/sent/digest_sent/push_skipped/etc.), `back_off_count`, `clicked_at`, `digest_id`
> - **New column on `notification_preferences`:** `preferred_frequency` (daily/weekly)
>
> See **HomeTrack Notification Priority §13** for complete SQL definitions. Apply as Migration 012 before building notification Edge Functions.

---

*End of Database Schema Document*
*HomeTrack — Version 1.1 — February 2026*
