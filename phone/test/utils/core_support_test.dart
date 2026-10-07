import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/utils/core_support.dart';

import 'package:pub_semver/pub_semver.dart';

import '../helpers/feature_access_factories.dart';

void main() {
  CoreSupport createCoreSupportWithFlags(List<String> flags) {
    return CoreSupportImpl(flags);
  }

  group('CoreSupport Feature Flags', () {
    test('returns all false when no flags provided', () {
      final cs = createCoreSupportWithFlags([]);

      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsSms, isFalse);
      expect(cs.supportsChats, isFalse);
      expect(cs.supportsSystemNotifications, isFalse);
      expect(cs.supportsSystemPushNotifications, isFalse);
      expect(cs.supportsCallToActions, isFalse);
      expect(cs.supportsCallHistory, isFalse);
      expect(cs.supportsExtensions, isFalse);
      expect(cs.supportsCallCenter, isFalse);
    });

    test('call-to-actions only', () {
      final cs = createCoreSupportWithFlags([kCtaListFeatureFlag]);

      expect(cs.supportsCallToActions, isTrue);
      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsSms, isFalse);
    });

    test('extensions only', () {
      final cs = createCoreSupportWithFlags([kExtensionsFeatureFlag]);

      expect(cs.supportsExtensions, isTrue);
      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsSms, isFalse);
    });

    test('call center only', () {
      final cs = createCoreSupportWithFlags([kCallCenterFeatureFlag]);

      expect(cs.supportsCallCenter, isTrue);
      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsCallHistory, isFalse);
    });

    test('voicemail only', () {
      final cs = createCoreSupportWithFlags([kVoicemailFeatureFlag]);

      expect(cs.supportsVoicemail, isTrue);
      expect(cs.supportsSms, isFalse);
      expect(cs.supportsChats, isFalse);
    });

    test('sms only', () {
      final cs = createCoreSupportWithFlags([kSmsMessagingFeatureFlag]);

      expect(cs.supportsSms, isTrue);
      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsChats, isFalse);
    });

    test('chats only', () {
      final cs = createCoreSupportWithFlags([kChatMessagingFeatureFlag]);

      expect(cs.supportsChats, isTrue);
      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsSms, isFalse);
    });

    test('system notifications only', () {
      final cs = createCoreSupportWithFlags([kSystemNotificationsFeatureFlag]);
      expect(cs.supportsSystemNotifications, isTrue);
    });

    test('call history only', () {
      final cs = createCoreSupportWithFlags([kCallHistoryFeatureFlag]);

      expect(cs.supportsCallHistory, isTrue);
      expect(cs.supportsVoicemail, isFalse);
      expect(cs.supportsSms, isFalse);
    });

    test('all flags -> all getters true', () {
      final cs = createCoreSupportWithFlags([
        kVoicemailFeatureFlag,
        kSmsMessagingFeatureFlag,
        kChatMessagingFeatureFlag,
      ]);

      expect(cs.supportsVoicemail, isTrue);
      expect(cs.supportsSms, isTrue);
      expect(cs.supportsChats, isTrue);
    });
  });

  group('voicemail on a core whose list does not name the sender', () {
    // The app reads who left a message off the list and nowhere else, so the
    // adapter advertising voicemail is not enough: the core has to list it.
    test('is not supported, whatever the adapter advertises', () {
      final cs = CoreSupportImpl(const [kVoicemailFeatureFlag], voicemailListNamesSender: false);

      expect(cs.supportsVoicemail, isFalse);
    });

    test('is supported once the core lists it', () {
      final cs = CoreSupportImpl(const [kVoicemailFeatureFlag], voicemailListNamesSender: true);

      expect(cs.supportsVoicemail, isTrue);
    });

    test('a core that lists it does not stand in for the adapter flag', () {
      final cs = CoreSupportImpl(const [], voicemailListNamesSender: true);

      expect(cs.supportsVoicemail, isFalse);
    });

    test('the factory takes it from the core version', () {
      final old = CoreSupportFactory.create(
        systemInfoWithSupported(const [kVoicemailFeatureFlag], coreVersion: Version(1, 0, 0)),
      );
      final current = CoreSupportFactory.create(
        systemInfoWithSupported(const [kVoicemailFeatureFlag], coreVersion: Version(1, 1, 0)),
      );

      expect(old.supportsVoicemail, isFalse);
      expect(current.supportsVoicemail, isTrue);
    });

    test('the factory supports nothing before the core has answered', () {
      expect(CoreSupportFactory.create(null).supportsVoicemail, isFalse);
    });
  });

  group('CoreSupport Immutability', () {
    test('internal flags are immutable (defensive copy check)', () {
      final sourceFlags = <String>[kVoicemailFeatureFlag];
      final cs = createCoreSupportWithFlags(sourceFlags);

      expect(cs.supportsVoicemail, isTrue, reason: 'Should be true initially');
      sourceFlags.clear();

      expect(cs.supportsVoicemail, isTrue, reason: 'Should stay true despite source list clearing');
    });
  });
}
