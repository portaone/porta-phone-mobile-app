import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

part 'call_queues_state.dart';

part 'call_queues_cubit.freezed.dart';

final _logger = Logger('CallQueuesCubit');

/// What a log in or log out ended as, in the terms the screen speaks.
///
/// Returned rather than published as state: each outcome is a sentence said
/// once, to the person who just tapped, and a state field would have to be
/// cleared again afterwards by whoever happened to read it.
enum CallQueueWriteOutcome {
  ok,

  /// The queue is not this user's any more - the list was older than the PBX
  /// and has been asked for again.
  queueGone,

  /// The PBX site is read-only (disaster recovery): reads work, writes do not.
  readOnly,

  failed,
}

class CallQueuesCubit extends Cubit<CallQueuesState> {
  CallQueuesCubit(this._repository) : super(CallQueuesState.of(_repository.snapshot)) {
    _subscription = _repository.watch().listen(_onSnapshot);
  }

  final CallQueuesRepository _repository;

  late final StreamSubscription<CallQueuesSnapshot> _subscription;

  /// Asks for the queues once.
  ///
  /// Nothing is emitted here: the repository publishes both the answer and a
  /// failure to read it, so a screen reads one state whether the request came
  /// from here or from the polling task nobody awaits.
  Future<void> refresh() async {
    try {
      await _repository.refresh();
    } catch (e, stackTrace) {
      _logger.warning('refresh', e, stackTrace);
    }
  }

  Future<CallQueueWriteOutcome> setLoggedIn(String queueId, {required bool loggedIn}) {
    return _write(() => _repository.setLoggedIn(queueId, loggedIn: loggedIn));
  }

  Future<CallQueueWriteOutcome> setAllLoggedIn({required bool loggedIn}) {
    return _write(() => _repository.setAllLoggedIn(loggedIn: loggedIn));
  }

  Future<CallQueueWriteOutcome> _write(Future<void> Function() request) async {
    try {
      await request();
      return CallQueueWriteOutcome.ok;
    } on api.CallQueueNotFoundException {
      return CallQueueWriteOutcome.queueGone;
    } catch (e, stackTrace) {
      _logger.warning('write', e, stackTrace);
      if (e is api.RequestFailure && e.statusCode == 503) return CallQueueWriteOutcome.readOnly;
      return CallQueueWriteOutcome.failed;
    }
  }

  void _onSnapshot(CallQueuesSnapshot snapshot) => emit(CallQueuesState.of(snapshot));

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
