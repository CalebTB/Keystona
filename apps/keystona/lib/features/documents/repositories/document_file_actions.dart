import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hand-off to the operating system: share sheet, browser, dialer.
abstract interface class DocumentFileActions {
  Future<void> share({required String url, required String title});

  /// Opens [url] outside the app. Returns false when nothing can open it.
  Future<bool> open(Uri url);
}

class PluginDocumentFileActions implements DocumentFileActions {
  const PluginDocumentFileActions();

  @override
  Future<void> share({required String url, required String title}) async {
    await SharePlus.instance.share(
      ShareParams(uri: Uri.parse(url), text: title),
    );
  }

  @override
  Future<bool> open(Uri url) async {
    if (!await canLaunchUrl(url)) return false;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
