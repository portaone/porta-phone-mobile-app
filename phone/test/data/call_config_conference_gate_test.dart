import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';

import '../helpers/feature_access_factories.dart';

CallCapabilitiesConfig _capabilitiesFor(WebtritSystemInfo? systemInfo) {
  return CallMapper.map(createMockAppConfig(), const FeatureOverrides(), systemInfo).capabilities;
}

void main() {
  group('conference capability gate', () {
    test('is on where the deployment advertises the capability', () {
      expect(_capabilitiesFor(systemInfoWithSupported([kConferenceFeatureFlag])).isConferenceEnabled, isTrue);
    });

    test('is off where the deployment advertises other capabilities only', () {
      expect(_capabilitiesFor(systemInfoWithSupported([kSipPresenceFeatureFlag])).isConferenceEnabled, isFalse);
    });

    test('is off when the backend advertises nothing', () {
      expect(_capabilitiesFor(systemInfoWithSupported(const [])).isConferenceEnabled, isFalse);
    });

    test('is off before any system info has been fetched', () {
      expect(_capabilitiesFor(null).isConferenceEnabled, isFalse);
    });

    test('defaults to off, so a config built without it hides the feature', () {
      expect(const CallCapabilitiesConfig().isConferenceEnabled, isFalse);
    });

    test('does not disturb the other call capabilities', () {
      final capabilities = _capabilitiesFor(systemInfoWithSupported([kConferenceFeatureFlag]));

      expect(capabilities.isVideoCallEnabled, isTrue);
      expect(capabilities.isBlindTransferEnabled, isTrue);
      expect(capabilities.isAttendedTransferEnabled, isTrue);
    });
  });
}
