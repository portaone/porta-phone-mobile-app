import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/l10n/app_localizations_en.g.dart';
import 'package:webtrit_phone/l10n/app_localizations_uk.g.dart';

// The questions asked before voicemails are deleted for good carry the number
// of messages, and that number is the part a person cannot check once the
// dialog covers the list. English read "1 messages"; Ukrainian was worse: its
// `one` form is for every number ending in 1 but 11, and it named no number, so
// 21 messages were asked about as one. (An exact `=1` form is no way round it:
// the generator folds it into `one`.)
void main() {
  group('English', () {
    final l10n = AppLocalizationsEn();

    test('one message is asked about as one', () {
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(1), 'Delete the message permanently?');
      expect(
        l10n.voicemail_Dialog_emptyTrashContent(1),
        'The message in the trash will be removed and the space it uses will be freed.',
      );
    });

    test('several are counted', () {
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(21), 'Delete 21 messages permanently?');
      expect(l10n.voicemail_Dialog_emptyTrashContent(2), startsWith('All 2 messages in the trash'));
    });

    test('what is picked is said in words that stand alone', () {
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(0), 'Nothing selected');
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(1), '1 message selected');
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(4), '4 messages selected');
    });
  });

  group('Ukrainian', () {
    final l10n = AppLocalizationsUk();

    test('one message is asked about with its number', () {
      // The same form serves 1 and 21, so it has to carry the number: without
      // it 21 messages were asked about as "the message".
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(1), 'Видалити 1 повідомлення назавжди?');
      expect(l10n.voicemail_Dialog_emptyTrashContent(1), startsWith('1 повідомлення з кошика буде вилучено'));
    });

    test('twenty-one messages are not asked about as one', () {
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(21), 'Видалити 21 повідомлення назавжди?');
      expect(l10n.voicemail_Dialog_emptyTrashContent(21), startsWith('21 повідомлення з кошика'));
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(101), contains('101'));
    });

    test('two to four and five and more take their own forms', () {
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(3), 'Видалити 3 повідомлення назавжди?');
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(5), 'Видалити 5 повідомлень назавжди?');
      expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(11), 'Видалити 11 повідомлень назавжди?');
      expect(l10n.voicemail_Dialog_emptyTrashContent(4), startsWith('4 повідомлення з кошика'));
      expect(l10n.voicemail_Dialog_emptyTrashContent(12), startsWith('12 повідомлень з кошика'));
    });

    test('what is picked follows the same forms', () {
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(0), 'Нічого не вибрано');
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(1), 'Вибрано 1 повідомлення');
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(5), 'Вибрано 5 повідомлень');
      expect(l10n.voicemail_SemanticsAnnouncement_selectedCount(22), 'Вибрано 22 повідомлення');
    });
  });
}
