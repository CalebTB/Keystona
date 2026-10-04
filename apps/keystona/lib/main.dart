import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/observability/sentry_init.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  // Everything else starts inside SentryInit.run's appRunner. Sentry only
  // observes errors thrown within that callback, and Supabase/RevenueCat
  // initialization is exactly where startup crashes happen — so they have to
  // be inside it, not before it.
  //
  // No-ops safely when there is no DSN or the build is development, so this
  // is identical to the previous behaviour until a DSN is configured.
  await SentryInit.run(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    // Verbose only outside production — the RevenueCat SDK logs purchase
    // payloads at debug level.
    await Purchases.setLogLevel(
      AppConfig.isProduction ? LogLevel.error : LogLevel.debug,
    );
    await Purchases.configure(
      PurchasesConfiguration(AppConfig.revenuecatAppleKey),
    );

    runApp(
      const ProviderScope(
        child: KeystonaApp(),
      ),
    );
  });
}

/// Root application widget.
///
/// Uses [ConsumerWidget] so it can watch [routerProvider] and rebuild when
/// authentication state transitions cause a new [GoRouter] to be produced.
class KeystonaApp extends ConsumerWidget {
  const KeystonaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Keystona',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
