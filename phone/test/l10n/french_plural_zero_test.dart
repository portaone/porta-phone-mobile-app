import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/l10n/app_localizations_fr.g.dart';

// French puts 0 in the `one` category, unlike English. A `one` form that names
// no number, or writes "1" instead of the count, then speaks of a single item
// when there is none: an empty cache read "1 enregistrement" and an empty trash
// was described as holding one message.
void main() {
  final l10n = AppLocalizationsFr();

  test('zero is not shown as one item', () {
    expect(l10n.cacheManagement_Label_itemsCount(0), '0 enregistrement');
    expect(
      l10n.logRecordsConsole_Text_recordsCountHint(0),
      'Affichage de 0 enregistrement. Utilisez Partager pour exporter le log complet.',
    );
    expect(
      l10n.voicemail_Dialog_emptyTrashContent(0),
      "Les 0 messages de la corbeille seront supprimés et l'espace qu'ils occupent sera libéré.",
    );
    expect(l10n.voicemail_Dialog_deleteSelectedPermanentlyTitle(0), 'Supprimer définitivement 0 messages ?');
    expect(l10n.voicemail_Snackbar_deleteFailed(0), "Les messages n'ont pas pu être supprimés");
    expect(l10n.voicemail_Snackbar_restoreFailed(0), "Les messages n'ont pas pu être restaurés");
  });

  test('one item keeps the singular', () {
    expect(l10n.cacheManagement_Label_itemsCount(1), '1 enregistrement');
    expect(l10n.voicemail_Snackbar_deleteFailed(1), "Le message n'a pas pu être supprimé");
  });

  test('a count is shown with its number', () {
    expect(l10n.cacheManagement_Label_itemsCount(5), '5 enregistrements');
  });
}
