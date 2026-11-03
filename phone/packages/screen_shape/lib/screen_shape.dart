import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the display is round.
///
/// Flutter cannot tell: a round watch face and a square one are both a
/// square window to it. Android knows, because the maker declares it in the
/// device configuration.
class DisplayShape {
  const DisplayShape._();

  static const MethodChannel _methodChannel = MethodChannel('screen_shape');

  /// Whether the display is round (`Configuration.isScreenRound`), or null
  /// where the platform has no answer: every platform but Android, and any
  /// failure. Never throws.
  static Future<bool?> isRound() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _methodChannel.invokeMethod<bool>('isRound');
    } catch (_) {
      return null;
    }
  }
}
