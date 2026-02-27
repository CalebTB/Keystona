class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String posthogHost = String.fromEnvironment('POSTHOG_HOST');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String revenuecatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const String revenuecatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging => appEnv == 'staging';
  static bool get isProduction => appEnv == 'production';
}
