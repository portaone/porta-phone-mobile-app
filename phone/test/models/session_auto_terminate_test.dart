import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

void main() {
  group('SessionAutoTerminate', () {
    // A preset equal to the installation's period is the default itself; one
    // longer than it would be refused by the core.
    for (final (max, presets) in [
      (null, [7, 30, 90]),
      (120, [7, 30, 90]),
      (90, [7, 30]),
      (89, [7, 30]),
      (30, [7]),
      (29, [7]),
      (7, <int>[]),
      (6, <int>[]),
    ]) {
      test('offers $presets under an installation limit of $max', () {
        expect(SessionAutoTerminate(installationMaxDays: max).presets, presets);
      });
    }

    test('the longest choice is the installation limit, or 365 days without one', () {
      expect(const SessionAutoTerminate(installationMaxDays: 90).maxDays, 90);
      expect(const SessionAutoTerminate().maxDays, 365);
    });

    test('the period in force is the default when it is the installation one', () {
      expect(
        const SessionAutoTerminate(inactivityTimeoutDays: 90, installationMaxDays: 90).isInstallationDefault,
        isTrue,
      );
      expect(const SessionAutoTerminate().isInstallationDefault, isTrue);
      expect(
        const SessionAutoTerminate(inactivityTimeoutDays: 30, installationMaxDays: 90).isInstallationDefault,
        isFalse,
      );
      expect(const SessionAutoTerminate(inactivityTimeoutDays: 30).isInstallationDefault, isFalse);
    });
  });
}
