# Services

This directory contains application-level services that handle cross-cutting concerns.

## Service Types

### `supabase_service.dart`
Supabase client initialization and configuration.

### `storage_service.dart`
File storage operations (Supabase Storage integration).

### `auth_service.dart`
Authentication service (wraps Supabase Auth).

### `analytics_service.dart`
PostHog analytics integration.

### `local_storage_service.dart`
SQLite database for offline-first features (especially Emergency Hub).

### `notification_service.dart`
Push notifications and local notification scheduling.

### `api_cache_service.dart`
Caching layer for external API calls (ATTOM, Weather, etc.).

## Usage

Services are typically provided as singletons through Riverpod providers:

```dart
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
```

Feature-specific business logic should live in `features/<feature_name>/services/`.
