import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/app_localizations_en.g.dart';
import 'package:webtrit_phone/l10n/app_localizations_uk.g.dart';

import 'conversation_screen_harness.dart';

void main() {
  group('Chat.title', () {
    test('is the name when the chat has one', () {
      expect(groupChat(id: 42, name: 'Team').title(AppLocalizationsEn()), 'Team');
    });

    test('is one localized title from the number when it has none - never the bare number', () {
      // WT-1884: three places used to make up their own ("Chat 42", "Group: 42",
      // and the bare "42" in the chat's title bar).
      expect(groupChat(id: 42, name: null).title(AppLocalizationsEn()), 'Group 42');
      expect(groupChat(id: 42, name: null).title(AppLocalizationsUk()), 'Група 42');
    });
  });
}
