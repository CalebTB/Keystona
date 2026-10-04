class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hmvsiiicjwygayekwaor.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtdnNpaWljand5Z2F5ZWt3YW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2MDMxOTksImV4cCI6MjA4NDE3OTE5OX0.BLtR0IG_QAtgEX9ljOIVdHJl6oq6i4pGNKkheHR9s60',
  );
  static const String posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String posthogHost = String.fromEnvironment('POSTHOG_HOST');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  /// Must match the release sentry_dart_plugin creates at upload time, or
  /// events land on a release that has no debug files attached. The Makefile
  /// computes one string and passes it to both. Empty in dev builds, where
  /// Sentry is disabled anyway.
  static const String sentryRelease = String.fromEnvironment('SENTRY_RELEASE');
  static const String revenuecatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'test_bjTwAPcHTznQgOXzvyNPXCRwirU',
  );
  static const String revenuecatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  /// Defaults to 'production', NOT 'development'. The default is the value a
  /// build gets when someone forgets --dart-define, and the two failure modes
  /// are not symmetric: defaulting to development ships a release with crash
  /// reporting silently off, which is how you find out from an empty Sentry
  /// dashboard weeks later. Defaulting to production means a forgotten define
  /// ships WITH reporting. Debug-build noise is held back by kReleaseMode in
  /// SentryInit.isEnabled instead of by this value.
  static const String appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'production');

  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging => appEnv == 'staging';
  static bool get isProduction => appEnv == 'production';
}
