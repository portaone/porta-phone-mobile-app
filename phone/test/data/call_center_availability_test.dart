import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/theme_schema.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/core_support.dart';

import '../helpers/helpers.dart';

void main() {
  // The call center has two gates and only one of them can live here. This
  // pins which: the deployment's capability, and nothing about the person
  // signed in - a session that knows the feature exists still has to read the
  // queue list before it knows whether to offer anything.
  group('call center availability answers for the deployment alone', () {
    FeatureAccess access(List<String> flags) {
      return FeatureAccess.create(
        AppConfig(
          mainConfig: AppConfigMain(
            bottomMenu: AppConfigBottomMenu(
              tabs: [const BottomMenuTabScheme.keypad(titleL10n: 'keypad', icon: '0xe1ce')],
            ),
          ),
        ),
        [createMockTermsResource()],
        CoreSupportImpl(flags),
        null,
        const FeatureOverrides(),
      );
    }

    test('is false when the adapter does not advertise the capability', () {
      expect(access(const []).callCenterAvailable, isFalse);
    });

    test('is true as soon as the adapter advertises it', () {
      expect(access(const [kCallCenterFeatureFlag]).callCenterAvailable, isTrue);
    });

    test('does not depend on any other capability being present', () {
      expect(access(const [kVoicemailFeatureFlag]).callCenterAvailable, isFalse);
      expect(access(const [kCallCenterFeatureFlag, kVoicemailFeatureFlag]).callCenterAvailable, isTrue);
    });
  });
}
