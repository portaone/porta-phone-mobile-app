import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session.dart';
import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

final _logger = Logger('CallQueuesRepository');

/// The call queues the signed-in user serves as an agent, and their two writes.
///
/// The backend is the only owner of the login state: the same flag is changed
/// by the PBX dial codes and by the self-care portal, so every answer is
/// rendered as it arrives and nothing is flipped locally on a tap.
abstract interface class CallQueuesRepository implements Refreshable, Disposable {
  /// What is known about the queues, starting with what is known already.
  Stream<CallQueuesSnapshot> watch();

  /// The latest snapshot, for a caller that needs an answer rather than a
  /// subscription - the settings row asking whether to show itself at all.
  CallQueuesSnapshot get snapshot;

  /// Logs the user in to one queue, or out of it.
  Future<void> setLoggedIn(String queueId, {required bool loggedIn});

  /// Logs the user in to every queue at once, or out of every one.
  Future<void> setAllLoggedIn({required bool loggedIn});
}

class CallQueuesRepositoryApiImpl with CallQueueApiMapper implements CallQueuesRepository {
  CallQueuesRepositoryApiImpl({
    required api.WebtritApiClient apiClient,
    required String token,
    required SessionGuard sessionGuard,
  }) : _apiClient = apiClient,
       _token = token,
       _sessionGuard = sessionGuard;

  final api.WebtritApiClient _apiClient;
  final String _token;
  final SessionGuard _sessionGuard;

  final _snapshot = BehaviorSubject<CallQueuesSnapshot>.seeded(const CallQueuesSnapshot());

  /// Bumped by every write that the backend accepted.
  ///
  /// A read that started before a write carries the state from before it, and
  /// applying that answer would flip the agent back for a whole poll interval -
  /// visibly undoing what they just did. The counter is how such an answer is
  /// recognised on arrival: it started in one generation and came back in
  /// another, so it is dropped.
  int _writeGeneration = 0;

  Future<void>? _inFlightRead;

  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  CallQueuesSnapshot get snapshot => _snapshot.value;

  @override
  Stream<CallQueuesSnapshot> watch() => _snapshot.stream;

  /// A read, shared by everyone who asks for one while it is in flight.
  ///
  /// Both placements of the screen and the session's own first read go through
  /// here, and each read makes the backend walk the customer's whole hunt group
  /// list - so two callers arriving together get one request rather than two.
  @override
  Future<void> refresh() {
    if (!_active) return Future.value();

    return _inFlightRead ??= _read().whenComplete(() => _inFlightRead = null);
  }

  Future<void> _read() async {
    final generation = _writeGeneration;

    final api.CallQueueListResponse response;
    try {
      response = await _apiClient.getUserCallQueues(_token);
    } on api.EndpointNotSupportedException catch (e) {
      if (!_isRouteAbsent(e)) {
        _publishReadFailure();
        rethrow;
      }
      _logger.info('Call queues are not offered by this deployment, stopping: $e');
      _deactivate();
      return;
    } on api.UnauthorizedException catch (e) {
      _sessionGuard.onUnauthorized(e);
      _publishReadFailure();
      rethrow;
    } catch (_) {
      _publishReadFailure();
      rethrow;
    }

    if (generation != _writeGeneration) {
      _logger.fine('Dropping a read that started before a write');
      return;
    }

    _apply(callQueuesFromApi(response.items));
  }

  /// Whether this refusal means the route is not there at all.
  ///
  /// A 501 says so outright. A 404 does not: the transport reports a bare one
  /// as "not supported" because an absent route answers that way, but so does
  /// an ingress in front of a backend that is briefly down. Once a read has
  /// succeeded the route demonstrably exists, so a later bare 404 is a failure
  /// to retry rather than a reason to take an agent's queues off their screen
  /// for the rest of the session.
  bool _isRouteAbsent(api.EndpointNotSupportedException e) => e.statusCode == 501 || !snapshot.known;

  @override
  Future<void> setLoggedIn(String queueId, {required bool loggedIn}) async {
    if (snapshot.isPending(queueId)) return;

    _emit(snapshot.copyWith(pendingIds: {...snapshot.pendingIds, queueId}));
    try {
      final queue = await _write(() => _apiClient.updateUserCallQueue(_token, queueId, loggedIn: loggedIn));
      _replace(callQueueFromApi(queue));
    } on api.CallQueueNotFoundException {
      // The queue is not this user's any more, so the list on screen is older
      // than the PBX. The row keeps what it shows until a read replaces it -
      // the write never happened, and inventing a state for it would be worse
      // than leaving the stale one for one more cycle.
      _clearPending(queueId);
      await _refreshQuietly();
      rethrow;
    } finally {
      _clearPending(queueId);
    }
  }

  @override
  Future<void> setAllLoggedIn({required bool loggedIn}) async {
    if (snapshot.isBusy) return;

    _emit(snapshot.copyWith(allPending: true));
    try {
      final response = await _write(() => _apiClient.updateUserCallQueues(_token, loggedIn: loggedIn));
      _emit(snapshot.copyWith(queues: callQueuesFromApi(response.items), known: true, allPending: false));
    } finally {
      if (!_snapshot.isClosed && snapshot.allPending) _emit(snapshot.copyWith(allPending: false));
    }
  }

  @override
  Future<void> dispose() => _snapshot.close();

  /// Runs one write, translating the two refusals every route here shares and
  /// bumping the generation once the backend has accepted it.
  Future<T> _write<T>(Future<T> Function() request) async {
    final T result;
    try {
      result = await request();
    } on api.EndpointNotSupportedException catch (e) {
      if (_isRouteAbsent(e)) {
        _logger.info('Call queues are not offered by this deployment, stopping: $e');
        _deactivate();
      }
      rethrow;
    } on api.UnauthorizedException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    }

    _writeGeneration++;
    return result;
  }

  /// A read asked for by a failed write rather than by the poll.
  ///
  /// Its failure is not the caller's: they are already being told that their
  /// write did not happen, and a second error about the refresh would replace
  /// that with something they can do nothing about.
  Future<void> _refreshQuietly() async {
    try {
      await refresh();
    } catch (e, stackTrace) {
      _logger.warning('Refresh after a refused write failed', e, stackTrace);
    }
  }

  /// Applies a read, keeping whatever has a write in flight.
  ///
  /// A row whose own request has not answered yet still shows what the user
  /// left it at, and a read that overwrote it would flicker the switch back
  /// before flipping it again. While every queue is being written at once, the
  /// whole answer is dropped for the same reason.
  void _apply(List<CallQueue> incoming) {
    final current = snapshot;

    if (current.allPending) {
      _emit(current.copyWith(known: true, readFailed: false));
      return;
    }

    if (current.pendingIds.isEmpty) {
      _emit(current.copyWith(queues: incoming, known: true, readFailed: false));
      return;
    }

    final held = {for (final queue in current.queues) queue.id: queue};
    final merged = [for (final queue in incoming) current.isPending(queue.id) ? (held[queue.id] ?? queue) : queue];
    _emit(current.copyWith(queues: merged, known: true, readFailed: false));
  }

  /// Says that a read failed, keeping whatever was read before it.
  void _publishReadFailure() => _emit(snapshot.copyWith(readFailed: true));

  void _replace(CallQueue updated) {
    final queues = [
      for (final queue in snapshot.queues)
        if (queue.id == updated.id) updated else queue,
    ];
    _emit(snapshot.copyWith(queues: queues, known: true));
  }

  void _clearPending(String queueId) {
    if (!snapshot.pendingIds.contains(queueId)) return;
    _emit(snapshot.copyWith(pendingIds: {...snapshot.pendingIds}..remove(queueId)));
  }

  void _deactivate() {
    _active = false;
    _emit(const CallQueuesSnapshot(known: true));
  }

  void _emit(CallQueuesSnapshot next) {
    if (_snapshot.isClosed) return;
    _snapshot.add(next);
  }
}

/// What every caller gets where the deployment does not offer call queues.
///
/// It answers "nothing is known and nothing is coming", so a placement reading
/// it hides itself without having to know why.
class EmptyCallQueuesRepository implements CallQueuesRepository {
  const EmptyCallQueuesRepository();

  @override
  bool get isActive => false;

  @override
  CallQueuesSnapshot get snapshot => const CallQueuesSnapshot(known: true);

  @override
  Stream<CallQueuesSnapshot> watch() => Stream.value(const CallQueuesSnapshot(known: true));

  @override
  Future<void> refresh() => Future.value();

  @override
  Future<void> setLoggedIn(String queueId, {required bool loggedIn}) => Future.value();

  @override
  Future<void> setAllLoggedIn({required bool loggedIn}) => Future.value();

  @override
  Future<void> dispose() => Future.value();
}
