---
name: migration-writer
description: Use this skill whenever creating, modifying, or reviewing database migrations for the HomeTrack (Keystona) app. Trigger when the user says 'add a table', 'new migration', 'schema change', 'add a column', 'database change', 'update the schema', 'create migration', 'add an index', 'RLS policy', or anything involving PostgreSQL DDL, table creation, enum additions, or database structure changes. Also trigger when reviewing existing migrations for correctness. This skill ensures all migrations follow the exact patterns established in the existing 11 migrations — UUID primary keys, audit columns, soft deletes, RLS policies, indexes, triggers, and rollback scripts.
---

# Migration Writer Skill — HomeTrack (Keystona)

## Core Rules

1. **All migrations require integrator approval.** Never create a migration without the user confirming.
2. **Migrations are sequential, never parallel.** Number them in order after the last existing migration.
3. **Every migration has a rollback script.** Always provide the corresponding DROP/ALTER statements.
4. **Test locally first.** `supabase db reset` must run cleanly with the new migration.

## Current State

**11 migrations exist** (001–011) creating **27 tables** across 6 storage buckets. See the Database Schema doc for the complete reference.

**Next migration number:** 012

## Table Template

Every new user-data table follows this exact pattern:

```sql
-- ============================================================
-- Migration 0XX: {Feature Name}
-- {Brief description of what this migration adds}
-- ============================================================

CREATE TABLE {table_name} (
  -- Primary key
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys (always include property_id and user_id for user data)
  property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Core fields
  name            TEXT NOT NULL,
  -- ... feature-specific fields ...

  -- Audit columns (REQUIRED on every table)
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ               -- Soft delete (include if records can be deleted)
);

-- Updated_at trigger (REQUIRED on every table with updated_at)
CREATE TRIGGER {table_name}_updated_at
  BEFORE UPDATE ON {table_name}
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS (REQUIRED on every user-data table)
ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own {table_name}"
  ON {table_name} FOR SELECT
  USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own {table_name}"
  ON {table_name} FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own {table_name}"
  ON {table_name} FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own {table_name}"
  ON {table_name} FOR DELETE
  USING (user_id = auth.uid());

-- Indexes (REQUIRED: at minimum, index on property_id)
CREATE INDEX idx_{table_name}_property ON {table_name}(property_id) WHERE deleted_at IS NULL;
-- Add additional indexes based on query patterns
```

## Column Type Conventions

| Data | Type | Example |
|------|------|---------|
| Primary keys | `UUID DEFAULT gen_random_uuid()` | `id` |
| Foreign keys | `UUID NOT NULL REFERENCES {table}(id) ON DELETE CASCADE` | `property_id` |
| Optional foreign keys | `UUID REFERENCES {table}(id) ON DELETE SET NULL` | `phase_id` |
| Short text | `TEXT NOT NULL` or `TEXT` | `name`, `description` |
| Long text | `TEXT` | `notes`, `content`, `ocr_text` |
| Enum values | Custom `CREATE TYPE` enum | `status`, `category` |
| Flexible categories | `TEXT` with comment listing expected values | `project_type`, `link_type` |
| Money | `NUMERIC(12,2)` for totals, `NUMERIC(10,2)` for line items | `estimated_budget`, `actual_cost` |
| Dates | `DATE` for calendar dates, `TIMESTAMPTZ` for timestamps | `due_date` vs `created_at` |
| Booleans | `BOOLEAN DEFAULT FALSE` | `is_favorite`, `is_paid` |
| Counts/small numbers | `SMALLINT` or `INTEGER` | `sort_order`, `rating` |
| Percentages | `SMALLINT CHECK ({col} BETWEEN 0 AND 100)` | `completion_percentage` |
| JSON data | `JSONB` | `specifications`, `metadata` |
| Arrays | `TEXT[]` or `UUID[]` | `tags`, `linked_document_ids` |
| File paths | `TEXT` | `file_path`, `thumbnail_path` |
| File sizes | `INTEGER` | `file_size_bytes` |

## Enum Conventions

```sql
-- Define enums at the top of the migration
-- Use lowercase snake_case values
-- Name the type descriptively: {domain}_{concept}

CREATE TYPE project_status AS ENUM ('planning', 'in_progress', 'on_hold', 'completed', 'cancelled');
CREATE TYPE budget_category AS ENUM ('materials', 'labor', 'permits', 'fixtures', 'equipment_rental', 'design', 'other');
```

**When to use enums vs TEXT:**
- **Use enum** when the values are fixed and enforced (status, category with known set)
- **Use TEXT** with a comment when values are flexible or may grow (project_type, link_type)

## Adding Columns to Existing Tables

```sql
-- ============================================================
-- Migration 0XX: Add {column} to {table}
-- ============================================================

ALTER TABLE {table_name}
  ADD COLUMN {column_name} {TYPE} {DEFAULT/CONSTRAINT};

-- If adding a NOT NULL column to a table with existing data:
-- Step 1: Add as nullable
ALTER TABLE {table_name} ADD COLUMN {column_name} {TYPE};

-- Step 2: Backfill existing rows
UPDATE {table_name} SET {column_name} = {default_value} WHERE {column_name} IS NULL;

-- Step 3: Add NOT NULL constraint
ALTER TABLE {table_name} ALTER COLUMN {column_name} SET NOT NULL;

-- Add index if the column will be filtered/sorted on
CREATE INDEX idx_{table}_{column} ON {table_name}({column_name});
```

## Adding Enum Values

```sql
-- PostgreSQL allows adding values to existing enums
ALTER TYPE {enum_name} ADD VALUE '{new_value}';

-- Note: You CANNOT remove enum values or rename them without recreating the type.
-- If you need to remove a value, create a new enum and migrate the column.
```

## Index Conventions

| Query Pattern | Index Type | Example |
|---------------|-----------|---------|
| Filter by FK | B-tree (default) | `CREATE INDEX idx_docs_property ON documents(property_id)` |
| Filter by FK + status | Composite B-tree | `CREATE INDEX idx_tasks_status ON tasks(property_id, status)` |
| Soft-delete filtered | Partial index | `CREATE INDEX idx_docs_property ON documents(property_id) WHERE deleted_at IS NULL` |
| Text search (fuzzy) | GIN with pg_trgm | `CREATE INDEX idx_docs_search ON documents USING gin(name gin_trgm_ops)` |
| Full-text search | GIN with tsvector | `CREATE INDEX idx_docs_ocr ON documents USING gin(ocr_search_vector)` |
| Sort by date | B-tree on date column | `CREATE INDEX idx_notes_date ON notes(project_id, note_date DESC)` |
| Unique constraint | Unique index | `UNIQUE(project_id, contact_id)` |

**Rules:**
- Every user-data table gets an index on `property_id` (always the first filter)
- Add composite indexes for common filter combinations (property + status, property + category)
- Use partial indexes with `WHERE deleted_at IS NULL` for soft-delete tables
- Don't over-index — each index slows down writes

## RPC / Function Template

```sql
CREATE OR REPLACE FUNCTION {function_name}(
  p_param1 UUID,
  p_param2 TEXT DEFAULT NULL
) RETURNS {return_type} AS $$
BEGIN
  -- Business logic here
  -- Use auth.uid() for user context

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- SECURITY DEFINER means this function runs with the owner's permissions,
-- bypassing RLS. Use ONLY when you need to aggregate across rows
-- or perform cross-table operations that RLS would block.
-- Always validate auth.uid() inside the function.
```

## Rollback Script Template

Every migration gets a corresponding rollback:

```sql
-- ============================================================
-- Rollback 0XX: {Feature Name}
-- ============================================================

-- Drop indexes first
DROP INDEX IF EXISTS idx_{table}_{column};

-- Drop policies
DROP POLICY IF EXISTS "Users can view own {table}" ON {table_name};
DROP POLICY IF EXISTS "Users can insert own {table}" ON {table_name};
DROP POLICY IF EXISTS "Users can update own {table}" ON {table_name};
DROP POLICY IF EXISTS "Users can delete own {table}" ON {table_name};

-- Drop triggers
DROP TRIGGER IF EXISTS {table_name}_updated_at ON {table_name};

-- Drop tables (in reverse dependency order)
DROP TABLE IF EXISTS {child_table};
DROP TABLE IF EXISTS {parent_table};

-- Drop enums (only if not used by other tables)
DROP TYPE IF EXISTS {enum_name};

-- For column additions:
ALTER TABLE {table_name} DROP COLUMN IF EXISTS {column_name};
```

## Seed Data Template

For lookup/template tables:

```sql
INSERT INTO {table_name} ({columns}) VALUES
  ('value1', 'description1', 1),
  ('value2', 'description2', 2),
  ('value3', 'description3', 3);
```

**Rules:**
- Lookup tables (categories, templates) have NO RLS — readable by all users
- Include `is_active BOOLEAN DEFAULT TRUE` for soft-deactivation without deletion
- Include `sort_order SMALLINT` for ordered display

## Checklist Before Submitting a Migration

- [ ] Migration number is sequential (after last existing: currently 011)
- [ ] File named: `supabase/migrations/0XX_{descriptive_name}.sql`
- [ ] All tables have: UUID PK, `created_at`, `updated_at` audit columns
- [ ] User-data tables have: `property_id`, `user_id`, RLS policies, `update_updated_at` trigger
- [ ] Soft-delete tables have: `deleted_at TIMESTAMPTZ` column
- [ ] Indexes added for primary query patterns
- [ ] Rollback script provided
- [ ] `supabase db reset` runs cleanly
- [ ] Database Schema doc updated with new tables
- [ ] API Contract doc updated with new endpoints (if applicable)
- [ ] Sprint Plan updated if this changes feature scope