---
name: supabase-agent
description: Use this skill whenever writing Supabase queries, RLS policies, Edge Functions, database RPCs, storage operations, or any backend code for the HomeTrack (Keystona) app. Trigger for ANY database interaction — queries, inserts, updates, deletes, real-time subscriptions, file uploads/downloads, or auth operations. Also trigger when the user mentions 'Supabase', 'database', 'query', 'RLS', 'Edge Function', 'storage bucket', 'migration', 'API call', 'backend', or anything involving data access patterns. This skill prevents N+1 queries, enforces security patterns, and ensures all data access follows project conventions.
---

# Supabase Agent Skill — HomeTrack (Keystona)

## Core Architecture

HomeTrack uses Supabase as the backend. The Supabase client SDK IS the API — there is no separate REST API layer. Row Level Security (RLS) IS the auth layer — every table has policies that enforce data isolation per user.

**Stack:** Supabase (PostgreSQL 15, GoTrue Auth, Storage, Edge Functions, Realtime)

## Critical Rules (Never Violate)

1. **Always filter by `property_id` first.** Every user-data query starts with `.eq('property_id', propertyId)`. This hits the primary index.
2. **Always check `deleted_at IS NULL`.** Use `.is_('deleted_at', null)` on every query for tables with soft deletes.
3. **Select only needed columns.** Never use `.select('*')` on list screens. Specify the exact columns the UI needs.
4. **Use nested selects, not N+1 queries.** Join related data in a single query using PostgREST nested syntax.
5. **Never bypass RLS.** All client-side queries go through RLS. Only Edge Functions with `SECURITY DEFINER` RPCs can bypass, and only when explicitly needed.
6. **User ID from auth, not client.** Always use `auth.uid()` in RLS policies. Never trust a `user_id` passed from the client for authorization.

## Query Patterns

### List Queries (Card Data Only)

```dart
// ✅ CORRECT — only fields needed for list card
final docs = await supabase
  .from('documents')
  .select('id, name, category_id, thumbnail_path, created_at, expiration_date, mime_type')
  .eq('property_id', propertyId)
  .is_('deleted_at', null)
  .order('created_at', ascending: false)
  .range(0, 24);  // Page 1, 25 items

// ❌ WRONG — selects everything including OCR text blob
final docs = await supabase
  .from('documents')
  .select('*')
  .eq('property_id', propertyId);
```

### Detail Queries (Full Data + Relations)

```dart
// ✅ CORRECT — single query with nested joins
final project = await supabase
  .from('projects')
  .select('''
    *,
    phases:project_phases(id, name, status, sort_order, planned_start_date, planned_end_date),
    budget_items:project_budget_items(id, name, category, estimated_cost, actual_cost, is_paid),
    contractors:project_contractors(
      id, role, contract_amount, rating,
      contact:emergency_contacts(id, name, company_name, phone_primary, category)
    ),
    photos:project_photos(id, file_path, thumbnail_path, photo_type, pair_id, room_area, caption),
    notes:project_notes(id, title, content, note_date)
  ''')
  .eq('id', projectId)
  .single();

// ❌ WRONG — 6 separate queries (N+1)
final project = await supabase.from('projects').select().eq('id', projectId).single();
final phases = await supabase.from('project_phases').select().eq('project_id', projectId);
// ... and 4 more queries
```

### Insert Patterns

```dart
// ✅ Always include user_id and property_id, return the created record
final { data, error } = await supabase
  .from('documents')
  .insert({
    'property_id': propertyId,
    'user_id': userId,
    'name': name,
    'category_id': categoryId,
    // ... other fields
  })
  .select()
  .single();

if (error != null) {
  // Handle per Error Handling Guide
}
```

### Update Patterns

```dart
// ✅ Update by ID, return updated record
final { data, error } = await supabase
  .from('projects')
  .update({
    'status': 'in_progress',
    'actual_start_date': DateTime.now().toIso8601String(),
  })
  .eq('id', projectId)
  .select()
  .single();
```

### Soft Delete Pattern

```dart
// ✅ Soft delete — set deleted_at, show undo snackbar
final { error } = await supabase
  .from('documents')
  .update({ 'deleted_at': DateTime.now().toIso8601String() })
  .eq('id', documentId);

// Show undo snackbar (5 seconds)
// If undo tapped:
await supabase
  .from('documents')
  .update({ 'deleted_at': null })
  .eq('id', documentId);
```

### Count Query (Tier Limit Checks)

```dart
// ✅ Count without fetching data — for free tier checks
final { count } = await supabase
  .from('documents')
  .select('*', const FetchOptions(count: CountOption.exact, head: true))
  .eq('property_id', propertyId)
  .is_('deleted_at', null);

if (tier == 'free' && count! >= 25) {
  // Show upgrade sheet
}
```

### Pagination Pattern

```dart
// ✅ Offset-based pagination
const pageSize = 25;

Future<List<Document>> loadPage(int page) async {
  final start = page * pageSize;
  final end = start + pageSize - 1;

  return supabase
    .from('documents')
    .select('id, name, category_id, thumbnail_path, created_at')
    .eq('property_id', propertyId)
    .is_('deleted_at', null)
    .order('created_at', ascending: false)
    .range(start, end);
}
```

## Storage Operations

### Upload Pattern

```dart
// ✅ Correct file path structure: {user_id}/{property_id}/filename
final filePath = '$userId/$propertyId/${DateTime.now().millisecondsSinceEpoch}.jpg';

final { data, error } = await supabase.storage
  .from('documents')  // bucket name
  .upload(filePath, file, fileOptions: FileOptions(
    contentType: 'image/jpeg',
    upsert: false,
  ));
```

### Signed URL (for reading)

```dart
// ✅ Get signed URL with 1-hour expiry
final url = await supabase.storage
  .from('documents')
  .createSignedUrl(filePath, 3600);  // 3600 seconds = 1 hour
```

### Thumbnail via Transform

```dart
// ✅ Request transformed image — never load full-size for thumbnails
final url = supabase.storage
  .from('documents')
  .getPublicUrl(filePath, transform: TransformOptions(
    width: 120,
    height: 120,
    resize: ResizeMode.cover,
    quality: 70,
  ));
```

### Storage Buckets Reference

| Bucket | Max Size | MIME Types | Use |
|--------|----------|------------|-----|
| `documents` | 25MB | PDF, JPEG, PNG, HEIC, WebP | Document Vault files |
| `item-photos` | 10MB | JPEG, PNG, HEIC, WebP | System/appliance photos |
| `shutoff-photos` | 5MB (500KB compressed) | JPEG, PNG | Emergency shutoff photos |
| `completion-photos` | 10MB | JPEG, PNG, HEIC, WebP | Maintenance completion photos |
| `property-photos` | 10MB | JPEG, PNG, HEIC, WebP | Property exterior photos |
| `project-photos` | 10MB | JPEG, PNG, HEIC, WebP | Project before/after/progress |

## RLS Policy Patterns

Every user-data table MUST have these 4 policies:

```sql
-- SELECT: User can only see their own data
CREATE POLICY "Users can view own {table}"
  ON {table} FOR SELECT
  USING (user_id = auth.uid());

-- INSERT: User can only create their own data
CREATE POLICY "Users can insert own {table}"
  ON {table} FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- UPDATE: User can only modify their own data
CREATE POLICY "Users can update own {table}"
  ON {table} FOR UPDATE
  USING (user_id = auth.uid());

-- DELETE: User can only delete their own data
CREATE POLICY "Users can delete own {table}"
  ON {table} FOR DELETE
  USING (user_id = auth.uid());
```

**Lookup tables (categories, templates) have NO RLS** — they're read-only for all users.

## Edge Function Patterns

```typescript
// supabase/functions/{function-name}/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    // 1. Auth check
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No auth token' }), { status: 401 });
    }

    // 2. Create authenticated client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // 3. Get user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    // 4. Business logic here
    const body = await req.json();
    // ...

    // 5. Return response
    return new Response(JSON.stringify({ data: result }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
```

## Error Handling for Supabase Calls

```dart
// ✅ Standard error handling pattern
try {
  final response = await supabase.from('documents').select().eq('id', id).single();
  return Document.fromJson(response);
} on PostgrestException catch (e) {
  if (e.code == 'PGRST116') {
    // Not found
    throw DocumentNotFoundException();
  }
  throw DatabaseException(e.message);
} on AuthException catch (e) {
  // Token expired, session invalid
  throw AuthenticationException(e.message);
} catch (e) {
  throw UnexpectedException(e.toString());
}
```

## Key Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| `PGRST116` | Row not found (`.single()` returned 0) | Show "not found" or navigate back |
| `23505` | Unique constraint violation | Show "already exists" message |
| `23503` | Foreign key violation | Related data doesn't exist |
| `42501` | RLS policy violation | User doesn't own this data |
| `57014` | Query timeout | Retry with simpler query |

## Key Project References

- **Database Schema** — All 27 tables, indexes, RLS policies, seed data
- **API Contract** — All 84 endpoints with exact query patterns
- **Performance Guide** — Query optimization, caching, pagination strategies
- **Error Handling Guide** — Supabase error code handling patterns
