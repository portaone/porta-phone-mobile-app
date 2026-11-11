import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:_web_socket_channel/_web_socket_channel.dart';

import 'events/events.dart';
import 'exceptions.dart';
import 'handshakes/handshakes.dart';
import 'receive_watchdog.dart';
import 'requests/requests.dart';
import 'responses/responses.dart';
import 'transaction.dart';

typedef StateHandshakeHandler = void Function(StateHandshake stateHandshake);
typedef EventHandler = void Function(Event event);
typedef ErrorHandler = void Function(Object error, StackTrace? stackTrace);
typedef DisconnectHandler = void Function(int? code, String? reason);

class WebtritSignalingClient {
  static final _callIdRandom = Random();
  static const _callIdChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  @visibleForTesting
  static Uri buildTenantUrl(Uri baseUrl, String tenantId) {
    if (tenantId.isEmpty) {
      return baseUrl;
    } else {
      final baseUrlPathSegments = List.of(baseUrl.pathSegments.where((segment) => segment.isNotEmpty));
      if (baseUrlPathSegments.length >= 2 && baseUrlPathSegments[baseUrlPathSegments.length - 2] == 'tenant') {
        baseUrlPathSegments.removeRange(baseUrlPathSegments.length - 2, baseUrlPathSegments.length);
      }
      return baseUrl.replace(
        pathSegments: [
          ...baseUrlPathSegments,
          ...['tenant', tenantId],
        ],
      );
    }
  }

  static String generateTransactionId() {
    return Transaction.generateId();
  }

  static String generateCallId([int length = 24]) {
    return List.generate(length, (index) => _callIdChars[_callIdRandom.nextInt(_callIdChars.length)]).join();
  }

  static const subprotocol = 'webtrit-protocol';

  static const defaultExecuteTransactionTimeoutDuration = Duration(milliseconds: 10000);

  static int _createCounter = 0;

  @visibleForTesting
  WebtritSignalingClient.inner(this._wsc) : _id = _createCounter, _logger = Logger('WebtritSignalingClient') {
    _createCounter++;

    _logger.fine('$_id connected');
  }

  final int _id;
  final Logger _logger;
  final Set<String> _ignoredTypes = {};

  final WebSocketChannel _wsc;
  StreamSubscription? _wscStreamSubscription;

  late final StateHandshakeHandler _onStateHandshake;
  late final EventHandler _onEvent;
  late final ErrorHandler _onError;
  late final DisconnectHandler _onDisconnect;

  Duration? _keepaliveInterval;
  Timer? _keepaliveTimer;
  bool _keepaliveWaiting = false;
  bool _stateReceived = false;

  /// Asks for a keepalive when nothing was received for the keepalive
  /// interval, whatever was sent meanwhile: requests put the timer of the
  /// keepalive off, and a connection without its state has none.
  late final _receiveWatchdog = ReceiveWatchdog(quiet: () => _currentKeepaliveInterval, onQuiet: _onQuiet);

  Duration get _currentKeepaliveInterval => _keepaliveInterval ?? const Duration(seconds: 30);

  final _transactions = <String, Transaction>{};

  static Future<WebtritSignalingClient> connect(
    Uri baseUrl,
    String tenantId,
    String token,
    bool force, {
    Duration? connectionTimeout,
    TrustedCertificates certs = TrustedCertificates.empty,
  }) async {
    final tenantUrl = buildTenantUrl(baseUrl, tenantId);
    final signalingUrl = tenantUrl
        .replace(
          pathSegments: [...tenantUrl.pathSegments, 'signaling', 'v1'],
          queryParameters: {'token': token, 'force': force.toString()},
        )
        .toString();

    final ws = await connectWebSocket(
      signalingUrl,
      protocols: [subprotocol],
      connectionTimeout: connectionTimeout,
      certs: certs,
    );
    final wsc = createWebSocketChannel(ws);
    return WebtritSignalingClient.inner(wsc);
  }

  void listen({
    required StateHandshakeHandler onStateHandshake,
    required EventHandler onEvent,
    required ErrorHandler onError,
    required DisconnectHandler onDisconnect,
  }) {
    if (_wscStreamSubscription != null) {
      throw StateError('$WebtritSignalingClient with id: $_id has already been listened to');
    }
    _logger.fine('$_id listen');

    _onStateHandshake = onStateHandshake;
    _onEvent = onEvent;
    _onError = onError;
    _onDisconnect = onDisconnect;

    _wscStreamSubscription = _wsc.stream.listen(_wscStreamOnData, onError: _wscStreamOnError, onDone: _wscStreamOnDone);
    _receiveWatchdog.start();
  }

  Future<void> disconnect([int? code, String? reason]) async {
    final wscStreamSubscription = _wscStreamSubscription;
    if (wscStreamSubscription == null) {
      _logger.fine('$_id already disconnected with code: ${_wsc.closeCode} reason: ${_wsc.closeReason}');
    } else {
      _logger.fine('$_id disconnect code: $code reason: $reason');

      _stopTimers();

      _cleanupTransactions(code, reason);

      _wscStreamSubscription = null;

      await wscStreamSubscription.cancel(); // to prevent onDisconnect and other handlers call

      await _wsc.sink.close(code, reason);
    }
  }

  //

  void _wscStreamOnData(dynamic data) {
    _logger.fine('$_id _wsOnData: $data');

    try {
      final Map<String, dynamic> messageJson = jsonDecode(data);
      _onMessage(messageJson);
    } finally {
      // After the message: a state handshake names the interval to watch by.
      _receiveWatchdog.heard();
    }
  }

  void _wscStreamOnError(dynamic error, StackTrace stackTrace) {
    _logger.warning('$_id _wsOnError', error, stackTrace);

    _onError(error, stackTrace);
  }

  void _wscStreamOnDone() {
    final closeCode = _wsc.closeCode;
    final closeReason = _wsc.closeReason;

    _logger.fine('$_id _wsOnDone code: $closeCode reason: $closeReason');

    _stopTimers();

    _cleanupTransactions(closeCode, closeReason);

    _wscStreamSubscription = null;

    _onDisconnect(closeCode, closeReason);
  }

  //

  Future<void> execute(Request request, [Duration timeoutDuration = defaultExecuteTransactionTimeoutDuration]) async {
    if (_wscStreamSubscription == null) {
      throw SignalingDisconnectedException(_id);
    }

    _restartKeepaliveTimer();

    final requestJson = request.toJson();
    final responseJson = await _executeTransaction(requestJson, timeoutDuration);
    final response = Response.fromJson(responseJson);
    if (response is AckResponse) {
      return;
    } else if (response is ErrorResponse) {
      throw SignalingErrorException(_id, response.code, response.reason);
    } else {
      throw SignalingUnknownResponseException(_id, responseJson);
    }
  }

  //

  void _onMessage(Map<String, dynamic> messageJson) {
    if (messageJson.containsKey(Response.typeKey) || messageJson[Handshake.typeKey] == KeepaliveHandshake.typeValue) {
      final responseJson = messageJson;

      final transactionId = responseJson['transaction'];
      final transaction = _transactions.remove(transactionId);

      if (transaction != null) {
        transaction.handleResponse(responseJson);
      } else {
        // Late server response for a transaction that already timed out and was
        // removed from the map. This can happen under network congestion when
        // the server ACK arrives after the client's timeout has fired.
        // Treating this as a connection error would cause a false-positive
        // SignalingConnectionFailed and an unnecessary reconnect — ignore it.
        _logger.warning(
          '$_id _onMessage: received response for unknown transactionId=$transactionId — ignoring late response',
        );
      }
    } else if (messageJson.containsKey(Event.typeKey)) {
      final eventJson = messageJson;

      try {
        final event = Event.fromJson(eventJson);
        _onEvent(event);
      } on UnknownEventTypeError catch (error) {
        // Core can be newer than the app. An event type the app does not know
        // says nothing about the connection, so it must not fail it. The same
        // type can come often, so it is logged once per client.
        if (_ignoredTypes.add(error.type)) {
          _logger.warning('$_id _onMessage: ignoring unknown event ${error.type}');
        }
      } catch (error, stackTrace) {
        _onError(error, stackTrace);
      }
    } else if (messageJson[Handshake.typeKey] == StateHandshake.typeValue) {
      final stateHandshakeJson = messageJson;

      try {
        final stateHandshake = StateHandshake.fromJson(stateHandshakeJson);
        _stateReceived = true;
        _onStateHandshake(stateHandshake);

        _keepaliveInterval = stateHandshake.keepaliveInterval;
        _startKeepaliveTimer();
      } catch (error, stackTrace) {
        _onError(error, stackTrace);
      }
    } else {
      // A kind of message the app does not know says nothing about the connection.
      final type = '${messageJson[Handshake.typeKey]}';
      if (_ignoredTypes.add(type)) {
        _logger.warning('$_id _onMessage: ignoring unknown message of ${messageJson.keys} ($type)');
      }
    }
  }

  Future<Map<String, dynamic>> _executeTransaction(Map<String, dynamic> requestJson, Duration timeoutDuration) async {
    final isIdGenerate = requestJson['transaction'] == null;
    if (isIdGenerate) {
      requestJson['transaction'] = Transaction.generateId();
    }

    // Sent before the transaction exists, so a failed write starts no timeout.
    // The answer cannot overtake it: the socket stream delivers it asynchronously.
    _addMessage(requestJson);

    final transaction = Transaction(
      signalingClientId: _id,
      id: requestJson['transaction'],
      timeoutDuration: timeoutDuration,
    );
    _transactions[transaction.id] = transaction;

    try {
      final responseJson = await transaction.future;
      if (isIdGenerate) {
        responseJson.remove('transaction');
      }

      return responseJson;
    } catch (e) {
      _transactions.remove(transaction.id);
      rethrow;
    }
  }

  void _addMessage(Map<String, dynamic> messageJson) {
    final data = jsonEncode(messageJson);
    _addData(data);
  }

  void _addData(dynamic data) {
    _logger.fine(() => '$_id _addData add: $data');

    try {
      if (_wsc.closeCode != null) {
        throw StateError('Cannot add event after closing (detected via closeCode)');
      }

      _wsc.sink.add(data);
    } on StateError catch (e) {
      throw SignalingBadStateException(_id, e);
    }
  }

  void _cleanupTransactions(int? code, String? reason) {
    for (final transaction in _transactions.values) {
      transaction.terminateByDisconnect(code, reason);
    }
    _transactions.clear();
  }

  //

  void _startKeepaliveTimer() {
    final interval = _currentKeepaliveInterval;
    _logger.fine('$_id keepalive timer scheduled: $interval');
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer(interval, _onKeepalive);
  }

  void _stopTimers() {
    _receiveWatchdog.stop();
    _keepaliveTimer?.cancel();
  }

  void _restartKeepaliveTimer() {
    _logger.fine('$_id keepalive timer restarted');
    _startKeepaliveTimer();
  }

  void _onQuiet() {
    if (_keepaliveWaiting) return;
    _logger.fine('$_id nothing received in $_currentKeepaliveInterval');
    _keepaliveTimer?.cancel();
    _onKeepalive();
  }

  /// The connection is dead though nothing closed it. It is given up as
  /// [disconnect] gives one up, so the handlers hear nothing more of it, and
  /// the requests waiting on it time out now and not each at its own time.
  void _connectionLost(Object error, StackTrace stackTrace) {
    final wscStreamSubscription = _wscStreamSubscription;
    if (wscStreamSubscription == null) return;
    _wscStreamSubscription = null;
    _stopTimers();
    unawaited(wscStreamSubscription.cancel());
    for (final transaction in _transactions.values) {
      transaction.timeOutNow();
    }
    _transactions.clear();
    unawaited(_wsc.sink.close().catchError((_) {}));
    _onError(error, stackTrace);
  }

  void _onKeepalive() async {
    _logger.fine('$_id keepalive firing');
    _keepaliveWaiting = true;
    try {
      final elapsed = await _executeKeepaliveTransaction(defaultExecuteTransactionTimeoutDuration);
      _logger.finest('$_id handshake keepalive latency: $elapsed');

      // Stop the keepalive loop if the client was disconnected or the socket was closed between
      // send and response; disconnect() leaves closeCode unset until the peer's close frame comes.
      if (_wscStreamSubscription != null && _wsc.closeCode == null) {
        _startKeepaliveTimer();
      } else {
        _receiveWatchdog.stop();
      }
    } on SignalingStateHandshakeMissingException catch (e, stackTrace) {
      _connectionLost(e, stackTrace);
    } on SignalingTransactionTimeoutException catch (e, stackTrace) {
      _connectionLost(SignalingKeepaliveTimeoutException(e.id, e.transactionId), stackTrace);
    } on SignalingBadStateException {
      _logger.fine('$_id keepalive stopped gracefully due to closed socket.');
      // Catches the specific exception thrown when attempting to write to a closed socket.
      // This indicates a race condition where the Keepalive timer triggered shortly after
      // the socket was closed but before the timer could be cancelled.
      //
      // Since the socket is already in a terminal state, the standard disconnection
      // handlers (onDone/onDisconnect) are responsible for the lifecycle management.
      // Reporting this as an error would be redundant and potentially misleading.
      //
      // Gracefully terminate the recursive Keepalive loop here.
      _receiveWatchdog.stop();
      return;
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    } finally {
      _keepaliveWaiting = false;
    }
  }

  Future<Duration> _executeKeepaliveTransaction(Duration timeoutDuration) async {
    final stopwatch = Stopwatch();

    final keepaliveHandshakeRequest = KeepaliveHandshake();
    final requestJson = keepaliveHandshakeRequest.toJson();
    stopwatch.start();
    final responseJson = await _executeTransaction(requestJson, timeoutDuration);
    stopwatch.stop();
    // ignore: unused_local_variable
    final keepaliveHandshakeResponse = KeepaliveHandshake.fromJson(responseJson);

    // An answer proves the connection works only after the state, which the
    // server sends first: before it, frames were lost and nothing would
    // renegotiate the calls on this connection.
    if (!_stateReceived) {
      throw SignalingStateHandshakeMissingException(_id, requestJson['transaction']);
    }

    return stopwatch.elapsed;
  }
}
