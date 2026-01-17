---
title: "PostgreSQL UUID Column Rejects Empty Strings in INSERT"
problem_type: database_issue
severity: high
components:
  - Supabase
  - Flutter
  - PostgreSQL
symptom: "invalid input syntax for type uuid: ''"
date_encountered: 2026-01-17
date_resolved: 2026-01-17
---

# PostgreSQL UUID Column Rejects Empty Strings in INSERT

## Problem Description

When attempting to create a new system record in the `home_systems` table, the application threw a PostgreSQL validation error:

```
invalid input syntax for type uuid: ""
```

This error appeared when tapping the "Add System" button and submitting the form with valid data.

## Root Cause

The issue occurred because the Flutter app was sending an empty string (`""`) for the `id` field in the INSERT statement. PostgreSQL's UUID data type requires either:
- A valid UUID string (e.g., `"550e8400-e29b-41d4-a716-446655440000"`)
- NULL (if the column allows it)

**Empty strings are not valid UUID values.**

The problematic code was in `system_service.dart`:

```dart
// BEFORE (Broken)
Future<SystemResult<HomeSystem>> createSystem(HomeSystem system) async {
  try {
    final response = await _supabase
        .from('home_systems')
        .insert(system.toJson())  // Includes id: ""
        .select()
        .single();

    return SystemSuccess(HomeSystem.fromJson(response));
  } catch (e) {
    // Error thrown here
  }
}
```

The `system.toJson()` method was including all fields, including:
- `id: ""` (empty string from UI)
- `created_at: DateTime.now()` (client-generated)
- `updated_at: DateTime.now()` (client-generated)

However, the database schema defines these as auto-generated:
```sql
CREATE TABLE home_systems (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),  -- Auto-generated
  -- ...
  created_at TIMESTAMPTZ DEFAULT NOW(),            -- Auto-generated
  updated_at TIMESTAMPTZ DEFAULT NOW()             -- Auto-generated
);
```

## Investigation Steps

1. **Error Analysis**: Examined the error message showing UUID validation failure
2. **Code Review**: Checked `SystemSetupScreen` where `id: widget.existingSystem?.id ?? ''` was creating empty strings for new records
3. **Database Schema Review**: Confirmed that `id`, `created_at`, and `updated_at` have database-level defaults
4. **Service Layer Analysis**: Identified that `createSystem` was sending all fields to database

## Solution

Exclude auto-generated fields from the INSERT payload, allowing the database to generate them:

```dart
// AFTER (Fixed)
Future<SystemResult<HomeSystem>> createSystem(HomeSystem system) async {
  // Validate input
  final validationError = _validateSystem(system);
  if (validationError != null) {
    return SystemFailure(InvalidDataError(validationError));
  }

  try {
    // Exclude id, created_at, updated_at - let database generate these
    final json = system.toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');

    final response = await _supabase
        .from('home_systems')
        .insert(json)  // Only user-provided fields
        .select()
        .single();

    return SystemSuccess(HomeSystem.fromJson(response));
  } on PostgrestException catch (e) {
    return SystemFailure(_mapPostgrestException(e));
  } catch (e) {
    return SystemFailure(UnknownError(e.toString()));
  }
}
```

**Key changes:**
1. Convert model to JSON
2. Remove `id`, `created_at`, `updated_at` from the map
3. Send modified JSON to database
4. Database generates UUID via `uuid_generate_v4()`
5. Database generates timestamps via `NOW()`
6. `.select()` returns the complete record with generated values

## Prevention

### 1. **Pattern for Database Auto-Generated Fields**

When creating records with auto-generated fields:
- ✅ **DO**: Exclude auto-generated fields from INSERT payloads
- ❌ **DON'T**: Send empty strings or client-generated values for database-generated fields

### 2. **Consider Separate DTOs**

For complex models, consider separate Data Transfer Objects:

```dart
// Create DTO (no id, created_at, updated_at)
class CreateSystemRequest {
  final String propertyId;
  final String name;
  final SystemType systemType;
  // ... other user-provided fields only

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'name': name,
      'system_type': systemType.toDbValue(),
      // ... only fields user can set
    };
  }
}

// Update DTO (includes id, but not timestamps)
class UpdateSystemRequest {
  final String id;
  final String name;
  // ... fields that can be updated
}
```

### 3. **Alternative: Conditional JSON Serialization**

Another approach is to make `toJson()` context-aware:

```dart
Map<String, dynamic> toJson({bool forCreate = false}) {
  final json = {
    'property_id': propertyId,
    'name': name,
    'system_type': systemType.toDbValue(),
    // ... other fields
  };

  if (!forCreate) {
    json['id'] = id;
    json['created_at'] = createdAt.toIso8601String();
    json['updated_at'] = updatedAt.toIso8601String();
  }

  return json;
}

// Usage
await _supabase
    .from('home_systems')
    .insert(system.toJson(forCreate: true));
```

### 4. **Testing Strategy**

Add integration tests for create operations:

```dart
test('createSystem should exclude auto-generated fields', () async {
  final service = SystemService();

  final result = await service.createSystem(
    HomeSystem(
      id: '',  // Empty string should be excluded
      propertyId: testPropertyId,
      name: 'Test System',
      // ...
      createdAt: DateTime.now(),  // Should be excluded
      updatedAt: DateTime.now(),  // Should be excluded
    ),
  );

  expect(result, isA<SystemSuccess>());
  final system = (result as SystemSuccess).data;
  expect(system.id, isNotEmpty);  // Database generated
  expect(system.id.length, equals(36));  // Valid UUID format
});
```

## Related Issues

- Similar pattern needed for `updateSystem` (but includes `id`, excludes `created_at`)
- Property creation in `PropertyService` uses same pattern
- Any future tables with auto-generated UUIDs

## References

- **File**: `lib/features/system_registry/services/system_service.dart`
- **Migration**: `supabase/migrations/add_home_systems_table.sql`
- **Commit**: `fcdcbc2` - "fix(systems): Exclude auto-generated fields when creating new systems"
- **PR**: #10 - System Registry implementation

## Tags

`uuid` `postgresql` `supabase` `validation-error` `auto-generated-fields` `flutter` `insert`
