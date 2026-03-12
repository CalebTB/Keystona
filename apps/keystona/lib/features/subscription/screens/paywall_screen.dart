import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Presents the RevenueCat native paywall as a full screen.
///
/// The paywall is launched via [RevenueCatUI.presentPaywall] in a
/// post-frame callback. The screen shows a centered spinner while
/// the SDK launches the paywall overlay. On any result — purchase,
/// cancel, or error — the screen pops itself so the caller is
/// always returned to.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _presentPaywall());
  }

  Future<void> _presentPaywall() async {
    try {
      await RevenueCatUI.presentPaywall();
    } catch (_) {
      // Paywall SDK error — silently fall back to previous screen.
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}
