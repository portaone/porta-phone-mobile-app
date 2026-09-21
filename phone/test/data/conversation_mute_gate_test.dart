import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/theme_schema.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/core_support.dart';

import '../helpers/helpers.dart';

void main() {
  // The mute control is offered only when the core advertises it. There is
  // nothing to probe with: a core without the functionality does not answer
  // the mute events at all - its fallback handler replies nothing - so a
  // client that offers the control anyway runs into its own push timeout
  // instead of an error. The same flag is how an operator switches the
  // functionality off for a deployment.
  group('the conversation mute control follows the core capability', () {
    FeatureAccess access({required List<String> flags, bool messagingTab = true}) {
      return FeatureAccess.create(
        AppConfig(
          mainConfig: AppConfigMain(
            bottomMenu: AppConfigBottomMenu(
              tabs: [
                if (messagingTab) const BottomMenuTabScheme.messaging(titleL10n: 'messaging', icon: '0xe0b7'),
                const BottomMenuTabScheme.keypad(titleL10n: 'keypad', icon: '0xe1ce'),
              ],
            ),
          ),
        ),
        [createMockTermsResource()],
        CoreSupportImpl(flags),
        null,
        const FeatureOverrides(),
      );
    }

    test('a core that advertises the mute alongside chats offers the control', () {
      final featureAccess = access(flags: [kChatMessagingFeatureFlag, kConversationMuteFeatureFlag]);

      expect(featureAccess.coreSupport.supportsConversationMute, isTrue);
      expect(featureAccess.conversationMuteAvailable, isTrue);
    });

    test('sms alone is enough: the control lives in an sms thread too', () {
      final featureAccess = access(flags: [kSmsMessagingFeatureFlag, kConversationMuteFeatureFlag]);

      expect(featureAccess.messagingConfig.chatsPresent, isFalse);
      expect(featureAccess.conversationMuteAvailable, isTrue);
    });

    test('a core that does not advertise the mute keeps the control away', () {
      final featureAccess = access(flags: [kChatMessagingFeatureFlag, kSmsMessagingFeatureFlag]);

      expect(featureAccess.messagingConfig.anyMessagingEnabled, isTrue);
      expect(featureAccess.conversationMuteAvailable, isFalse);
    });

    test('the mute without messaging placed anywhere has nothing to mute', () {
      final featureAccess = access(
        flags: [kChatMessagingFeatureFlag, kConversationMuteFeatureFlag],
        messagingTab: false,
      );

      expect(featureAccess.conversationMuteAvailable, isFalse);
    });

    test('a core that advertises nothing keeps the control away', () {
      final featureAccess = access(flags: const []);

      expect(featureAccess.conversationMuteAvailable, isFalse);
    });
  });
}
