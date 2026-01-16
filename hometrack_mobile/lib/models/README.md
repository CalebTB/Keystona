# Models

This directory contains shared data models used across multiple features.

## Model Types

### Domain Models
Core business entities that are shared across features:
- `user.dart` - User profile data
- `property.dart` - Property/home information
- `subscription.dart` - Subscription and payment status

### Response Models
API response structures for external services:
- `attom_response.dart` - ATTOM property data API responses
- `weather_response.dart` - OpenWeatherMap API responses

### Common Models
Shared data structures:
- `api_result.dart` - Wrapper for API responses with success/error states
- `sync_status.dart` - Offline sync status tracking

## Usage

Feature-specific models should live in `features/<feature_name>/models/`.
Only place models here if they are truly shared across multiple features.

```dart
import 'package:hometrack_mobile/models/property.dart';
import 'package:hometrack_mobile/models/user.dart';
```
