import 'dart:async';

import 'package:logging/logging.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

final _logger = Logger('SignalingInbound');

/// The features the session's signaling events are split between.
enum SignalingConsumer {
  /// The events of calls, lines, conferences, presence and dialogs.
  call,

  /// The voicemail box changing.
  voicemail,
}

/// Where the session's signaling events are split between features.
///
/// Feature-level routing lives here, at the session, so a feature does not take
/// in, and does not have to skip, events that belong to another one. Each
/// protocol event has one consumer, named by [consumerOf] - the one place that
/// knows which feature an event is for - and a feature's stream carries only
/// what is its own: an event of no consumer goes nowhere, so a new kind of
/// event the server starts sending reaches no feature until it is given one
/// here. The connection and the handshake are the session's, not an event of
/// one feature: the call stream carries them, and a feature reads from them
/// what it needs.
///
/// It holds no subscription of its own: each listener of a feature's stream
/// takes its own stream from the module at the moment it listens, so it gets
/// the module's replay of the session (the connection and the handshake) as a
/// direct listener would, and hears events in the order it subscribed. The
/// streams themselves are made once, so a widget handed one twice sees the
/// same stream.
///
/// An error on the module's stream goes to the call stream only, as it reached
/// the call feature before the split; no other feature takes the transport's
/// errors.
class SignalingInbound {
  SignalingInbound(this._events);

  /// A fresh stream of the module's events: [SignalingModule.events].
  final Stream<SignalingModuleEvent> Function() _events;

  /// The feature [event] is for, or null when it is for none.
  static SignalingConsumer? consumerOf(SignalingProtocolEvent event) => switch (event.event) {
    SessionEvent() || GlobalEvent() => SignalingConsumer.call,
    MessageSummaryUpdate() => SignalingConsumer.voicemail,
    _ => null,
  };

  /// What the call feature takes in: the connection, the handshake and its
  /// own protocol events.
  late final Stream<SignalingModuleEvent> call = _route(
    SignalingConsumer.call,
    (event) => switch (event) {
      SignalingProtocolEvent() => consumerOf(event) == SignalingConsumer.call ? event : null,
      _ => event,
    },
  );

  /// When voicemail should read the box again: the server said it changed,
  /// or the session was (re)established - a change it said while the session
  /// was down, or before this listener came, is not replayed.
  late final Stream<void> voicemail = _route<Object>(
    SignalingConsumer.voicemail,
    (event) => switch (event) {
      SignalingProtocolEvent() => consumerOf(event) == SignalingConsumer.voicemail ? event : null,
      SignalingHandshakeReceived() => event,
      _ => null,
    },
  );

  /// A stream of what [select] keeps of the module's events for [consumer],
  /// taken from the module afresh for each listener and forwarded in the same
  /// turn.
  Stream<T> _route<T extends Object>(SignalingConsumer consumer, T? Function(SignalingModuleEvent event) select) {
    return Stream.multi((controller) {
      final subscription = _events().listen(
        (event) {
          final selected = select(event);
          if (selected != null) {
            controller.addSync(selected);
          } else if (consumer == SignalingConsumer.call &&
              event is SignalingProtocolEvent &&
              consumerOf(event) == null) {
            // Told by the call stream, the one every session listens to.
            _logger.fine('no feature takes ${event.event.runtimeType}');
          }
        },
        onError: consumer == SignalingConsumer.call ? controller.addErrorSync : (Object _, StackTrace _) {},
        onDone: controller.closeSync,
      );
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = subscription.cancel;
    });
  }
}
