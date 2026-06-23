import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

class UrlOpener {
  UrlOpener._();

  static Future<bool> open(BuildContext context, String url) async {
    if (url.isEmpty) return false;
    final Uri? uri = _toHttpUri(url);
    if (uri == null) {
      _toast(context, 'Invalid link: $url');
      return false;
    }
    for (final LaunchMode mode in <LaunchMode>[
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ]) {
      try {
        final bool ok = await launchUrl(uri, mode: mode);
        if (ok) return true;
        appLogger.w('🔗 launchUrl returned false for $uri (mode=$mode)');
      } catch (e) {
        appLogger.w('🔗 launchUrl threw for $uri (mode=$mode): $e');
      }
    }

    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (context.mounted) {
      _toast(context, 'Link copied to clipboard — open it in your browser');
    }
    return false;
  }

  static Future<void> copy(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final Uri? uri = _toHttpUri(url);
    if (uri == null) return;
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (context.mounted) _toast(context, 'Link copied');
  }

  static Uri? _toHttpUri(String input) {
    String s = input.trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    return Uri.tryParse(s);
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
