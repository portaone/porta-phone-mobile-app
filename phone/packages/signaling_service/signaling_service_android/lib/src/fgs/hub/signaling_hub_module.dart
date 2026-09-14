import 'dart:async';

import 'package:logging/logging.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'signaling_hub_client.dart';

final _logger = Logger('SignalingHubModule');

/// [SignalingModule] implementation backed by a [SignalingHubClient].
///
/// Used by the main isolate when [SignalingHub] is already running in the
/// foreground-service isolate. Routes all execute calls through the hub's
/// WebSocket rather than opening an additional connection.
///
/// [connect] sends a [SignalingHubConnectCommand] to the foreground-service
/// isolate, which calls [SignalingModule.connect] on the real WebSocket module.
/// [disconnect] sends a [SignalingHubDisconnectCommand] similarly.
/// [dispose] unsubscribes from the hub and releases resources.
///
/// ## No buffer of its own
///
/// [SignalingHub] brings a new [SignalingHubClient] up to date right after
/// its subscribe ack, with the session's lifecycle events and a handshake
/// rendered from its session snapshot. That replay is delivered once, so the
/// one consumer of [events] - [HubConnectionManager] - listens before the ack
/// is awaited and misses nothing; a listener that comes later sees only what
/// follows. Consumers further up subscribe to the plugin, which keeps the
/// session buffer for them.
class SignalingHubModule implements SignalingModule {
  SignalingHubModule(this._hubClient) {
    _sub = _hubClient.events.listen(_onHubEvent, onDone: _onHubDone);
    _hubClient.start();
    _logger.fine('SignalingHubModule created, consumerId=${_hubClient.consumerId}');
  }

  final SignalingHubClient _hubClient;

  bool _connected = false;
  StreamSubscription<SignalingModuleEvent>? _sub;

  final _controller = StreamController<SignalingModuleEvent>.broadcast();

  @override
  Stream<SignalingModuleEvent> get events => _controller.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void>? execute(Request request) {
    if (!_connected) return null;
    return _hubClient.execute(request);
  }

  /// Asks the hub to connect the background WebSocket.
  ///
  /// Sends a [SignalingHubConnectCommand] to the foreground-service isolate,
  /// which calls [SignalingModule.connect] on the real WebSocket module.
  /// The resulting [SignalingConnected] event arrives on [events] once the
  /// connection is established.
  @override
  void connect() => _hubClient.sendConnect();

  /// Asks the hub to disconnect the background WebSocket.
  ///
  /// Sends a [SignalingHubDisconnectCommand] to the foreground-service isolate,
  /// which calls [SignalingModule.disconnect] on the real WebSocket module.
  /// The resulting [SignalingDisconnected] event arrives on [events].
  @override
  Future<void> disconnect() async => _hubClient.sendDisconnect();

  /// No-op: [SignalingHubModule] routes requests directly through the hub
  /// WebSocket without a local queue, so there is nothing to cancel.
  @override
  void cancelRequestsByCallId(String callId) {}

  /// No-op: [SignalingHubModule] has no local request queue and therefore no
  /// terminating marks to clear.
  @override
  void clearTerminatingMark(String callId) {}

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _hubClient.dispose();
    if (!_controller.isClosed) await _controller.close();
    _logger.fine('SignalingHubModule disposed');
  }

  void _onHubDone() {
    _logger.warning('SignalingHubModule: hub client stream closed — hub unreachable');
    if (!_controller.isClosed) _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onHubEvent(SignalingModuleEvent event) {
    switch (event) {
      case SignalingConnected():
        _connected = true;
        _logger.info('hub event: connected');
      case SignalingDisconnected(:final code, :final reason):
        _connected = false;
        _logger.info('hub event: disconnected code=$code reason=$reason');
      case SignalingConnectionFailed(:final error, :final isRepeated):
        _connected = false;
        _logger.warning('hub event: connection failed isRepeated=$isRepeated -- $error');
      case SignalingHandshakeReceived(:final handshake):
        _logger.info('hub event: handshake lines=${handshake.lines}');
      case SignalingProtocolEvent(:final event):
        _logger.fine('hub event: protocol ${event.runtimeType}');
      default:
        _logger.fine('hub event: ${event.runtimeType}');
    }

    if (_controller.isClosed) return;
    _controller.add(event);
  }
}
