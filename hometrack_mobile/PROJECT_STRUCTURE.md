# Keystona Mobile - Project Structure

This document explains the folder organization for the Keystona Flutter mobile application.

## Overview

```
lib/
├── main.dart                          # App entry point
├── config/                            # App configuration
│   ├── env_config.dart               # Environment variables
│   └── app_config.dart               # App-level settings
├── core/                              # Shared code
│   ├── constants/                    # App constants
│   ├── theme/                        # Keystona design system
│   ├── utils/                        # Helper functions
│   └── widgets/                      # Shared widgets
├── services/                          # Application services
│   ├── supabase_service.dart         # Supabase client
│   ├── storage_service.dart          # File storage
│   ├── auth_service.dart             # Authentication
│   ├── analytics_service.dart        # PostHog integration
│   ├── local_storage_service.dart    # SQLite for offline
│   ├── notification_service.dart     # Push notifications
│   └── api_cache_service.dart        # API caching layer
├── models/                            # Shared data models
│   ├── user.dart                     # User profile
│   ├── property.dart                 # Property/home data
│   └── subscription.dart             # Payment status
└── features/                          # Feature modules
    ├── auth/                         # Authentication
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    ├── home_profile/                 # Home details
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    ├── document_vault/               # Document management
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    ├── maintenance_calendar/         # Maintenance scheduling
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    ├── emergency_hub/                # Emergency info (offline-first)
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── widgets/
    │   └── services/
    └── home_value_tracking/          # Property valuation
        ├── models/
        ├── providers/
        ├── screens/
        ├── widgets/
        └── services/
```

## Key Principles

### 1. Feature-Based Organization
Each feature is self-contained with its own models, providers, screens, widgets, and services. This promotes:
- **Modularity**: Features can be developed independently
- **Maintainability**: Easy to locate and modify feature code
- **Scalability**: New features follow the same pattern

### 2. Separation of Concerns
- **models/**: Data structures and domain entities
- **providers/**: Riverpod state management (business logic)
- **screens/**: Full-page views
- **widgets/**: Reusable UI components
- **services/**: Data access and external integrations

### 3. Shared Code in Core
Common utilities, themes, and widgets live in `core/` to avoid duplication while keeping features independent.

### 4. Service Layer
Application-level services in `services/` handle cross-cutting concerns like authentication, storage, and API integration.

## Development Guidelines

### When Creating New Features
1. Create a new directory under `features/`
2. Add the standard subdirectories (models, providers, screens, widgets, services)
3. Keep feature logic isolated - avoid direct imports from other features
4. Use Riverpod providers for cross-feature communication

### When Adding Shared Code
- **Widgets used in 3+ features** → `core/widgets/`
- **Utilities used across features** → `core/utils/`
- **Models used by 2+ features** → `models/`
- **Application-level services** → `services/`

### State Management
Use Riverpod with these patterns:
- **FutureProvider**: Async data loading
- **StateNotifier**: Complex state with multiple fields
- **Provider**: Services and dependencies
- **Family**: Parameterized providers

## Architecture References

For detailed architecture information, see:
- [CLAUDE.md](../CLAUDE.md) - Development guidelines
- [Keystona_TechnicalArchitecture.md](../Keystona_TechnicalArchitecture.md) - System architecture
- Feature specifications in the root directory

## Next Steps

1. Configure dependencies in `pubspec.yaml`
2. Implement Keystona theme in `core/theme/`
3. Set up Supabase service
4. Create authentication flow
5. Build feature screens following specs
