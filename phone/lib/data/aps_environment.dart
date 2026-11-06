import 'package:flutter/services.dart';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/utils/utils.dart';

final Logger _logger = Logger('ApsEnvironment');

/// The APNs environment the iOS build was signed for, read by the app's runner from the
/// `aps-environment` entitlement of the build's embedded provisioning profile: `development` or
/// `production`. A token is good only in the environment of the build that issued it, so this is
/// the environment a push token is registered with. Null off iOS, on the simulator, or when the
/// runner cannot read it.
class ApsEnvironment {
  static const MethodChannel _channel = MethodChannel('com.webtrit.phone/aps_environment');

  static Future<String?> read() async {
    if (!PlatformInfo.isIOS) return null;
    try {
      return await _channel.invokeMethod<String>('get');
    } catch (error, stackTrace) {
      _logger.warning('the aps-environment of the build could not be read', error, stackTrace);
      return null;
    }
  }
}
