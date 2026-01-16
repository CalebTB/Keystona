# Core

This directory contains shared code used across the entire application.

## Directory Structure

### `constants/`
Application-wide constants including API endpoints, configuration values, and shared constants.

### `theme/`
Keystona design system implementation including:
- Color palette (Deep Blue #1E3A5F, Warm Gold #D4A574)
- Typography (SF Pro Display/Text)
- Spacing system (4px base unit)
- Custom theme data

### `utils/`
Utility functions and helpers for:
- Date formatting
- String manipulation
- Validation
- Extensions

### `widgets/`
Shared widgets used across multiple features:
- Loading indicators
- Error states
- Empty states
- Custom buttons
- Status indicators

## Usage

Import core utilities in your feature files:

```dart
import 'package:hometrack_mobile/core/theme/keystona_theme.dart';
import 'package:hometrack_mobile/core/constants/app_constants.dart';
import 'package:hometrack_mobile/core/utils/date_utils.dart';
```
