import 'dart:async';

import 'package:logging/logging.dart';

import 'package:app_database/app_database.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/app/session/session.dart';

abstract class VoicemailRepository implements Refreshable {
  /// Fetches voicemails from the remote server and updates the local database.
  ///
  /// If [localeCode] is provided, it will be used to localize the request.
  /// This method does not return the fetched data directly. Instead, updates are
  /// reflected in [watchVoicemails].
  ///
  /// Additionally, any existing cached voicemails are immediately emitted to the stream,
  /// triggering all active [watchVoicemails] listeners before the remote fetch completes.
  /// Concurrent callers share one completion after all required writes. A failed
  /// attempt preserves its original error and stack even if cache fallback fails.
  /// Once the feature is known to be unavailable, later calls need no remote work.
  Future<void> fetchVoicemails({String? localeCode});

  /// Removes a voicemail with the specified [messageId] from both the remote server and the local database.
  ///
  /// If [localeCode] is provided, it will be used in the API request.
  /// Throws an error if the deletion fails on the remote server.
  Future<void> removeVoicemail(String messageId, {String? localeCode});

  /// Removes every voicemail in the local database from the remote server and,
  /// as each remote deletion succeeds, from the local database.
  ///
  /// Same contract as [removeMultipleVoicemails]: a message the server rejects
  /// stays, the rest go, and the first rejection is rethrown at the end, while
  /// a failure that is not about one message stops the loop at once.
  Future<void> removeAllVoicemails();

  /// Updates the seen status of the voicemail with the given [messageId].
  ///
  /// The new [seen] value will be sent to the remote server and applied to the local database.
  /// If [localeCode] is provided, it will be used for the API request.
  Future<void> updateVoicemailSeenStatus(String messageId, bool seen, {String? localeCode});

  /// Watches the count of unread voicemails in the local database.
  ///
  /// Emits a new value whenever the underlying data changes.
  Stream<int> watchUnreadVoicemailsCount();

  /// Watches the list of voicemails from the local database.
  ///
  /// Emits updates whenever the voicemail list changes.
  /// If the repository is disabled, an empty stream is returned.
  Stream<List<Voicemail>> watchVoicemails();

  /// Removes the voicemails with the given [messagesIds], each from the remote
  /// server first and from the local database only once the server confirmed.
  ///
  /// The loop is resumable over messages the server itself rejected: such a
  /// message keeps its local row and the loop carries on, so a retry repeats
  /// only what is left, and the first rejection is rethrown once the loop is
  /// done so that a caller learns the list is not what it asked for.
  ///
  /// Anything that is not the server deciding about one message ends the loop
  /// at once - a dead session, voicemail switched off, a request that never
  /// arrived - because it will hold for every message left.
  Future<void> removeMultipleVoicemails(List<String> messagesIds);

  /// Returns `false` once the server has responded with [VoicemailNotConfiguredException]
  /// or [EndpointNotSupportedException], indicating that voicemail is permanently
  /// unavailable for this session.
  bool get isFeatureSupported;
}

final _logger = Logger('VoicemailRepository');

class VoicemailRepositoryImpl
    with DialogInfoDriftMapper, PresenceInfoDriftMapper, ContactsDriftMapper, VoicemailMapper
    implements VoicemailRepository {
  VoicemailRepositoryImpl({
    required WebtritApiClient webtritApiClient,
    required String token,
    required AppDatabase appDatabase,
    SessionGuard? sessionGuard,
  }) : _sessionGuard = sessionGuard ?? const EmptySessionGuard(),
       _webtritApiClient = webtritApiClient,
       _token = token,
       _appDatabase = appDatabase {
    _initialize();
  }

  final WebtritApiClient _webtritApiClient;
  final String _token;
  final AppDatabase _appDatabase;
  final SessionGuard _sessionGuard;

  // If the repository is disabled, the stream controller is not initialized.
  // In such cases, subscribers will receive an empty stream instead.
  StreamController<List<Voicemail>>? _updatesController;
  StreamSubscription? _databaseSubscription;

  // Fetch callers and mutations awaiting a fetch observe the same outcome on
  // every path, without a separately completed coordination future.
  Future<void>? _fetching;
  bool _featureSupported = true;

  @override
  bool get isFeatureSupported => _featureSupported;

  @override
  bool get isActive => _featureSupported;

  void _initialize() {
    _updatesController = StreamController<List<Voicemail>>.broadcast(onListen: _onListen, onCancel: _onCancel);

    // The eager fetch has no awaiting owner. Its error is already logged or
    // routed to SessionGuard; ignoring this detached observation does not change
    // the shared future's failure for polling or UI callers joining the fetch.
    fetchVoicemails().ignore();
  }

  void _onListen() {
    _databaseSubscription = _appDatabase.voicemailDao.watchVoicemailsWithContacts().listen((dataList) {
      final items = dataList.map(_voicemailFromDriftWithContact).toList();
      _updatesController?.add(items);
    });
  }

  void _onCancel() {
    _databaseSubscription?.cancel();
  }

  @override
  Future<void> fetchVoicemails({String? localeCode}) {
    final fetching = _fetching;
    if (fetching != null) return fetching;
    if (!_featureSupported) return Future.value();

    return _fetching = _fetchVoicemails(localeCode: localeCode).whenComplete(() => _fetching = null);
  }

  Future<void> _fetchVoicemails({String? localeCode}) async {
    try {
      /// Do not emit unknown status to show updating state, because it leads to UI flicker on SettingsScreen
      /// especially on android if user checks status bar and app changes its lifecycle from innactive to resumed (WT-1424)
      ///
      /// Add separate event if needed
      await _emitCachedVoicemails();

      final remoteItems = await _webtritApiClient.getUserVoicemailList(_token, locale: localeCode);

      for (final item in remoteItems.items) {
        final details = await _webtritApiClient.getUserVoicemail(_token, item.id, locale: localeCode);

        await _appDatabase.voicemailDao.insertOrUpdateVoicemail(
          voicemailToDrift(item, details, _webtritApiClient.getVoicemailAttachmentUrl(item.id)),
        );
      }
    } on UnauthorizedException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    } catch (e, st) {
      final isExpected = e is VoicemailNotConfiguredException || e is EndpointNotSupportedException;
      _logger.warning('Failed to fetch voicemails', e, isExpected ? null : st);
      if (isExpected) _featureSupported = false;

      // Cache fallback is for presentation, not evidence of a successful cycle.
      // A secondary read failure must not replace the original refresh failure.
      try {
        await _emitCachedVoicemails();
      } catch (cacheError, cacheStack) {
        _logger.warning('Failed to emit cached voicemails after refresh failure', cacheError, cacheStack);
      }

      rethrow;
    }
  }

  /// Retrieves local voicemails and pushes them to the stream controller.
  Future<void> _emitCachedVoicemails() async {
    final dataList = await _appDatabase.voicemailDao.getVoicemailsWithContacts();
    final items = dataList.map(_voicemailFromDriftWithContact).toList();

    if (items.isNotEmpty) {
      _updatesController?.add(items);
    }
  }

  /// Removes a specific voicemail from both the remote server and the local database.
  ///
  /// If a [fetchVoicemails] operation is currently active, this method waits for it to complete
  /// before proceeding, ensuring no concurrent modifications to the same data set.
  ///
  /// The voicemail is first deleted from the remote server. If that succeeds,
  /// it is then removed from the local database.
  ///
  /// Throws an error if the remote deletion fails. The local record remains untouched in that case.
  ///
  /// [messageId] – the ID of the voicemail to remove.
  /// [localeCode] – optional locale code for the API request.
  @override
  Future<void> removeVoicemail(String messageId, {String? localeCode}) async {
    if (_fetching != null) {
      await _fetching;
    }

    try {
      await _webtritApiClient.deleteUserVoicemail(
        _token,
        messageId,
        locale: localeCode,
        options: RequestOptions.withNoRetries(),
      );

      await _appDatabase.voicemailDao.deleteVoicemailById(messageId);
    } on UnauthorizedException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    }
  }

  @override
  Future<void> removeAllVoicemails() async {
    if (_fetching != null) {
      await _fetching;
    }

    final allVoicemails = await _appDatabase.voicemailDao.getAllVoicemails();
    await _removeEach(allVoicemails.map((voicemail) => voicemail.id));
  }

  /// Updates the `seen` status of a voicemail, ensuring consistency with any ongoing fetch operation.
  ///
  /// If [fetchVoicemails] is currently in progress, this method waits for it to complete
  /// before proceeding. This guarantees sequential consistency and avoids conflicts
  /// between reading/updating local voicemail state during synchronization.
  ///
  /// The update is applied optimistically to the local database first, and then propagated
  /// to the remote server. If the remote update fails, the local change is reverted to the
  /// value the message had before the call, and the failure is rethrown.
  ///
  /// The remote call is awaited, and sent without retries: the revert is only possible
  /// while its outcome is still known here, and a caller that reports the failure needs it
  /// to arrive as the result of this future rather than as an unhandled error somewhere
  /// later.
  ///
  /// The revert restores the value read before the optimistic write. A refresh that lands
  /// inside that window can write the mailbox's own value and have it undone; the flag is
  /// a boolean, so there is nothing in the row itself to tell the two writers apart, and
  /// the next refresh settles it.
  ///
  /// [messageId] – the ID of the voicemail to update.
  /// [seen] – the new seen status to apply.
  /// [localeCode] – optional locale code for the API request.
  @override
  Future<void> updateVoicemailSeenStatus(String messageId, bool seen, {String? localeCode}) async {
    if (_fetching != null) {
      await _fetching;
    }

    final previous = await _appDatabase.voicemailDao.getVoicemailById(messageId);
    if (previous == null) return;

    final before = VoicemailDataCompanion(id: Value(previous.id), seen: Value(previous.seen));
    final after = VoicemailDataCompanion(id: Value(previous.id), seen: Value(seen));
    await _appDatabase.voicemailDao.updateVoicemail(after);

    try {
      await _webtritApiClient.updateUserVoicemail(
        _token,
        messageId,
        seen: seen,
        locale: localeCode,
        // Same policy as the delete beside it: someone is waiting on the screen
        // for this flag to settle, and the default three retries a second apart
        // would hold the tile in its optimistic state for most of half a minute
        // before admitting the mailbox never took the change.
        options: RequestOptions.withNoRetries(),
      );
    } on UnauthorizedException catch (e) {
      await _appDatabase.voicemailDao.updateVoicemail(before);
      _sessionGuard.onUnauthorized(e);
      rethrow;
    } catch (e) {
      await _appDatabase.voicemailDao.updateVoicemail(before);
      rethrow;
    }
  }

  /// Watches the number of voicemails that are currently marked as unread.
  ///
  /// Emits a new value whenever a voicemail is added, removed, or has its seen
  /// flag changed.
  ///
  /// Counted in the database rather than derived from [watchVoicemails]: that
  /// list carries the contact each voicemail resolves to, so a caller holding
  /// it open for the whole session - the unread counter behind a badge does -
  /// would have the contact join re-run for it on every contacts write. The
  /// two agree because a voicemail's read status is exactly its `seen` flag.
  @override
  Stream<int> watchUnreadVoicemailsCount() {
    return _appDatabase.voicemailDao.watchUnreadVoicemailsCount();
  }

  /// Watches the list of voicemails currently stored in the local database.
  ///
  /// Emits the full list of [Voicemail] objects whenever:
  /// - the database content changes (insert/update/delete),
  /// - or the repository pushes cached/remote updates.
  ///
  /// If the repository is disabled (e.g. due to feature flag or configuration),
  /// returns an empty stream that never emits values.
  ///
  /// Returns a broadcast [Stream<List<Voicemail>>], or an empty stream if disabled.
  @override
  Stream<List<Voicemail>> watchVoicemails() {
    return _updatesController?.stream ?? const Stream.empty();
  }

  Voicemail _voicemailFromDriftWithContact(VoicemailWithContact data, {ReadStatus? readStatus}) {
    final displayName = data.contact != null ? contactFromDrift(data.contact!).maybeName : null;

    return voicemailFromDrift(data.voicemail, displayName ?? data.voicemail.sender, readStatus: readStatus);
  }

  @override
  Future<void> refresh() {
    return fetchVoicemails();
  }

  @override
  Future<void> removeMultipleVoicemails(List<String> messagesIds) async {
    if (_fetching != null) {
      await _fetching;
    }

    await _removeEach(messagesIds);
  }

  /// Removes [messageIds] one by one through [removeVoicemail], which deletes
  /// the local row itself once the server has confirmed.
  ///
  /// A message the server rejected is logged and skipped so that the rest still
  /// go, and the first rejection is kept and rethrown once the loop is done.
  /// Anything else is rethrown where it happened: see [_isMessageRejection].
  Future<void> _removeEach(Iterable<String> messageIds) async {
    Object? firstRejection;
    StackTrace? firstStack;

    for (final messageId in messageIds) {
      try {
        await removeVoicemail(messageId);
      } catch (e, st) {
        if (!_isMessageRejection(e)) rethrow;

        _logger.warning('Voicemail $messageId was not removed', e, st);
        firstRejection ??= e;
        firstStack ??= st;
      }
    }

    if (firstRejection != null) {
      Error.throwWithStackTrace(firstRejection, firstStack!);
    }
  }

  /// Whether [error] is the server rejecting this one message, rather than a
  /// condition that will hold for every message left in the loop.
  ///
  /// Only a rejection is worth skipping over. Everything else - an expired
  /// session, an account that is gone, voicemail switched off, an endpoint this
  /// deployment does not serve - fails identically for every message, so
  /// carrying on would spend one doomed request per message and report the
  /// last message's problem instead of the real one. A mailbox of a hundred
  /// messages makes that minutes of waiting.
  ///
  /// The test is deliberately narrow: the client raises a [RequestFailure]
  /// subclass of its own for every condition it recognises, and none of those
  /// are about a single message, so what counts as a rejection is a plain
  /// [RequestFailure] carrying the status the server answered with. A request
  /// that never arrived - a timeout, a dead socket - is not a [RequestFailure]
  /// at all, and an exception the client learns to map later will stop the loop
  /// rather than be mistaken for one message's problem.
  static bool _isMessageRejection(Object error) =>
      error is RequestFailure && error.runtimeType == RequestFailure && error.statusCode != null;
}

/// A no-op implementation of [VoicemailRepository] used when voicemail functionality
/// is disabled or not available.
///
/// All methods in this repository perform no actions and return default or
/// empty values (e.g., `Future.value()`, `Stream.value(0)`, `Stream.value(const [])`).
///
/// This serves as a placeholder to prevent errors when other parts of the application
/// attempt to interact with the [VoicemailRepository] interface, even if the feature
/// is not enabled.

class EmptyVoicemailRepository implements VoicemailRepository {
  const EmptyVoicemailRepository();

  @override
  bool get isActive => false;

  @override
  Future<void> fetchVoicemails({String? localeCode}) => Future.value();

  @override
  Future<void> removeVoicemail(String messageId, {String? localeCode}) => Future.value();

  @override
  Future<void> removeAllVoicemails() => Future.value();

  @override
  Future<void> updateVoicemailSeenStatus(String messageId, bool seen, {String? localeCode}) => Future.value();

  @override
  Stream<int> watchUnreadVoicemailsCount() => Stream.value(0);

  @override
  Stream<List<Voicemail>> watchVoicemails() => Stream.value(const []);

  @override
  Future<void> refresh() => Future.value();

  @override
  Future<void> removeMultipleVoicemails(List<String> messagesIds) => Future.value();

  @override
  bool get isFeatureSupported => false;
}
