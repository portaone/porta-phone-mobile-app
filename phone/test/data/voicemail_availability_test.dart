import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/theme_schema.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/core_support.dart';

import '../helpers/helpers.dart';

void main() {
  // Voicemail is placed by configuration and its data layer is shared by every
  // placement, so what runs is asked of the feature, not of one of its
  // placements. These pin that separation: the settings row keeps naming the
  // row alone, and availability answers for the whole feature.
  group('voicemail availability is asked of the feature, not of the settings row', () {
    const voicemailItem = AppConfigSettingsItem(
      enabled: true,
      type: 'voicemail',
      titleL10n: 'settings_ListViewTileTitle_voicemail',
      icon: '0xe0b7',
    );

    const themeModeItem = AppConfigSettingsItem(
      enabled: true,
      type: 'themeMode',
      titleL10n: 'settings_ListViewTileTitle_themeMode',
      icon: '0xe518',
    );

    FeatureAccess access({required bool settingsRow, required List<String> flags, bool bottomMenuTab = false}) {
      return FeatureAccess.create(
        AppConfig(
          mainConfig: AppConfigMain(
            bottomMenu: AppConfigBottomMenu(
              tabs: [
                if (bottomMenuTab) const BottomMenuTabScheme.voicemail(titleL10n: 'voicemail', icon: '0xe0b7'),
                const BottomMenuTabScheme.keypad(titleL10n: 'keypad', icon: '0xe1ce'),
              ],
            ),
          ),
          settingsConfig: AppConfigSettings(
            sections: [
              AppConfigSettingsSection(
                enabled: true,
                titleL10n: 'section',
                items: [if (settingsRow) voicemailItem, themeModeItem],
              ),
            ],
          ),
        ),
        [createMockTermsResource()],
        CoreSupportImpl(flags),
        null,
        const FeatureOverrides(),
      );
    }

    test('a configured row on a core that advertises voicemail makes it available', () {
      final featureAccess = access(settingsRow: true, flags: [kVoicemailFeatureFlag]);

      expect(featureAccess.settingsConfig.voicemailsEnabled, isTrue);
      expect(featureAccess.voicemailAvailable, isTrue);
    });

    test('a core that does not advertise voicemail keeps it unavailable', () {
      final featureAccess = access(settingsRow: true, flags: const []);

      expect(featureAccess.settingsConfig.voicemailsEnabled, isFalse);
      expect(featureAccess.voicemailAvailable, isFalse);
    });

    test('no configured placement keeps it unavailable', () {
      final featureAccess = access(settingsRow: false, flags: [kVoicemailFeatureFlag]);

      expect(featureAccess.settingsConfig.voicemailsEnabled, isFalse);
      expect(featureAccess.voicemailAvailable, isFalse);
    });

    test('the settings row stays about the row: dropping it drops the row, not the core capability', () {
      final featureAccess = access(settingsRow: false, flags: [kVoicemailFeatureFlag]);
      final flavors = featureAccess.settingsConfig.sections.expand((section) => section.items).map((i) => i.flavor);

      expect(flavors, isNot(contains(SettingsFlavor.voicemail)));
      expect(featureAccess.coreSupport.supportsVoicemail, isTrue);
    });

    // The two placements are configured independently, and the data layer is
    // one for both - so either of them alone has to keep it running.
    test('the bottom-menu tab alone makes it available', () {
      final featureAccess = access(settingsRow: false, bottomMenuTab: true, flags: [kVoicemailFeatureFlag]);

      expect(featureAccess.settingsConfig.voicemailsEnabled, isFalse);
      expect(featureAccess.voicemailAvailable, isTrue);
    });

    test('a core without voicemail keeps it unavailable however it is placed', () {
      final featureAccess = access(settingsRow: true, bottomMenuTab: true, flags: const []);

      expect(featureAccess.voicemailAvailable, isFalse);
    });

    test('the route guard follows availability, not the settings row', () {
      expect(
        access(settingsRow: true, flags: [kVoicemailFeatureFlag]).checker.isEnabled(FeatureFlag.voicemail),
        isTrue,
      );
      expect(
        access(settingsRow: false, flags: [kVoicemailFeatureFlag]).checker.isEnabled(FeatureFlag.voicemail),
        isFalse,
      );
    });
  });
  // The three WT-1878 controls each answer for themselves, and each dies with
  // voicemail. The trash one carries the heaviest consequence: read as false it
  // does not merely hide a control, it changes what deleting means.
  group('the three voicemail controls', () {
    const voicemailItem = AppConfigSettingsItem(
      enabled: true,
      type: 'voicemail',
      titleL10n: 'settings_ListViewTileTitle_voicemail',
      icon: '0xe0b7',
    );

    FeatureAccess access(List<String> flags) {
      return FeatureAccess.create(
        AppConfig(
          settingsConfig: AppConfigSettings(
            sections: [
              AppConfigSettingsSection(enabled: true, titleL10n: 'section', items: const [voicemailItem]),
            ],
          ),
        ),
        [createMockTermsResource()],
        CoreSupportImpl(flags),
        null,
        const FeatureOverrides(),
      );
    }

    test('each control follows its own flag', () {
      final featureAccess = access([kVoicemailFeatureFlag, kVoicemailSaveFeatureFlag, kVoicemailForwardFeatureFlag]);

      expect(featureAccess.voicemailSaveAvailable, isTrue);
      expect(featureAccess.voicemailForwardAvailable, isTrue);
      expect(featureAccess.voicemailTrashAvailable, isFalse);
    });

    test('all three are on when the core offers all three', () {
      final featureAccess = access([
        kVoicemailFeatureFlag,
        kVoicemailSaveFeatureFlag,
        kVoicemailTrashFeatureFlag,
        kVoicemailForwardFeatureFlag,
      ]);

      expect(featureAccess.voicemailSaveAvailable, isTrue);
      expect(featureAccess.voicemailTrashAvailable, isTrue);
      expect(featureAccess.voicemailForwardAvailable, isTrue);
    });

    test('none of them survives voicemail itself being withdrawn', () {
      // The backend withdraws the three with voicemail, but the client does not
      // rely on that: a control cannot be offered where the feature does not run.
      final featureAccess = access([
        kVoicemailSaveFeatureFlag,
        kVoicemailTrashFeatureFlag,
        kVoicemailForwardFeatureFlag,
      ]);

      expect(featureAccess.voicemailAvailable, isFalse);
      expect(featureAccess.voicemailSaveAvailable, isFalse);
      expect(featureAccess.voicemailTrashAvailable, isFalse);
      expect(featureAccess.voicemailForwardAvailable, isFalse);
    });

    test('a core that offers voicemail alone offers none of the three', () {
      final featureAccess = access([kVoicemailFeatureFlag]);

      expect(featureAccess.voicemailAvailable, isTrue);
      expect(featureAccess.voicemailSaveAvailable, isFalse);
      expect(featureAccess.voicemailTrashAvailable, isFalse);
      expect(featureAccess.voicemailForwardAvailable, isFalse);
    });
  });
}
