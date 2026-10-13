import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/data/data.dart' show AppPreferences;
import 'package:webtrit_phone/repositories/repositories.dart';

class _AppPreferences extends Mock implements AppPreferences {}

void main() {
  late _AppPreferences preferences;
  late SystemNotificationsSyncJournalPrefsImpl journal;
  final stored = <String, String>{};

  setUp(() {
    stored.clear();
    preferences = _AppPreferences();
    when(() => preferences.getString(any())).thenAnswer((i) => stored[i.positionalArguments.single as String]);
    when(() => preferences.setString(any(), any())).thenAnswer((i) async {
      stored[i.positionalArguments.first as String] = i.positionalArguments.last as String;
    });
    journal = SystemNotificationsSyncJournalPrefsImpl(preferences);
  });

  test('nothing recorded yet is no sync, not a sync at some default time', () {
    expect(journal.lastSyncedAt, isNull);
  });

  test('a recorded sync is read back as the same moment', () async {
    final at = DateTime(2026, 10, 12, 14, 30, 5);

    await journal.markSynced(at);

    expect(journal.lastSyncedAt!.isAtSameMomentAs(at), isTrue);
  });

  test('a value that is not a time is no sync rather than a crash', () {
    stored['system-notifications-synced-at'] = 'yesterday';

    expect(journal.lastSyncedAt, isNull);
  });
}
