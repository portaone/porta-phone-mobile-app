import 'dart:async';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

/// What became of a request handed to the session's signaling.
sealed class SignalingOutcome {
  const SignalingOutcome();
}

/// The server took the request.
final class SignalingSent extends SignalingOutcome {
  const SignalingSent();
}

/// Nothing could be handed the request: the module answered `null`.
final class SignalingNotSent extends SignalingOutcome {
  const SignalingNotSent();
}

/// The request went with the signaling: its connection was lost, or never
/// there, before the server's answer ([isSignalingLoss]). The server may still
/// hold what the request was about.
final class SignalingLost extends SignalingOutcome {
  const SignalingLost(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Any other failure of the request: the server refused it, or something
/// other than the connection went wrong.
final class SignalingRefused extends SignalingOutcome {
  const SignalingRefused(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Whether [error] of a request is the signaling being lost under it rather
/// than the request failing: the one place that says which errors those are.
bool isSignalingLoss(Object error) {
  // The signaling client throws a disconnected error when its socket closed
  // between the module handing it the request and the send: the same loss
  // of signaling as the others, only met a moment later.
  return error is NotConnectedException ||
      error is SignalingDisconnectedException ||
      error is SignalingTransactionTimeoutException ||
      error is SignalingTransactionTerminateByDisconnectException ||
      error is TimeoutException;
}

/// What the call feature asks of the session's signaling: to send its
/// requests, to hear the answers to them, and how the session stands.
///
/// It has no stream of the session's events on purpose: those reach the call
/// feature only through the shell's SignalingInbound, so nothing here can
/// subscribe around the routing.
abstract interface class CallSignaling {
  /// Whether the session is connected and ready to execute requests.
  bool get isConnected;

  /// The session as the module knows it now; see [SignalingModule.sessionHandshake].
  StateHandshake? get sessionHandshake;

  /// Sends [request]; null when not connected. See [SignalingModule.execute].
  ///
  /// The module's own contract; a caller moved to [send] reads what became of
  /// the request as a value instead.
  Future<void>? execute(Request request);

  /// Sends [request] and says what became of it; never throws.
  Future<SignalingOutcome> send(Request request);

  /// The server's answer to the request sent with [transaction]: the first
  /// session event that names it, within [timeout] - a [TimeoutException]
  /// otherwise, and a [StateError] if the session's events end first.
  ///
  /// Listens from the moment it is asked. The module does not replay protocol
  /// events, so an answer that arrived before this was asked is not found and
  /// the wait runs out its [timeout].
  Future<Event> response(String transaction, {required Duration timeout});

  /// [response], given up when [until] completes first: then it lets go of the
  /// session's events at once and completes with null.
  Future<Event?> responseUntil(String transaction, {required Duration timeout, required Future<void> until});

  /// See [SignalingModule.cancelRequestsByCallId].
  void cancelRequestsByCallId(String callId);

  /// See [SignalingModule.clearTerminatingMark].
  void clearTerminatingMark(String callId);
}

/// [CallSignaling] over the session's [SignalingModule], hearing answers on
/// the call feature's own stream of events (the shell's SignalingInbound).
class ModuleCallSignaling implements CallSignaling {
  ModuleCallSignaling(this._module, {required Stream<SignalingModuleEvent> events}) : _events = events;

  final SignalingModule _module;
  final Stream<SignalingModuleEvent> _events;

  @override
  bool get isConnected => _module.isConnected;

  @override
  StateHandshake? get sessionHandshake => _module.sessionHandshake;

  @override
  Future<void>? execute(Request request) => _module.execute(request);

  @override
  Future<SignalingOutcome> send(Request request) async {
    try {
      final sent = _module.execute(request);
      if (sent == null) return const SignalingNotSent();
      await sent;
      return const SignalingSent();
    } catch (error, stackTrace) {
      return isSignalingLoss(error) ? SignalingLost(error, stackTrace) : SignalingRefused(error, stackTrace);
    }
  }

  @override
  Future<Event> response(String transaction, {required Duration timeout}) =>
      _wait(transaction, timeout: timeout).then((event) => event!);

  @override
  Future<Event?> responseUntil(String transaction, {required Duration timeout, required Future<void> until}) =>
      _wait(transaction, timeout: timeout, until: until);

  /// The wait behind both: completes with the answer, with null when [until]
  /// came first, or with an error.
  Future<Event?> _wait(String transaction, {required Duration timeout, Future<void>? until}) {
    final answer = Completer<Event?>();
    StreamSubscription<SignalingModuleEvent>? subscription;
    Timer? deadline;

    // Ends the wait either way and lets go of the stream: a wait that ran out
    // or was given up must not stay subscribed for the rest of the session.
    void finish(void Function() settle) {
      if (answer.isCompleted) return;
      deadline?.cancel();
      unawaited(subscription?.cancel());
      settle();
    }

    // Before listening: an answer settled while listen() runs then finds the
    // deadline to cancel.
    deadline = Timer(
      timeout,
      () => finish(() => answer.completeError(TimeoutException('No answer to $transaction', timeout))),
    );
    subscription = _events.listen(
      (event) {
        if (event case SignalingProtocolEvent(event: final SessionEvent sessionEvent)
            when sessionEvent.transaction == transaction) {
          finish(() => answer.complete(sessionEvent));
        }
      },
      onError: (Object error, StackTrace stackTrace) => finish(() => answer.completeError(error, stackTrace)),
      onDone: () => finish(() => answer.completeError(StateError('No answer to $transaction: the events ended'))),
    );
    // An answer settled while listen() was still returning left the
    // subscription to cancel here.
    if (answer.isCompleted) unawaited(subscription.cancel());
    until?.whenComplete(() => finish(() => answer.complete(null))).ignore();
    return answer.future;
  }

  @override
  void cancelRequestsByCallId(String callId) => _module.cancelRequestsByCallId(callId);

  @override
  void clearTerminatingMark(String callId) => _module.clearTerminatingMark(callId);
}
