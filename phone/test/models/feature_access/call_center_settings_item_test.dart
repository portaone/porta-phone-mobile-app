import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/theme_schema.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/core_support.dart';

import '../../helpers/helpers.dart';

// The settings row is a configured item like voicemail, so the capability is
// what decides whether it exists at all - the other half of the gate, whether
// this user is an agent, is asked of the queue list by the screen itself.
void main() {
  FeatureAccess access({required bool capability}) {
    return FeatureAccess.create(
      AppConfig(
        mainConfig: AppConfigMain(
          bottomMenu: AppConfigBottomMenu(
            tabs: [const BottomMenuTabScheme.keypad(titleL10n: 'keypad', icon: '0xe1ce')],
          ),
        ),
        settingsConfig: AppConfigSettings(
          sections: [
            AppConfigSettingsSection(
              enabled: true,
              titleL10n: 'settings_ListViewTileTitle_features',
              items: const [
                AppConfigSettingsItem(
                  enabled: true,
                  type: 'callCenter',
                  titleL10n: 'settings_ListViewTileTitle_callCenter',
                  icon: '0xf0ee',
                ),
                AppConfigSettingsItem(
                  enabled: true,
                  type: 'themeMode',
                  titleL10n: 'settings_ListViewTileTitle_themeMode',
                  icon: '0xe518',
                ),
              ],
            ),
          ],
        ),
      ),
      [createMockTermsResource()],
      CoreSupportImpl(capability ? const [kCallCenterFeatureFlag] : const []),
      null,
      const FeatureOverrides(),
    );
  }

  List<SettingsFlavor> flavorsOf(FeatureAccess featureAccess) => [
    for (final section in featureAccess.settingsConfig.sections)
      for (final item in section.items) item.flavor,
  ];

  test('a deployment that offers the queues keeps the configured row', () {
    expect(flavorsOf(access(capability: true)), contains(SettingsFlavor.callCenter));
  });

  test('one that does not drops it, the way it drops a voicemail row', () {
    expect(flavorsOf(access(capability: false)), isNot(contains(SettingsFlavor.callCenter)));
    expect(flavorsOf(access(capability: false)), contains(SettingsFlavor.themeMode));
  });
}
