import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await Purchases.setLogLevel(LogLevel.debug);
  final purchasesConfig = PurchasesConfiguration(AppConfig.revenuecatAppleKey);
  await Purchases.configure(purchasesConfig);

  runApp(
    const ProviderScope(
      child: KeystonaApp(),
    ),
  );
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
