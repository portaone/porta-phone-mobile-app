import 'dart:async';

import 'package:logging/logging.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

final _logger = Logger('SignalingInbound');

/// The features the session's signaling events are split between.
enum SignalingConsumer {
  /// The connection, the handshake and the events of calls, lines,
  /// conferences, presence and dialogs.
  call,
}

/// Where the session's signaling events are split between features.
///
/// Feature-level routing lives here, at the session, so a feature does not take
/// in, and does not have to skip, events that belong to another one. Each
/// event has one consumer, named by [consumerOf] - the one place that knows
/// which feature an event is for. A feature's stream carries only what is its
/// own: an event of no consumer goes nowhere, so a new kind of event the server
/// starts sending reaches no feature until it is given one here.
///
/// It holds no subscription of its own: each listener of a feature's stream
/// takes its own stream from the module at the moment it listens, so it gets
/// the module's replay of the session (the connection and the handshake) as a
/// direct listener would, and hears events in the order it subscribed.
///
/// An error on the module's stream goes to the call stream only, as it reached
/// the call feature before the split; no other feature takes the transport's
/// errors.
class SignalingInbound {
  SignalingInbound(this._events);

  /// A fresh stream of the module's events: [SignalingModule.events].
  final Stream<SignalingModuleEvent> Function() _events;

  /// The feature [event] is for, or null when it is for none.
  static SignalingConsumer? consumerOf(SignalingModuleEvent event) => switch (event) {
    SignalingProtocolEvent(event: SessionEvent() || GlobalEvent()) => SignalingConsumer.call,
    SignalingProtocolEvent() => null,
    // The connection and the handshake.
    _ => SignalingConsumer.call,
  };

  /// What the call feature takes in.
  Stream<SignalingModuleEvent> get call => _route(SignalingConsumer.call, (event) => event);

  /// A stream of the events [consumer] owns, each turned by [select], taken
  /// from the module afresh for each listener and forwarded in the same turn.
  Stream<T> _route<T>(SignalingConsumer consumer, T Function(SignalingModuleEvent event) select) {
    return Stream.multi((controller) {
      final subscription = _events().listen(
        (event) {
          final owner = consumerOf(event);
          if (owner == consumer) {
            controller.addSync(select(event));
          } else if (owner == null && consumer == SignalingConsumer.call) {
            // Told by the call stream, the one every session listens to.
            _logger.fine('no feature takes ${(event as SignalingProtocolEvent).event.runtimeType}');
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
