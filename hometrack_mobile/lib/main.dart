import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hometrack_mobile/core/config/supabase_client.dart';
import 'package:hometrack_mobile/core/theme/keystona_theme.dart';
import 'package:hometrack_mobile/features/auth/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabase();

  runApp(
    const ProviderScope(
      child: KeystonaApp(),
    ),
  );
}

class KeystonaApp extends StatelessWidget {
  const KeystonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keystona',
      theme: KeystonaTheme.light(),
      home: const AuthGate(),
    );
  }
}
