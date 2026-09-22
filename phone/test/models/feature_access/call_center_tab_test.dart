import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/theme_schema.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/core_support.dart';

import '../../helpers/helpers.dart';

// The section has two gates and only one of them can be asked in time. These
// pin what the other one reads: the answer the backend last gave for this
// account, because a section that can only say "you are not an agent" is worse
// than one that appears at the next start.
void main() {
  FeatureAccess access({required bool capability, required bool agent}) {
    return FeatureAccess.create(
      AppConfig(
        mainConfig: AppConfigMain(
          bottomMenu: AppConfigBottomMenu(
            tabs: [
              const BottomMenuTabScheme.keypad(titleL10n: 'keypad', icon: '0xe1ce'),
              const BottomMenuTabScheme.callCenter(titleL10n: 'callCenter', icon: '0xf0ee'),
            ],
          ),
        ),
      ),
      [createMockTermsResource()],
      CoreSupportImpl(capability ? const [kCallCenterFeatureFlag] : const []),
      null,
      const FeatureOverrides(),
      callCenterAgent: agent,
    );
  }

  bool hasSection(FeatureAccess featureAccess) =>
      featureAccess.bottomMenuConfig.getTabEnabled<CallCenterBottomMenuTab>() != null;

  test('an agent of a deployment that offers the queues gets the section', () {
    expect(hasSection(access(capability: true, agent: true)), isTrue);
  });

  test('a user the backend called no agent does not', () {
    expect(hasSection(access(capability: true, agent: false)), isFalse);
  });

  test('a deployment that does not offer the queues does not, whatever is remembered', () {
    expect(hasSection(access(capability: false, agent: true)), isFalse);
  });

  test('an account nothing is remembered about does not', () {
    // The default is the honest one: nothing has been asked yet.
    expect(hasSection(access(capability: true, agent: false)), isFalse);
  });
}
