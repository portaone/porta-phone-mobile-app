import 'dart:async';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

CallQueue testQueue(
  String id, {
  String? name,
  bool loggedIn = true,
  int agentsTotal = 3,
  int agentsLoggedIn = 2,
  int? callersWaiting = 0,
}) => CallQueue(
  id: id,
  name: name ?? 'Queue $id',
  loggedIn: loggedIn,
  agentsTotal: agentsTotal,
  agentsLoggedIn: agentsLoggedIn,
  callersWaiting: callersWaiting,
);

/// A repository the screen can be driven against, recording what it was asked
/// to write and letting a test decide what the backend answered.
class FakeCallQueuesRepository implements CallQueuesRepository {
  FakeCallQueuesRepository({CallQueuesSnapshot? initial})
    : _snapshot = initial ?? const CallQueuesSnapshot(known: true);

  final _controller = StreamController<CallQueuesSnapshot>.broadcast();

  CallQueuesSnapshot _snapshot;

  final writes = <String>[];

  Object? failWith;

  int refreshCount = 0;

  @override
  bool get isActive => true;

  @override
  CallQueuesSnapshot get snapshot => _snapshot;

  @override
  Stream<CallQueuesSnapshot> watch() => _controller.stream;

  void emit(CallQueuesSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
    final failure = failWith;
    if (failure != null) throw failure;
  }

  @override
  Future<void> setLoggedIn(String queueId, {required bool loggedIn}) async {
    writes.add('$queueId:$loggedIn');
    final failure = failWith;
    if (failure != null) throw failure;
  }

  @override
  Future<void> setAllLoggedIn({required bool loggedIn}) async {
    writes.add('all:$loggedIn');
    final failure = failWith;
    if (failure != null) throw failure;
  }

  @override
  Future<void> dispose() => _controller.close();
}
