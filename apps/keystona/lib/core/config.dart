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
  static const String revenuecatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'test_bjTwAPcHTznQgOXzvyNPXCRwirU',
  );
  static const String revenuecatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging => appEnv == 'staging';
  static bool get isProduction => appEnv == 'production';
}
