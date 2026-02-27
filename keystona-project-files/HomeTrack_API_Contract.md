# HomeTrack API Contract
## Complete Endpoint Specification — MVP

**Version 1.0 | February 2026**
**Status:** Active — Authoritative API reference for MVP development

---

## Table of Contents

1. [API Architecture](#1-api-architecture)
2. [Authentication](#2-authentication)
3. [Standard Patterns](#3-standard-patterns)
4. [Profile Endpoints](#4-profile-endpoints)
5. [Property Endpoints](#5-property-endpoints)
6. [Document Vault Endpoints](#6-document-vault-endpoints)
7. [Home Profile: Systems](#7-home-profile-systems)
8. [Home Profile: Appliances](#8-home-profile-appliances)
9. [Maintenance Calendar](#9-maintenance-calendar)
10. [Emergency Hub](#10-emergency-hub)
11. [Household Members](#11-household-members)
12. [Notifications](#12-notifications)
13. [Subscription & Payments](#13-subscription--payments)
14. [Edge Functions (Serverless)](#14-edge-functions)
15. [Realtime Subscriptions](#15-realtime-subscriptions)
16. [Rate Limits & Quotas](#16-rate-limits--quotas)
17. [Error Code Reference](#17-error-code-reference)

---

## 1. API Architecture

### Approach: Supabase Client SDK (Not REST)

HomeTrack uses **Supabase client libraries** as the primary API layer, not a custom REST API. This means:

- **Flutter** uses `supabase_flutter` SDK
- **Next.js** uses `@supabase/ssr` SDK
- Both SDKs talk directly to Supabase PostgREST (auto-generated REST from schema) and Supabase Storage
- **Edge Functions** handle complex operations that can't be done client-side (OCR, webhooks, cron jobs)
- **RLS policies** enforce authorization at the database level — the API doesn't need middleware auth checks

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────────────┐
│ Flutter App  │────▶│              │────▶│  PostgreSQL + RLS        │
│             │     │   Supabase   │     │  (data lives here)       │
│ Next.js Web │────▶│   Platform   │────▶│  Storage (files)         │
│             │     │              │────▶│  Edge Functions (logic)   │
└─────────────┘     └──────────────┘     └──────────────────────────┘

Client SDK calls:              Maps to:
supabase.from('documents')  →  PostgREST (auto-REST from schema)
supabase.storage             →  Storage API (file upload/download)
supabase.functions.invoke()  →  Edge Functions (custom logic)
supabase.auth                →  GoTrue (auth server)
```

### Why This Matters for Developers/Agents

You won't build traditional REST controllers. Instead:
1. **Schema IS the API** — table columns define request/response shapes
2. **RLS IS the auth** — policies enforce who can access what
3. **Edge Functions** handle anything the SDK can't do directly
4. **Views & RPCs** handle complex queries

---

## 2. Authentication

All endpoints require a valid JWT except where noted. Supabase Auth handles all flows.

### 2.1 Sign Up

```typescript
// Email + Password
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'securePassword123',
  options: {
    data: {
      full_name: 'Jane Smith',  // stored in raw_user_meta_data
    }
  }
});
```

**Response:** `{ user: User, session: Session }` or `{ error: AuthError }`

**Side effect:** Triggers `handle_new_user()` function → creates `profiles` row

### 2.2 Sign In

```typescript
// Email + Password
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'securePassword123',
});

// Google OAuth
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: { redirectTo: 'hometrack://auth/callback' }
});

// Apple Sign-In
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'apple',
  options: { redirectTo: 'hometrack://auth/callback' }
});

// Magic Link
const { data, error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com',
  options: { emailRedirectTo: 'hometrack://auth/callback' }
});
```

### 2.3 Sign Out

```typescript
const { error } = await supabase.auth.signOut();
```

### 2.4 Session Management

```typescript
// Get current session (JWT auto-refreshes)
const { data: { session } } = await supabase.auth.getSession();

// Listen for auth state changes
supabase.auth.onAuthStateChange((event, session) => {
  // 'SIGNED_IN' | 'SIGNED_OUT' | 'TOKEN_REFRESHED' | 'PASSWORD_RECOVERY'
});
```

### 2.5 Password Reset

```typescript
// Request reset email
const { error } = await supabase.auth.resetPasswordForEmail('user@example.com', {
  redirectTo: 'hometrack://auth/reset-password',
});

// Update password (after clicking reset link)
const { error } = await supabase.auth.updateUser({
  password: 'newSecurePassword456'
});
```

---

## 3. Standard Patterns

### 3.1 Standard Response Envelope

All Supabase client calls return:

```typescript
{
  data: T | null,       // The result (or null on error)
  error: {
    message: string,    // Human-readable error message
    code: string,       // Error code (e.g., 'PGRST116', '42501')
    details: string,    // Additional details
    hint: string,       // Suggested fix
  } | null,
  count: number | null  // Total count (when requested)
}
```

### 3.2 Pagination

```typescript
// Offset-based pagination (default)
const { data, count } = await supabase
  .from('documents')
  .select('*', { count: 'exact' })
  .range(0, 24)          // First 25 items (0-indexed)
  .order('created_at', { ascending: false });

// Cursor-based pagination (for large datasets)
const { data } = await supabase
  .from('maintenance_tasks')
  .select('*')
  .lt('created_at', lastItem.created_at)  // cursor
  .order('created_at', { ascending: false })
  .limit(25);
```

**Standard page size:** 25 items. Max: 100.

### 3.3 Filtering

```typescript
// Supabase PostgREST filter operators
.eq('column', value)       // equals
.neq('column', value)      // not equals
.gt('column', value)       // greater than
.gte('column', value)      // greater than or equal
.lt('column', value)       // less than
.lte('column', value)      // less than or equal
.like('column', '%pattern%')
.ilike('column', '%pattern%')  // case-insensitive
.in('column', [values])
.is('column', null)        // IS NULL
.not('column', 'is', null) // IS NOT NULL
.contains('column', value) // JSONB contains
.textSearch('search_vector', 'query')  // full-text search
```

### 3.4 Soft Deletes

The app never hard-deletes user data. Instead:

```typescript
// "Delete" = set deleted_at
const { error } = await supabase
  .from('documents')
  .update({ deleted_at: new Date().toISOString() })
  .eq('id', documentId);

// RLS policies automatically filter deleted_at IS NULL on SELECT
// No need to manually filter in queries
```

### 3.5 Type Definitions (TypeScript)

```typescript
// Auto-generate from schema
// npx supabase gen types typescript --project-id <ref> > src/types/database.ts

// Usage
import { Database } from './types/database';
type Document = Database['public']['Tables']['documents']['Row'];
type DocumentInsert = Database['public']['Tables']['documents']['Insert'];
type DocumentUpdate = Database['public']['Tables']['documents']['Update'];
```

---

## 4. Profile Endpoints

### 4.1 Get Current Profile

```typescript
const { data: profile } = await supabase
  .from('profiles')
  .select('*')
  .eq('id', userId)
  .single();
```

**Response shape:**

```typescript
{
  id: string,                    // UUID (matches auth.users.id)
  display_name: string | null,
  email: string | null,
  avatar_url: string | null,
  subscription_tier: 'free' | 'premium' | 'family',
  subscription_id: string | null,
  trial_started_at: string | null,
  trial_ends_at: string | null,
  account_status: 'active' | 'deactivated' | 'pending_deletion',
  onboarding_completed: boolean,
  onboarding_step: string,
  timezone: string,
  climate_zone: number | null,
  created_at: string,
  updated_at: string
}
```

### 4.2 Update Profile

```typescript
const { data, error } = await supabase
  .from('profiles')
  .update({
    display_name: 'Jane Smith',
    timezone: 'America/New_York',
    onboarding_step: 'property_setup',
  })
  .eq('id', userId)
  .select()
  .single();
```

### 4.3 Complete Onboarding

```typescript
const { error } = await supabase
  .from('profiles')
  .update({
    onboarding_completed: true,
    onboarding_step: 'complete',
  })
  .eq('id', userId);
```

### 4.4 Request Account Deletion

**Edge Function** (complex logic: grace period, email, scheduled job)

```typescript
const { data, error } = await supabase.functions.invoke('request-account-deletion', {
  body: {}
});
```

**Response:**

```typescript
{
  success: true,
  deletion_scheduled_at: '2026-04-22T00:00:00Z',  // 30 days from now
  message: 'Your account will be permanently deleted on April 22, 2026. You can reactivate anytime before then.'
}
```

### 4.5 Cancel Account Deletion

```typescript
const { data, error } = await supabase.functions.invoke('cancel-account-deletion', {
  body: {}
});
```

### 4.6 Export User Data (CCPA)

**Edge Function** (generates ZIP of all user data)

```typescript
const { data, error } = await supabase.functions.invoke('export-user-data', {
  body: {}
});
```

**Response:**

```typescript
{
  download_url: 'https://storage.supabase.co/signed/exports/user-123/export-2026-02-22.zip',
  expires_at: '2026-02-23T00:00:00Z',  // 24-hour download window
  file_size_bytes: 52428800
}
```

---

## 5. Property Endpoints

### 5.1 Get Property

```typescript
// Get user's property (MVP: one per user)
const { data: property } = await supabase
  .from('properties')
  .select('*')
  .single();  // RLS filters to current user automatically
```

**Response shape:**

```typescript
{
  id: string,
  user_id: string,
  address_line1: string,
  address_line2: string | null,
  city: string,
  state: string,
  zip_code: string,
  county: string | null,
  property_type: string,
  year_built: number | null,
  square_feet: number | null,
  lot_size_sqft: number | null,
  bedrooms: number | null,
  bathrooms: number | null,
  stories: number | null,
  garage_type: string | null,
  garage_spaces: number | null,
  purchase_date: string | null,
  purchase_price: number | null,
  down_payment: number | null,
  climate_zone: number | null,
  exterior_photo_path: string | null,
  created_at: string,
  updated_at: string
}
```

### 5.2 Create Property

```typescript
const { data, error } = await supabase
  .from('properties')
  .insert({
    user_id: userId,
    address_line1: '123 Oak Street',
    city: 'Austin',
    state: 'TX',
    zip_code: '78701',
    property_type: 'single_family',
    year_built: 1998,
    square_feet: 2200,
    bedrooms: 3,
    bathrooms: 2.5,
    purchase_date: '2025-11-15',
    purchase_price: 425000,
  })
  .select()
  .single();
```

**Error if user already has a property:** Unique constraint violation (MVP: one per user)

### 5.3 Update Property

```typescript
const { data, error } = await supabase
  .from('properties')
  .update({
    square_feet: 2400,
    bathrooms: 3,
  })
  .eq('id', propertyId)
  .select()
  .single();
```

### 5.4 Detect Climate Zone

**Edge Function** (looks up IECC climate zone from ZIP code)

```typescript
const { data, error } = await supabase.functions.invoke('detect-climate-zone', {
  body: { zip_code: '78701' }
});
```

**Response:**

```typescript
{
  climate_zone: 2,
  zone_description: 'Hot-Humid',
  heating_degree_days: 1688,
  cooling_degree_days: 2974
}
```

---

## 6. Document Vault Endpoints

### 6.1 List Documents

```typescript
const { data, count } = await supabase
  .from('documents')
  .select(`
    *,
    category:document_categories(id, name, icon, color),
    type:document_types(id, name)
  `, { count: 'exact' })
  .eq('property_id', propertyId)
  .order('created_at', { ascending: false })
  .range(0, 24);
```

**With filters:**

```typescript
// By category
.eq('category_id', categoryId)

// Expiring soon (next 90 days)
.lte('expiration_date', ninetyDaysFromNow)
.gte('expiration_date', today)

// Expired
.lt('expiration_date', today)
```

### 6.2 Get Single Document

```typescript
const { data } = await supabase
  .from('documents')
  .select(`
    *,
    category:document_categories(id, name, icon, color),
    type:document_types(id, name)
  `)
  .eq('id', documentId)
  .single();
```

### 6.3 Search Documents

```typescript
// Full-text search (Premium only — check subscription_tier first)
const { data } = await supabase
  .from('documents')
  .select('id, name, category_id, ocr_text, created_at')
  .textSearch('search_vector', searchQuery, {
    type: 'websearch',   // Supports AND, OR, NOT operators
    config: 'english'
  })
  .eq('property_id', propertyId)
  .limit(25);

// Basic search (Free tier — name and category only)
const { data } = await supabase
  .from('documents')
  .select('id, name, category_id, created_at')
  .ilike('name', `%${searchQuery}%`)
  .eq('property_id', propertyId)
  .limit(25);
```

### 6.4 Upload Document

**Two-step process:** upload file to Storage, then create database record.

```typescript
// Step 1: Upload file to Supabase Storage
const filePath = `${userId}/${propertyId}/${Date.now()}_${fileName}`;

const { data: uploadData, error: uploadError } = await supabase.storage
  .from('documents')
  .upload(filePath, file, {
    contentType: mimeType,
    upsert: false,
  });

// Step 2: Create document record
const { data: doc, error: docError } = await supabase
  .from('documents')
  .insert({
    property_id: propertyId,
    user_id: userId,
    name: documentName,
    category_id: categoryId,
    document_type_id: documentTypeId,    // optional
    file_path: filePath,
    file_size_bytes: fileSize,
    mime_type: mimeType,
    page_count: pageCount,
    metadata: { policy_number: 'HO-12345' },  // type-specific
    expiration_date: '2027-03-15',              // optional
    notes: 'Renewal due in March',              // optional
    linked_system_id: null,                     // optional
    linked_appliance_id: null,                  // optional
  })
  .select()
  .single();

// Step 3: OCR processing happens automatically via database webhook
// (See Edge Functions section)
```

**Free tier check:** Before inserting, count existing documents:

```typescript
const { count } = await supabase
  .from('documents')
  .select('*', { count: 'exact', head: true })
  .eq('property_id', propertyId);

if (subscriptionTier === 'free' && count >= 25) {
  throw new Error('FREE_TIER_DOCUMENT_LIMIT');
}
```

### 6.5 Update Document

```typescript
const { data, error } = await supabase
  .from('documents')
  .update({
    name: 'Updated Document Name',
    category_id: newCategoryId,
    expiration_date: '2028-01-01',
    metadata: { ...existingMetadata, policy_number: 'HO-99999' },
    notes: 'Updated notes',
  })
  .eq('id', documentId)
  .select()
  .single();
```

### 6.6 Delete Document (Soft)

```typescript
const { error } = await supabase
  .from('documents')
  .update({ deleted_at: new Date().toISOString() })
  .eq('id', documentId);
```

### 6.7 Get Document Download URL

```typescript
// Signed URL (expires in 1 hour)
const { data } = await supabase.storage
  .from('documents')
  .createSignedUrl(filePath, 3600);

// data.signedUrl → use for preview or download
```

### 6.8 Get Expiration Dashboard

```typescript
// Documents expiring within 90 days, sorted by urgency
const { data } = await supabase
  .from('documents')
  .select(`
    id, name, expiration_date,
    category:document_categories(name, icon, color)
  `)
  .eq('property_id', propertyId)
  .not('expiration_date', 'is', null)
  .lte('expiration_date', ninetyDaysFromNow)
  .order('expiration_date', { ascending: true });
```

### 6.9 List Categories

```typescript
// System categories + user's custom categories
const { data } = await supabase
  .from('document_categories')
  .select('*')
  .or(`is_system.eq.true,user_id.eq.${userId}`)
  .order('sort_order');
```

### 6.10 Create Custom Category

```typescript
const { data, error } = await supabase
  .from('document_categories')
  .insert({
    user_id: userId,
    name: 'Pool & Spa',
    icon: 'pool',
    color: '#0097A7',
    is_system: false,
    sort_order: 10,
  })
  .select()
  .single();
```

### 6.11 List Document Types (by Category)

```typescript
const { data } = await supabase
  .from('document_types')
  .select('*')
  .eq('category_id', categoryId)
  .order('sort_order');
```

---

## 7. Home Profile: Systems

### 7.1 List Systems

```typescript
const { data } = await supabase
  .from('systems')
  .select(`
    *,
    photos:item_photos(id, file_path, thumbnail_path, photo_type, caption)
  `)
  .eq('property_id', propertyId)
  .eq('status', 'active')
  .order('category');
```

### 7.2 Get System Detail

```typescript
const { data } = await supabase
  .from('systems')
  .select(`
    *,
    photos:item_photos(id, file_path, thumbnail_path, photo_type, caption),
    maintenance_tasks(id, name, status, due_date, last_completed:task_completions(completed_date))
  `)
  .eq('id', systemId)
  .single();
```

### 7.3 Create System

```typescript
const { data, error } = await supabase
  .from('systems')
  .insert({
    property_id: propertyId,
    user_id: userId,
    category: 'hvac',
    system_type: 'furnace_gas',
    name: 'Main Furnace',
    brand: 'Carrier',
    model: '59SC5A080E17--14',
    serial_number: '3114A00001',
    installation_date: '2018-10-15',
    location: 'Basement',
    expected_lifespan_min: 15,
    expected_lifespan_max: 20,
    warranty_expiration: '2028-10-15',
    estimated_replacement_cost: 5500,
  })
  .select()
  .single();

// IMPORTANT: After creating a system, trigger maintenance task generation
// This is handled by an Edge Function (see Section 14)
```

### 7.4 Update System

```typescript
const { data, error } = await supabase
  .from('systems')
  .update({
    status: 'needs_repair',
    notes: 'Making unusual noise during heating cycle',
  })
  .eq('id', systemId)
  .select()
  .single();
```

### 7.5 Upload System Photo

```typescript
// Step 1: Upload to storage
const filePath = `${userId}/${propertyId}/systems/${systemId}/${Date.now()}.jpg`;
const { data: upload } = await supabase.storage
  .from('item-photos')
  .upload(filePath, file);

// Step 2: Create photo record
const { data: photo } = await supabase
  .from('item_photos')
  .insert({
    user_id: userId,
    system_id: systemId,
    file_path: filePath,
    photo_type: 'model_label',
    caption: 'Model and serial number label',
  })
  .select()
  .single();
```

### 7.6 Get Lifespan Overview

**Database View or RPC** (calculated fields)

```typescript
const { data } = await supabase.rpc('get_system_lifespan_overview', {
  p_property_id: propertyId
});
```

**Response shape:**

```typescript
[{
  id: string,
  name: string,
  category: string,
  installation_date: string,
  age_years: number,              // calculated
  lifespan_min: number,
  lifespan_max: number,
  lifespan_percentage: number,    // age / avg lifespan * 100
  status: 'healthy' | 'aging' | 'end_of_life',  // calculated
  estimated_replacement_cost: number | null,
  years_until_replacement_min: number,  // calculated
  years_until_replacement_max: number,  // calculated
}]
```

**SQL for this RPC:**

```sql
CREATE OR REPLACE FUNCTION get_system_lifespan_overview(p_property_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category system_category,
  installation_date DATE,
  age_years NUMERIC,
  lifespan_min SMALLINT,
  lifespan_max SMALLINT,
  lifespan_percentage NUMERIC,
  health_status TEXT,
  estimated_replacement_cost NUMERIC,
  years_until_replacement_min NUMERIC,
  years_until_replacement_max NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.name,
    s.category,
    s.installation_date,
    ROUND(EXTRACT(EPOCH FROM (NOW() - s.installation_date)) / 31557600, 1) AS age_years,
    COALESCE(s.lifespan_override, s.expected_lifespan_min) AS lifespan_min,
    COALESCE(s.lifespan_override, s.expected_lifespan_max) AS lifespan_max,
    CASE WHEN s.installation_date IS NOT NULL THEN
      ROUND(
        EXTRACT(EPOCH FROM (NOW() - s.installation_date)) / 31557600 /
        ((COALESCE(s.lifespan_override, s.expected_lifespan_min) + COALESCE(s.lifespan_override, s.expected_lifespan_max)) / 2.0) * 100
      , 0)
    ELSE 0 END AS lifespan_percentage,
    CASE
      WHEN s.installation_date IS NULL THEN 'unknown'
      WHEN EXTRACT(EPOCH FROM (NOW() - s.installation_date)) / 31557600 >= COALESCE(s.lifespan_override, s.expected_lifespan_max) THEN 'end_of_life'
      WHEN EXTRACT(EPOCH FROM (NOW() - s.installation_date)) / 31557600 >= COALESCE(s.lifespan_override, s.expected_lifespan_min) * 0.75 THEN 'aging'
      ELSE 'healthy'
    END AS health_status,
    s.estimated_replacement_cost,
    GREATEST(0, COALESCE(s.lifespan_override, s.expected_lifespan_min) - EXTRACT(EPOCH FROM (NOW() - s.installation_date)) / 31557600) AS years_until_replacement_min,
    GREATEST(0, COALESCE(s.lifespan_override, s.expected_lifespan_max) - EXTRACT(EPOCH FROM (NOW() - s.installation_date)) / 31557600) AS years_until_replacement_max
  FROM systems s
  WHERE s.property_id = p_property_id
    AND s.deleted_at IS NULL
    AND s.status = 'active'
  ORDER BY lifespan_percentage DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 8. Home Profile: Appliances

Follows identical patterns to Systems. Key differences noted.

### 8.1 List Appliances

```typescript
const { data } = await supabase
  .from('appliances')
  .select(`
    *,
    photos:item_photos(id, file_path, thumbnail_path, photo_type, caption)
  `)
  .eq('property_id', propertyId)
  .eq('status', 'active')
  .order('category');
```

### 8.2 Create Appliance

```typescript
const { data, error } = await supabase
  .from('appliances')
  .insert({
    property_id: propertyId,
    user_id: userId,
    category: 'kitchen',
    appliance_type: 'refrigerator',
    name: 'Kitchen Refrigerator',
    brand: 'Samsung',
    model: 'RF28R7351SR',
    serial_number: 'JC1234567',
    purchase_date: '2023-06-10',
    purchase_price: 2199.99,
    retailer: 'Home Depot',
    location: 'Kitchen',
    expected_lifespan_min: 12,
    expected_lifespan_max: 14,
    warranty_expiration: '2025-06-10',
    specifications: {
      configuration: 'French Door',
      capacity_cu_ft: 28,
      has_ice_maker: true,
      has_water_dispenser: true,
      energy_star: true,
    },
  })
  .select()
  .single();
```

### 8.3 Update, Delete, Photo Upload

Same patterns as Systems (sections 7.4, 7.5). Replace `systems` with `appliances` and `system_id` with `appliance_id` in photo records.

---

## 9. Maintenance Calendar

### 9.1 List Tasks (Filtered)

```typescript
// All active tasks, sorted by due date
const { data } = await supabase
  .from('maintenance_tasks')
  .select(`
    *,
    system:systems(id, name, category),
    appliance:appliances(id, name, category),
    completions:task_completions(id, completed_date, completed_by, service_cost, materials_cost)
  `)
  .eq('property_id', propertyId)
  .in('status', ['scheduled', 'due', 'overdue'])
  .order('due_date', { ascending: true });

// Overdue only
.eq('status', 'overdue')

// This week
.gte('due_date', startOfWeek)
.lte('due_date', endOfWeek)

// By system
.eq('linked_system_id', systemId)

// By category
.eq('category', 'hvac')
```

### 9.2 Get Task Detail

```typescript
const { data } = await supabase
  .from('maintenance_tasks')
  .select(`
    *,
    system:systems(id, name, category, brand, model),
    appliance:appliances(id, name, category, brand, model),
    completions:task_completions(
      id, completed_date, completed_by, contractor_name,
      service_cost, materials_cost, time_spent_minutes, notes,
      photos:completion_photos(id, file_path, thumbnail_path, caption)
    ),
    template:maintenance_task_templates(instructions, tools_needed, supplies_needed)
  `)
  .eq('id', taskId)
  .single();
```

### 9.3 Create Custom Task

```typescript
const { data, error } = await supabase
  .from('maintenance_tasks')
  .insert({
    property_id: propertyId,
    user_id: userId,
    task_origin: 'custom',
    name: 'Replace bathroom caulking',
    description: 'Old caulk around master bathroom tub is peeling',
    category: 'interior',
    due_date: '2026-04-15',
    recurrence: 'none',
    difficulty: 'easy',
    diy_or_pro: 'diy',
    priority: 'medium',
    estimated_minutes: 45,
    tools_needed: ['caulk gun', 'utility knife', 'scraper'],
    supplies_needed: ['silicone caulk', 'painters tape'],
  })
  .select()
  .single();
```

### 9.4 Quick Complete Task

```typescript
// One-tap completion with auto-timestamp
const { data: completion } = await supabase
  .from('task_completions')
  .insert({
    task_id: taskId,
    user_id: userId,
    property_id: propertyId,
    completed_date: new Date().toISOString().split('T')[0],
    completed_by: 'diy',
  })
  .select()
  .single();

// Update task status
await supabase
  .from('maintenance_tasks')
  .update({ status: 'completed' })
  .eq('id', taskId);

// If recurring, schedule next occurrence (Edge Function)
await supabase.functions.invoke('schedule-next-task', {
  body: { task_id: taskId }
});
```

### 9.5 Detailed Complete Task

```typescript
const { data: completion } = await supabase
  .from('task_completions')
  .insert({
    task_id: taskId,
    user_id: userId,
    property_id: propertyId,
    completed_date: '2026-03-10',
    completed_by: 'contractor',
    contractor_name: 'Mike Rodriguez',
    contractor_company: 'Rodriguez HVAC',
    contractor_phone: '512-555-1234',
    service_cost: 189.00,
    materials_cost: 45.00,
    time_spent_minutes: 90,
    notes: 'Replaced capacitor and cleaned condenser coils. Tech recommended replacing unit within 2 years.',
    linked_document_ids: ['receipt-uuid-here'],
  })
  .select()
  .single();

// Update task status (same as quick complete)
```

### 9.6 Skip Task

```typescript
await supabase
  .from('maintenance_tasks')
  .update({
    status: 'skipped',
    skip_reason: 'Already done by contractor during annual service',
  })
  .eq('id', taskId);

// If recurring, schedule next occurrence
await supabase.functions.invoke('schedule-next-task', {
  body: { task_id: taskId }
});
```

### 9.7 Get Task Templates

```typescript
// Get templates relevant to user's climate zone and systems
const { data } = await supabase
  .from('maintenance_task_templates')
  .select('*')
  .eq('is_active', true)
  .order('season', { ascending: true })
  .order('sort_order');

// Client-side filter by climate zone:
// templates.filter(t => !t.climate_zones || t.climate_zones.includes(userClimateZone))
```

### 9.8 Generate Tasks from Templates

**Edge Function** (run after property + systems are set up)

```typescript
const { data, error } = await supabase.functions.invoke('generate-maintenance-tasks', {
  body: {
    property_id: propertyId,
    climate_zone: 4,
    system_categories: ['hvac', 'plumbing', 'roofing'],
  }
});
```

**Response:**

```typescript
{
  tasks_created: 18,
  categories: { hvac: 4, exterior: 6, interior: 5, plumbing: 2, safety: 1 }
}
```

### 9.9 Get Home Health Score

> **⚠ API UPDATE REQUIRED:** The response shape below is the original MVP definition. The Dashboard Spec and Health Score Algorithm spec define an **expanded response** that includes three-pillar breakdown (maintenance/documents/emergency sub-scores), momentum data, and score availability flag. See **HomeTrack Health Score Algorithm §9** for the updated RPC contract that must be implemented before dashboard development. The expanded response replaces this one.

**RPC** (aggregate calculation)

```typescript
const { data } = await supabase.rpc('get_home_health_score', {
  p_property_id: propertyId
});
```

**Original Response (to be replaced):**

```typescript
{
  score: 78,                    // 0-100
  total_tasks: 24,
  completed_on_time: 18,
  overdue: 3,
  skipped: 2,
  upcoming_this_month: 4,
  trend: 'improving'            // 'improving', 'stable', 'declining'
}
```

**See Health Score Algorithm §9.2 for the expanded response shape including:**
- `composite_score` (nullable for first 30 days)
- `maintenance`, `documents`, `emergency` pillar sub-scores with breakdown data
- `momentum` (completed_30d / total_30d)
- `trend_delta` for debugging

### 9.10 Get Dashboard Data (Proposed Aggregated RPC)

> **Future implementation:** The **Dashboard Spec §14** proposes a `get_dashboard_data(property_id)` aggregated RPC that returns all data needed to render the Home tab in a single call: health score, pillar breakdowns, upcoming tasks, overdue count, active insights, urgent items, and momentum stats. This reduces the Home tab from 5-6 individual queries to 1 RPC call. Define and implement during Phase 0.8 (Dashboard) or Phase 8 (Polish).

---

## 10. Emergency Hub

### 10.1 List Utility Shutoffs

```typescript
const { data } = await supabase
  .from('utility_shutoffs')
  .select(`
    *,
    photos:shutoff_photos(id, file_path, thumbnail_path, photo_type, caption, file_size_bytes)
  `)
  .eq('property_id', propertyId)
  .order('utility_type');
```

### 10.2 Create/Update Shutoff

```typescript
// Create water shutoff
const { data, error } = await supabase
  .from('utility_shutoffs')
  .upsert({
    id: existingId || undefined,        // upsert: update if exists
    property_id: propertyId,
    user_id: userId,
    utility_type: 'water',
    location_description: 'Basement, left wall next to water heater, 3 feet from floor',
    valve_type: 'ball',
    turn_direction: 'clockwise (quarter turn)',
    tools_required: ['none'],
    special_instructions: 'Blue handle. Turn 90 degrees until perpendicular to pipe.',
    is_complete: true,
  })
  .select()
  .single();
```

### 10.3 Upload Shutoff Photo

```typescript
const filePath = `${userId}/${propertyId}/shutoffs/${shutoffId}/${Date.now()}.jpg`;

// Compress to <500KB before upload (client-side)
const { data: upload } = await supabase.storage
  .from('shutoff-photos')
  .upload(filePath, compressedFile);

const { data: photo } = await supabase
  .from('shutoff_photos')
  .insert({
    shutoff_id: shutoffId,
    user_id: userId,
    file_path: filePath,
    photo_type: 'location',
    caption: 'Water main shutoff - basement left wall',
    file_size_bytes: compressedFile.size,
  })
  .select()
  .single();
```

### 10.4 List Emergency Contacts

```typescript
const { data } = await supabase
  .from('emergency_contacts')
  .select('*')
  .eq('property_id', propertyId)
  .order('is_favorite', { ascending: false })
  .order('category');
```

### 10.5 Create Emergency Contact

```typescript
const { data, error } = await supabase
  .from('emergency_contacts')
  .insert({
    property_id: propertyId,
    user_id: userId,
    name: 'Mike Rodriguez',
    company_name: 'Rodriguez Plumbing',
    category: 'plumber',
    phone_primary: '512-555-1234',
    is_24x7: true,
    is_favorite: true,
    notes: 'Recommended by neighbor. Fast response for emergencies.',
  })
  .select()
  .single();
```

### 10.6 Get/Set Insurance Info

```typescript
// List all insurance
const { data } = await supabase
  .from('insurance_info')
  .select('*')
  .eq('property_id', propertyId)
  .order('policy_type');

// Create/update
const { data, error } = await supabase
  .from('insurance_info')
  .upsert({
    property_id: propertyId,
    user_id: userId,
    policy_type: 'homeowners',
    carrier: 'State Farm',
    policy_number: 'HO-55-1234567',
    coverage_amount: 425000,
    deductible: 2500,
    premium_annual: 2100,
    agent_name: 'Sarah Johnson',
    agent_phone: '512-555-9876',
    claims_phone: '800-732-5246',
    effective_date: '2025-12-01',
    expiration_date: '2026-12-01',
  })
  .select()
  .single();
```

### 10.7 Get Emergency Hub Sync Payload

**Edge Function** (returns everything needed for offline cache)

```typescript
const { data } = await supabase.functions.invoke('emergency-hub-sync', {
  body: { property_id: propertyId }
});
```

**Response:**

```typescript
{
  shutoffs: [...],           // All shutoff records with inline photo URLs
  contacts: [...],           // All emergency contacts
  insurance: [...],          // All insurance policies
  photo_urls: {              // Signed URLs for offline download
    'shutoff-photo-1': 'https://signed-url...',
    'shutoff-photo-2': 'https://signed-url...',
  },
  synced_at: '2026-02-22T15:00:00Z'
}
```

---

## 11. Household Members

### 11.1 List Members

```typescript
const { data } = await supabase
  .from('household_members')
  .select(`
    *,
    member:profiles!member_user_id(id, display_name, email, avatar_url)
  `)
  .eq('property_id', propertyId)
  .neq('invite_status', 'removed');
```

### 11.2 Invite Member

```typescript
const { data, error } = await supabase.functions.invoke('invite-household-member', {
  body: {
    property_id: propertyId,
    email: 'spouse@example.com',
  }
});
```

**Response:**

```typescript
{
  id: 'member-uuid',
  invite_status: 'pending',
  invited_email: 'spouse@example.com',
  invite_token: 'abc123...',
  message: 'Invitation sent to spouse@example.com'
}
```

**Tier check:** Edge Function enforces member limits (Free: 1, Premium: 2, Family: 5)

### 11.3 Accept Invite

```typescript
const { data, error } = await supabase.functions.invoke('accept-household-invite', {
  body: { invite_token: 'abc123...' }
});
```

### 11.4 Remove Member

```typescript
const { error } = await supabase
  .from('household_members')
  .update({ invite_status: 'removed' })
  .eq('id', memberId)
  .eq('owner_user_id', userId);  // Only owner can remove
```

---

## 12. Notifications

> **Cross-reference:** The **HomeTrack Notification Priority** spec defines the complete priority tier system (P1/P2/P3), daily digest batching logic, back-off rules, per-task muting, and quiet hours behavior. It also defines **database schema additions** (Migration 012) including `notification_back_off`, `task_notification_mutes`, and `document_notification_mutes` tables, plus additional columns on `notification_log`. Implement those schema changes before building the notification Edge Functions.

### 12.1 Get Notification Preferences

```typescript
const { data } = await supabase
  .from('notification_preferences')
  .select('*')
  .eq('user_id', userId)
  .single();
```

### 12.2 Update Preferences

```typescript
const { data, error } = await supabase
  .from('notification_preferences')
  .upsert({
    user_id: userId,
    notifications_enabled: true,
    quiet_hours_start: '22:00',
    quiet_hours_end: '08:00',
    preferred_day: 'saturday',
    preferred_time: '09:00',
    maintenance_reminders: true,
    expiration_alerts: true,
    maintenance_channel: 'push',
    expiration_channel: 'both',
  })
  .select()
  .single();
```

### 12.3 Register Push Token

```typescript
const { error } = await supabase
  .from('push_tokens')
  .upsert({
    user_id: userId,
    token: fcmToken,
    platform: 'ios',                 // 'ios' | 'android' | 'web'
    device_id: deviceIdentifier,
    is_active: true,
  });
```

### 12.4 Get Notification History

```typescript
const { data } = await supabase
  .from('notification_log')
  .select('*')
  .eq('user_id', userId)
  .order('sent_at', { ascending: false })
  .limit(50);
```

### 12.5 Mark Notification Read

```typescript
const { error } = await supabase
  .from('notification_log')
  .update({ read_at: new Date().toISOString() })
  .eq('id', notificationId);
```

### 12.6 Get Unread Count

```typescript
const { count } = await supabase
  .from('notification_log')
  .select('*', { count: 'exact', head: true })
  .eq('user_id', userId)
  .is('read_at', null);
```

---

## 13. Subscription & Payments

Subscriptions are managed by **RevenueCat** (mobile) and **Stripe** (web). The app does NOT handle payment logic directly.

### 13.1 Check Subscription Status

```typescript
// Read from profiles table (updated by RevenueCat webhook)
const { data } = await supabase
  .from('profiles')
  .select('subscription_tier, subscription_id, trial_started_at, trial_ends_at')
  .eq('id', userId)
  .single();
```

### 13.2 RevenueCat Webhook Handler

**Edge Function:** `supabase/functions/revenuecat-webhook`

Receives events from RevenueCat and updates `profiles.subscription_tier`.

```typescript
// Webhook events handled:
// INITIAL_PURCHASE     → set tier to 'premium' or 'family'
// RENEWAL              → keep tier (log renewal)
// CANCELLATION         → schedule downgrade at period end
// EXPIRATION           → set tier to 'free'
// BILLING_ISSUE        → flag for follow-up
// SUBSCRIBER_ALIAS     → link RevenueCat ID
```

### 13.3 Feature Gating Pattern

```typescript
// Client-side feature check
function canAccess(feature: string, tier: SubscriptionTier): boolean {
  const premiumFeatures = [
    'ocr_search',
    'unlimited_documents',
    'weather_alerts',
    'refinance_alerts',
    'plaid_sync',
    'home_history_report',
    'receipt_scanner',
  ];

  const familyFeatures = [
    ...premiumFeatures,
    'multi_property',        // future
    'five_household_members',
  ];

  if (tier === 'family') return true;
  if (tier === 'premium') return premiumFeatures.includes(feature);
  
  // Free tier features
  const freeFeatures = [
    'basic_search',
    'document_upload_25',
    'maintenance_calendar',
    'emergency_hub',
    'home_profile',
    'one_household_member',
  ];
  return freeFeatures.includes(feature);
}
```

---

## 14. Edge Functions

Edge Functions handle operations that can't be done directly through the Supabase client SDK.

### 14.1 Function Inventory

| Function | Trigger | Purpose |
|----------|---------|---------|
| `process-document-ocr` | Database webhook (document INSERT) | Run OCR, update search index |
| `generate-maintenance-tasks` | Called after property + systems setup | Create tasks from templates |
| `schedule-next-task` | Called after task completion/skip | Schedule recurring task |
| `check-expirations` | Cron (daily at 9:00 AM UTC) | Find expiring docs, send reminders |
| `check-overdue-tasks` | Cron (daily at 9:00 AM UTC) | Update overdue status, send reminders |
| `detect-climate-zone` | Called during property setup | ZIP → IECC climate zone lookup |
| `emergency-hub-sync` | Called on app open | Bundle all emergency data for offline |
| `invite-household-member` | Called from UI | Validate tier limits, send invite email |
| `accept-household-invite` | Called from invite link | Link member to property |
| `request-account-deletion` | Called from UI | Start 30-day grace period |
| `cancel-account-deletion` | Called from UI | Cancel pending deletion |
| `export-user-data` | Called from UI (CCPA) | Generate ZIP of all user data |
| `revenuecat-webhook` | HTTP POST from RevenueCat | Update subscription tier |
| `send-push-notification` | Called by other functions | FCM delivery with preference checks |

### 14.2 OCR Processing Pipeline

**Function:** `process-document-ocr`

```
Trigger: New row in documents table (INSERT webhook)
    │
    ├── 1. Update ocr_status → 'processing'
    │
    ├── 2. Download file from Storage
    │
    ├── 3. If image: send to Google Cloud Vision API
    │   If PDF: extract text, then OCR each page
    │
    ├── 4. Store extracted text in documents.ocr_text
    │
    ├── 5. Auto-detect category (keyword matching)
    │   └── Suggest category if different from user's choice
    │
    ├── 6. Extract expiration date (pattern matching)
    │   └── If found and documents.expiration_date is NULL, set it
    │
    ├── 7. Generate thumbnail (first page)
    │   └── Upload to Storage, update documents.thumbnail_path
    │
    ├── 8. Update ocr_status → 'complete'
    │
    └── 9. On error: update ocr_status → 'failed', log error
```

### 14.3 Cron Jobs

```typescript
// Configured in supabase/config.toml or via pg_cron

// Daily expiration check (9 AM UTC)
SELECT cron.schedule('check-expirations', '0 9 * * *', $$
  SELECT net.http_post(
    url := 'https://<project>.supabase.co/functions/v1/check-expirations',
    headers := '{"Authorization": "Bearer <service_role_key>"}'::jsonb
  );
$$);

// Daily overdue task check (9 AM UTC)
SELECT cron.schedule('check-overdue-tasks', '0 9 * * *', $$
  SELECT net.http_post(
    url := 'https://<project>.supabase.co/functions/v1/check-overdue-tasks',
    headers := '{"Authorization": "Bearer <service_role_key>"}'::jsonb
  );
$$);

// Account deletion cleanup (midnight UTC)
SELECT cron.schedule('cleanup-deleted-accounts', '0 0 * * *', $$
  SELECT net.http_post(
    url := 'https://<project>.supabase.co/functions/v1/cleanup-deleted-accounts',
    headers := '{"Authorization": "Bearer <service_role_key>"}'::jsonb
  );
$$);
```

---

## 15. Realtime Subscriptions

Use Supabase Realtime for cross-device sync (e.g., spouse adds document on their phone, it appears on yours).

```typescript
// Subscribe to document changes for a property
const channel = supabase
  .channel('property-documents')
  .on(
    'postgres_changes',
    {
      event: '*',                        // INSERT, UPDATE, DELETE
      schema: 'public',
      table: 'documents',
      filter: `property_id=eq.${propertyId}`,
    },
    (payload) => {
      // payload.eventType: 'INSERT' | 'UPDATE' | 'DELETE'
      // payload.new: the new row
      // payload.old: the old row (for UPDATE/DELETE)
      handleDocumentChange(payload);
    }
  )
  .subscribe();

// Subscribe to maintenance task updates
const taskChannel = supabase
  .channel('property-tasks')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'maintenance_tasks',
      filter: `property_id=eq.${propertyId}`,
    },
    handleTaskChange
  )
  .subscribe();

// Cleanup on unmount
supabase.removeChannel(channel);
supabase.removeChannel(taskChannel);
```

---

## 16. Rate Limits & Quotas

### Supabase Defaults (Pro Plan)

| Resource | Limit |
|----------|-------|
| API requests | 1,000 req/sec |
| Realtime connections | 500 concurrent |
| Edge Function invocations | 500K/month |
| Edge Function execution time | 150 seconds max |
| Storage upload size | 50MB per file |
| Database connections | 60 direct, 200 pooled |

### Application-Level Limits

| Action | Limit | Enforcement |
|--------|-------|-------------|
| Document uploads (free) | 25 total | Client check + RPC guard |
| Document uploads (premium) | Unlimited | No limit |
| OCR processing | 1 per document | Edge Function |
| Household invites (free) | 1 member | Edge Function |
| Household invites (premium) | 2 members | Edge Function |
| Household invites (family) | 5 members | Edge Function |
| Push notifications per user | Max 5/day | Edge Function batching |
| Search queries | 10 req/sec per user | Client-side debounce |
| File upload size | 25MB per document | Storage bucket policy |
| Shutoff photo size | 500KB compressed | Client-side compression |

---

## 17. Error Code Reference

### Standard HTTP Errors (from PostgREST)

| Code | Meaning | Common Cause |
|------|---------|-------------|
| `400` | Bad Request | Malformed request, invalid filter |
| `401` | Unauthorized | Missing or expired JWT |
| `403` | Forbidden | RLS policy denied access |
| `404` | Not Found | Resource doesn't exist or filtered by RLS |
| `406` | Not Acceptable | Missing `Accept` header |
| `409` | Conflict | Unique constraint violation (e.g., duplicate property) |
| `413` | Payload Too Large | File exceeds size limit |
| `422` | Unprocessable | Schema validation failed |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Error | Server-side failure |

### Application Error Codes

| Error Code | HTTP Status | Description | Client Action |
|------------|-------------|-------------|---------------|
| `FREE_TIER_DOCUMENT_LIMIT` | 403 | Free tier 25-document limit reached | Show upgrade prompt |
| `FREE_TIER_MEMBER_LIMIT` | 403 | Free tier household member limit | Show upgrade prompt |
| `PREMIUM_MEMBER_LIMIT` | 403 | Premium 2-member limit reached | Show Family upgrade |
| `PROPERTY_ALREADY_EXISTS` | 409 | User already has a property (MVP) | Navigate to existing property |
| `OCR_PROCESSING_FAILED` | 500 | OCR extraction failed | Show document without search; allow retry |
| `CLIMATE_ZONE_NOT_FOUND` | 404 | ZIP code not in climate zone database | Allow manual zone selection |
| `INVITE_ALREADY_SENT` | 409 | Email already has pending invite | Show existing invite status |
| `INVITE_TOKEN_EXPIRED` | 410 | Invite link has expired | Owner must resend invite |
| `ACCOUNT_PENDING_DELETION` | 403 | Account in 30-day grace period | Show reactivation option |
| `FILE_TYPE_NOT_ALLOWED` | 415 | Unsupported file format | Show supported formats |
| `FILE_TOO_LARGE` | 413 | File exceeds 25MB limit | Show size limit, suggest compression |
| `SUBSCRIPTION_REQUIRED` | 403 | Feature requires Premium/Family | Show feature gate with upgrade CTA |

### Error Response Shape (Edge Functions)

```typescript
// All Edge Functions return this shape on error
{
  error: true,
  code: 'FREE_TIER_DOCUMENT_LIMIT',
  message: 'You have reached the 25-document limit on the Free plan.',
  action: 'upgrade',                    // hint for client: 'upgrade', 'retry', 'contact_support'
  details: {
    current_count: 25,
    limit: 25,
    tier: 'free',
  }
}
```

---

## Endpoint Count Summary

| Category | Client SDK Calls | Edge Functions | RPCs | Total |
|----------|-----------------|----------------|------|-------|
| Auth | 6 | — | — | 6 |
| Profile | 3 | 3 | — | 6 |
| Property | 3 | 1 | — | 4 |
| Document Vault | 11 | 1 (OCR) | — | 12 |
| Systems | 5 | — | 1 | 6 |
| Appliances | 4 | — | — | 4 |
| Maintenance | 7 | 2 | 1 | 10 |
| Emergency Hub | 7 | 1 | — | 8 |
| Household | 3 | 2 | — | 5 |
| Notifications | 5 | 1 | — | 6 |
| Payments | 1 | 1 | — | 2 |
| **Total** | **55** | **12** | **2** | **69** |

---

*End of API Contract*
*HomeTrack — Version 1.0 — February 2026*
