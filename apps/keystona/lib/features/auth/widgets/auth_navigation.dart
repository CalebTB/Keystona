import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Back chevron behaviour: pop when there is a page below, otherwise go to
/// [fallback] (a cold start straight onto this screen).
void authBack(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Opens a legal page. Does nothing until [url] is set (see AuthLegalLinks).
Future<void> openLegalLink(Uri? url) async {
  if (url == null) return;
  await launchUrl(url);
}
