import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens a link on the phone a watch is paired with.
///
/// A watch has no web view and no browser worth reading a page in, so a page
/// the app would show - terms, help, an embedded page - is sent to the phone,
/// where the person reads it. Wear OS only: anywhere else, and on a watch
/// with no phone in reach, [open] answers false and nothing is opened.
class PhoneLink {
  PhoneLink._();

  @visibleForTesting
  static const channel = MethodChannel('phone_link');

  /// Asks the paired phone to open [uri]; true once the phone has taken it.
  static Future<bool> open(Uri uri) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await channel.invokeMethod<bool>('open', uri.toString()) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
