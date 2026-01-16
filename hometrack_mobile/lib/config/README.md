# Config

This directory contains application configuration files.

## Configuration Files

### `env_config.dart`
Environment-specific configuration:
- API endpoints
- Supabase URL and keys
- Feature flags
- Environment detection (dev/staging/production)

### `app_config.dart`
Application-level configuration:
- App name and version
- Default settings
- Supported features per platform

## Usage

Configuration should be loaded at app startup and accessed through providers:

```dart
final envConfigProvider = Provider<EnvConfig>((ref) {
  return EnvConfig.fromEnvironment();
});
```

**Security Note:** Never commit API keys or secrets. Use environment variables or secure storage.
