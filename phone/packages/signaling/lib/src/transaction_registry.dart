import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'exceptions.dart';
import 'handshakes/handshakes.dart';
import 'responses/responses.dart';
import 'transaction.dart';

/// The request and answer half of a WebTrit socket: writes a request, keeps a
/// [Transaction] for it, and hands the answer that names it back to whoever
/// waits.
///
/// Both the signalling socket and the conference guest socket answer a
/// request with `ack` or `error` and echo a keepalive with its transaction,
/// so both clients route those through here and keep only what is theirs:
/// what the events mean, the state handshake, when to ask for a keepalive.
class TransactionRegistry {
  TransactionRegistry(this._wsc, {required this.clientId, required Logger logger}) : _logger = logger;

  final WebSocketChannel _wsc;
  final Logger _logger;

  /// The id of the client this registry belongs to, in exceptions and logs.
  final int clientId;

  final _transactions = <String, Transaction>{};

  /// Whether the peer's close frame has come.
  bool get isClosed => _wsc.closeCode != null;

  /// Writes [requestJson] and waits for the answer that names its transaction.
  ///
  /// A request without a transaction is given one, and the answer is handed
  /// back without it. The request is written before its [Transaction] exists:
  /// a write that fails throws to the caller and leaves no timeout behind. The
  /// answer cannot overtake it, since the socket stream delivers it
  /// asynchronously.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> requestJson, Duration timeoutDuration) async {
    final isIdGenerate = requestJson['transaction'] == null;
    if (isIdGenerate) {
      requestJson['transaction'] = Transaction.generateId();
    }

    send(requestJson);

    final transaction = Transaction(
      signalingClientId: clientId,
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

  /// Writes [messageJson] as it is; throws [SignalingBadStateException] on a
  /// closed socket.
  void send(Map<String, dynamic> messageJson) {
    final data = jsonEncode(messageJson);
    _logger.fine(() => '$clientId _addData add: $data');

    try {
      if (_wsc.closeCode != null) {
        throw StateError('Cannot add event after closing (detected via closeCode)');
      }

      _wsc.sink.add(data);
    } on StateError catch (e) {
      throw SignalingBadStateException(clientId, e);
    }
  }

  /// Whether [messageJson] is an answer: a response, or a keepalive echo.
  static bool isAnswer(Map<String, dynamic> messageJson) =>
      messageJson.containsKey(Response.typeKey) || messageJson[Handshake.typeKey] == KeepaliveHandshake.typeValue;

  /// Hands an answer to the transaction it names.
  ///
  /// An answer for a transaction already gone - one that timed out under
  /// network congestion and was removed - is logged and ignored: taking it for
  /// a connection error would make a needless reconnect.
  void handleAnswer(Map<String, dynamic> messageJson) {
    final transactionId = messageJson['transaction'];
    final transaction = _transactions.remove(transactionId);

    if (transaction != null) {
      transaction.handleResponse(messageJson);
    } else {
      _logger.warning(
        '$clientId _onMessage: received response for unknown transactionId=$transactionId — ignoring late response',
      );
    }
  }

  /// Ends every transaction still waiting because the socket closed.
  void terminateAll(int? code, String? reason) {
    for (final transaction in _transactions.values) {
      transaction.terminateByDisconnect(code, reason);
    }
    _transactions.clear();
  }

  /// Ends every transaction still waiting as its timeout would: the
  /// connection was found dead before their own timeouts.
  void timeOutAll() {
    for (final transaction in _transactions.values) {
      transaction.timeOutNow();
    }
    _transactions.clear();
  }
}
