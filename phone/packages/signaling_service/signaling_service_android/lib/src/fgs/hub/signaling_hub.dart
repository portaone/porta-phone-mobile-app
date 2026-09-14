import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:logging/logging.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import '../../constants.dart';
import 'signaling_hub_codec.dart';
import 'signaling_hub_command.dart';

final _logger = Logger('SignalingHub');

/// Wraps a [SignalingModule] and exposes its event stream to other isolates
/// via [IsolateNameServer].
///
/// [SignalingForegroundIsolateManager] creates and owns one hub instance.
/// Any isolate (e.g. push notification isolate) can subscribe by looking up
/// [kSignalingHubPortName] via [IsolateNameServer].
///
/// A subscriber that attaches after the session started is brought up to date
/// with state, not history: it receives the session's lifecycle events and a
/// handshake rendered from the hub's [SessionSnapshot] - the calls that are up
/// with their events so far, the registration as it stands - and takes the
/// same path it takes after a reconnect. Protocol events are never replayed.
///
/// Protocol -- subscriber -> hub: [SignalingHubCommand.encode] / [SignalingHubCommand.decode].
/// Protocol -- hub -> subscriber (List): see [encodeHubEvent] / [decodeHubEvent].
class SignalingHub {
  SignalingHub(this._signalingModule);

  final SignalingModule _signalingModule;
  final ReceivePort _receivePort = ReceivePort();

  /// consumerId -> subscriber SendPort
  final Map<String, SendPort> _subscribers = {};

  /// True when at least one subscriber (from any isolate) is connected.
  ///
  /// Used by [SignalingForegroundIsolateManager] to decide whether reconnect
  /// decisions should be delegated (subscribers present — at least one isolate
  /// can drive reconnects) or handled locally in the background isolate
  /// (no subscribers — app is closed, persistent-service mode).
  bool get hasSubscribers => _subscribers.isNotEmpty;

  /// True when a call is up on any line of the session.
  ///
  /// Used by [SignalingSyncHandler] to skip manager recreation when a config-change
  /// sync arrives mid-call, preventing the WebSocket from being torn down while
  /// the user is on a call.
  bool get hasActiveCalls => _session.hasActiveCalls;

  /// The session as a late subscriber needs it: the lifecycle events of the
  /// current WebSocket session and a handshake rendered from the session's
  /// state as it stands now - the same [SignalingEventBuffer] every other
  /// replay boundary keeps, so the app isolate and this hub cannot disagree
  /// about which calls are up. Encoded on replay, never stored encoded.
  ///
  /// A late subscriber is a new isolate with no memory of the session: what it
  /// needs is where the session stands, not the events that got it there.
  /// Replaying events would mean replaying the right ones, in the right order,
  /// with the buffered handshake patched to agree with them - a second copy of
  /// the call state machine, kept in the transport.
  final SignalingEventBuffer _session = SignalingEventBuffer();

  StreamSubscription<SignalingModuleEvent>? _moduleSubscription;
  bool _started = false;

  /// Registers the hub port in [IsolateNameServer] and begins forwarding
  /// [SignalingModule] events to subscribers.
  ///
  /// Calling [start] more than once is a no-op.
  void start() {
    if (_started) return;
    _started = true;

    // Remove any stale mapping from a previous isolate that was destroyed without
    // calling dispose() -- registerPortWithName returns false (silently no-ops)
    // when the name is already taken, so we clear it first.
    IsolateNameServer.removePortNameMapping(kSignalingHubPortName);
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, kSignalingHubPortName);
    _logger.fine('Hub started and registered as $kSignalingHubPortName');

    _moduleSubscription = _signalingModule.events.listen(_onModuleEvent);
    _receivePort.listen((msg) {
      final cmd = SignalingHubCommand.decode(msg);
      if (cmd == null) {
        _logger.warning('Hub ignoring unrecognised message: $msg');
        return;
      }
      _onCommand(cmd);
    });
  }

  /// Removes the hub from [IsolateNameServer], cancels all subscriptions,
  /// and closes the receive port. After [dispose] the hub must not be used.
  Future<void> dispose() async {
    _logger.warning(
      'Hub disposing — cancelling event forwarding to ${_subscribers.length} subscriber(s); '
      'active calls: $hasActiveCalls',
    );
    IsolateNameServer.removePortNameMapping(kSignalingHubPortName);
    await _moduleSubscription?.cancel();
    _receivePort.close();
    _subscribers.clear();
    _session.clear();
    _logger.fine('Hub disposed');
  }

  void _onModuleEvent(SignalingModuleEvent event) {
    _session.onEvent(event);
    _broadcast(encodeHubEvent(event));
  }

  void _broadcast(List<dynamic> encoded) {
    for (final port in _subscribers.values) {
      port.send(encoded);
    }
  }

  void _onCommand(SignalingHubCommand cmd) {
    switch (cmd) {
      case SignalingHubSubscribeCommand():
        _handleSubscribe(cmd);
      case SignalingHubUnsubscribeCommand():
        _handleUnsubscribe(cmd);
      case SignalingHubExecuteCommand():
        _handleExecute(cmd);
      case SignalingHubConnectCommand():
        if (!_subscribers.containsKey(cmd.consumerId)) {
          _logger.warning('Hub connect: unknown subscriber ${cmd.consumerId}');
          return;
        }
        _logger.fine('Hub received connect command from ${cmd.consumerId}');
        _signalingModule.connect();
      case SignalingHubDisconnectCommand():
        if (!_subscribers.containsKey(cmd.consumerId)) {
          _logger.warning('Hub disconnect: unknown subscriber ${cmd.consumerId}');
          return;
        }
        _logger.fine('Hub received disconnect command from ${cmd.consumerId}');
        unawaited(_signalingModule.disconnect());
      case SignalingHubPingCommand():
        final port = _subscribers[cmd.consumerId];
        if (port == null) {
          _logger.warning('Hub ping: unknown subscriber ${cmd.consumerId}');
          return;
        }
        port.send(encodePong());
    }
  }

  void _handleSubscribe(SignalingHubSubscribeCommand cmd) {
    _subscribers[cmd.consumerId] = cmd.replyPort;
    _logger.fine('Hub subscriber added: ${cmd.consumerId} (total: ${_subscribers.length})');
    // Ack first so the subscriber knows the hub port is alive (not stale).
    cmd.replyPort.send(encodeSubAck());
    // Replay the session's lifecycle, with the handshake rendered from the
    // session as it stands now: the calls that are up with their events so
    // far, and the registration as it is, not as the handshake first said.
    for (final event in _session.snapshot) {
      cmd.replyPort.send(encodeHubEvent(event));
    }
  }

  void _handleUnsubscribe(SignalingHubUnsubscribeCommand cmd) {
    _subscribers.remove(cmd.consumerId);
    _logger.fine('Hub subscriber removed: ${cmd.consumerId} (total: ${_subscribers.length})');
  }

  void _handleExecute(SignalingHubExecuteCommand cmd) {
    final port = _subscribers[cmd.consumerId];
    if (port == null) {
      _logger.warning('Hub execute: unknown subscriber ${cmd.consumerId}, corr=${cmd.correlationId}');
      return;
    }
    unawaited(_executeAndReply(port, cmd.correlationId, cmd.request));
  }

  Future<void> _executeAndReply(SendPort replyPort, String correlationId, Map<String, dynamic> reqMap) async {
    try {
      final request = Request.fromJson(reqMap);
      if (!_signalingModule.isConnected) throw NotConnectedException('ghost state: hub isConnected=false');
      await _signalingModule.execute(request)!;
      replyPort.send(encodeExecuteResult(correlationId, null));
    } catch (e) {
      _logger.warning('Hub execute error: $e, corr=$correlationId');
      replyPort.send(encodeExecuteResult(correlationId, e));
    }
  }
}
