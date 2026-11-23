import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/l10n/app_localizations_pt.g.dart';

// Portuguese puts 0 in the `one` category, unlike English. A `one` form that
// names no number, or writes "1" instead of the count, then speaks of a single
// item when there is none: an empty cache would read "1 registro" and an empty
// trash would be described as holding one message.
void main() {
  final l10n = AppLocalizationsPt();

  test('zero is not shown as one item', () {
    expect(l10n.cacheManagement_Label_itemsCount(0), '0 registro');
    expect(
      l10n.logRecordsConsole_Text_recordsCountHint(0),
      'Exibindo 0 registro. Use Compartilhar para exportar o log completo.',
    );
    expect(
      l10n.voicemail_Dialog_emptyTrashContent(0),
      'Todas as 0 mensagens na lixeira serão removidas e o espaço que elas ocupam será liberado.',
    );
    expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(0), 'Excluir 0 mensagens permanentemente?');
    expect(l10n.voicemail_Snackbar_deleteFailed(0), 'Não foi possível excluir as mensagens');
    expect(l10n.voicemail_Snackbar_restoreFailed(0), 'Não foi possível restaurar as mensagens');
  });

  test('one item keeps the singular', () {
    expect(l10n.cacheManagement_Label_itemsCount(1), '1 registro');
    expect(l10n.voicemail_Snackbar_deleteFailed(1), 'Não foi possível excluir a mensagem');
  });

  test('a count is shown with its number', () {
    expect(l10n.cacheManagement_Label_itemsCount(5), '5 registros');
  });

  test('a counter agrees with one item and with several', () {
    expect(l10n.voicemail_Label_unheardCount(1), '1 nova');
    expect(l10n.voicemail_Label_unheardCount(3), '3 novas');
    expect(l10n.common_SemanticsValue_unreadCount(1), '1 não lida');
    expect(l10n.common_SemanticsValue_unreadCount(4), '4 não lidas');
    expect(l10n.common_SemanticsValue_selectedCount(1), '1 selecionada');
    expect(l10n.common_SemanticsValue_selectedCount(2), '2 selecionadas');
  });
}
