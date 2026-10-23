import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// iOS refuses `tel:` links containing `*` or `#`, so USSD codes can't be handed to its dialer.
bool get canDialUssd => !Platform.isIOS;

/// `tel:` URI with `#` percent-encoded (an unencoded `#` would start a URI fragment).
Uri ussdUri(String code) => Uri.parse('tel:${code.replaceAll('#', '%23')}');

/// Opens the phone dialer pre-filled with [code]; the user still presses call.
Future<bool> openDialer(String code) async {
  try {
    return await launchUrl(ussdUri(code), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> copyToClipboard(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (_) {
    return false;
  }
}
