import 'package:equatable/equatable.dart';

/// One call queue the signed-in user serves as an agent.
///
/// A call queue is a hunt group on the PBX with a queue attached: callers wait
/// in it until an agent takes them. Being logged in is per queue, so an agent
/// can be taking calls from one while logged out of another.
class CallQueue extends Equatable {
  const CallQueue({
    required this.id,
    required this.name,
    required this.loggedIn,
    required this.agentsTotal,
    required this.agentsLoggedIn,
    this.callersWaiting,
  });

  /// The queue's number, which is also what logging in and out is addressed by.
  final String id;

  final String name;

  /// Whether this user is currently taking calls from the queue.
  final bool loggedIn;

  final int agentsTotal;

  /// How many agents are logged in right now; legitimately zero.
  final int agentsLoggedIn;

  /// How many callers are queued, or null when the figure is unknown.
  ///
  /// Unknown is permanent wherever the PBX call control interface is
  /// unavailable, so a screen has to read sensibly without it. It is never
  /// turned into a zero on the way here: zero is the PBX saying nobody is
  /// waiting, and showing that while callers are on hold is the one mistake
  /// this field invites.
  final int? callersWaiting;

  @override
  List<Object?> get props => [id, name, loggedIn, agentsTotal, agentsLoggedIn, callersWaiting];
}
