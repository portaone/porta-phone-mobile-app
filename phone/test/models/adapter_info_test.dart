import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/models/models.dart';

void main() {
  group('AdapterInfo capabilities', () {
    test('a capability the backend advertises reads as supported', () {
      final adapter = AdapterInfo(supported: [kSipPresenceFeatureFlag, kSipDialogsFeatureFlag, kConferenceFeatureFlag]);

      expect(adapter.supportsSipPresence, isTrue);
      expect(adapter.supportsSipDialogs, isTrue);
      expect(adapter.supportsConference, isTrue);
    });

    test('a capability missing from the list reads as unsupported', () {
      final adapter = AdapterInfo(supported: [kSipPresenceFeatureFlag]);

      expect(adapter.supportsSipPresence, isTrue);
      expect(adapter.supportsConference, isFalse);
    });

    test('no list at all means nothing is supported, not an error', () {
      final adapter = AdapterInfo();

      expect(adapter.supported, isNull);
      expect(adapter.supportsSipPresence, isFalse);
      expect(adapter.supportsSipDialogs, isFalse);
      expect(adapter.supportsConference, isFalse);
    });

    test('an empty list means nothing is supported', () {
      final adapter = AdapterInfo(supported: const []);

      expect(adapter.supportsConference, isFalse);
    });

    test('the wire strings are the ones the backend sends', () {
      // Guards the constants against a typo: the getters above would keep
      // passing if a constant and the list were wrong in the same way.
      expect(kConferenceFeatureFlag, 'conference');
      expect(kSipPresenceFeatureFlag, 'sipPresence');
      expect(kSipDialogsFeatureFlag, 'sipDialogs');
    });
  });
}
