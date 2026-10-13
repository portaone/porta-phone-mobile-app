import 'package:webtrit_phone/data/data.dart' show AppPreferences;

/// Remembers when the stored notifications were last brought up to date.
///
/// The store itself cannot say: its newest record is as old as the last
/// change the backend made, however recently that was read. And the backend
/// reports a deleted notification for a limited time only - so how long ago
/// the store last heard from it decides whether the store can still be
/// trusted, or may hold notifications deleted without a trace left to read.
abstract class SystemNotificationsSyncJournal {
  /// Null when no sync has been recorded: by this version of the app, on this
  /// device, since the record was last cleared.
  DateTime? get lastSyncedAt;

  Future<void> markSynced(DateTime at);
}

class SystemNotificationsSyncJournalPrefsImpl implements SystemNotificationsSyncJournal {
  SystemNotificationsSyncJournalPrefsImpl(this._appPreferences);

  final AppPreferences _appPreferences;

  static const _key = 'system-notifications-synced-at';

  @override
  DateTime? get lastSyncedAt {
    final value = _appPreferences.getString(_key);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> markSynced(DateTime at) => _appPreferences.setString(_key, at.toUtc().toIso8601String());
}
