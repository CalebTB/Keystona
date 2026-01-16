# Features

This directory contains all feature modules for the Keystona mobile application. Each feature is self-contained with its own models, providers, screens, widgets, and services.

## Feature Structure

Each feature follows this structure:

```
feature_name/
  ├── models/          # Data classes and domain models
  ├── providers/       # Riverpod state management providers
  ├── screens/         # Full-page screen widgets
  ├── widgets/         # Feature-specific reusable widgets
  └── services/        # Business logic and data access
```

## Available Features

### Authentication (`auth/`)
User authentication, sign-in, sign-up, and session management.

### Home Profile (`home_profile/`)
Home details, property information, and profile management.

### Document Vault (`document_vault/`)
Document upload, storage, OCR processing, categorization, and search.

### Maintenance Calendar (`maintenance_calendar/`)
Maintenance task scheduling, climate-based recommendations, and home health tracking.

### Emergency Hub (`emergency_hub/`)
**Offline-first** emergency information, utility shutoffs, and emergency contacts.

### Home Value Tracking (`home_value_tracking/`)
Property valuation, equity tracking, and refinance notifications.

## Development Guidelines

1. **Keep features isolated** - Features should not directly import from other features
2. **Use providers for cross-feature communication** - Share data through Riverpod providers
3. **Follow the Keystona design system** - Use theme colors, spacing, and components
4. **Implement offline support** - Especially for Emergency Hub and critical features
5. **Write widget tests** - Test all screens and complex widgets
