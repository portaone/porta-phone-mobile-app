import 'package:signaling/signaling.dart';

import 'signaling_module_event.dart';

/// Common interface for signaling module implementations.
///
/// Implemented by the direct WebSocket owner ([SignalingModuleIsolateImpl]) and
/// by [SignalingHubModule] (hub subscriber that routes through the
/// foreground-service WebSocket via [SignalingHub]).
abstract interface class SignalingModule {
  /// Broadcast stream of [SignalingModuleEvent]s.
  ///
  /// Late subscribers receive a replay of all events buffered since the last
  /// [SignalingConnecting] event, so they observe the full current session
  /// state without missing any transitions.
  Stream<SignalingModuleEvent> get events;

  /// Whether the signaling session is currently connected and ready to execute requests.
  bool get isConnected;

  /// The session as the module knows it now: the handshake rendered from
  /// the session's state after every event received so far, or `null`
  /// before a handshake. A consumer that plans from a handshake it received
  /// earlier reads this once it is ready to act, so a call that ended in the
  /// meantime is already gone from what it plans on.
  StateHandshake? get sessionHandshake;

  /// Sends [request] to the server and returns a [Future] that completes when
  /// the server acknowledges it.
  ///
  /// Returns null when not connected -- callers may safely `await` the result.
  Future<void>? execute(Request request);

  /// Initiates a new connection attempt. Fire-and-forget.
  ///
  /// On [SignalingHubModule] this is a no-op -- the hub owns the connection.
  void connect();

  /// Gracefully closes the current connection.
  ///
  /// On [SignalingHubModule] this is a no-op -- the hub owns the connection.
  Future<void> disconnect();

  /// Releases all resources. After [dispose] the instance must not be used.
  Future<void> dispose();

  /// Cancels all pending queued requests for [callId].
  ///
  /// Useful when a call is being terminated before the signaling connection
  /// is established — prevents a queued [OutgoingCallRequest] from being
  /// sent on reconnect and immediately unblocks any [execute] future
  /// awaiting that request.
  ///
  /// No-op if there are no matching requests in the queue.
  void cancelRequestsByCallId(String callId);

  /// Removes the post-cancel enqueue guard set by [cancelRequestsByCallId].
  ///
  /// Call this once the call teardown is fully complete to prevent guard
  /// entries from accumulating for the lifetime of the module. Safe to call
  /// even if [cancelRequestsByCallId] was never called for [callId].
  ///
  /// No-op on implementations that do not use a local request queue.
  void clearTerminatingMark(String callId);
}
