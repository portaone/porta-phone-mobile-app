import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:logging_appenders/base_remote_appender.dart';
import 'package:logging_appenders/logging_appenders.dart';

import 'anonymizing_formatter.dart';

/// Posts log records, in batches, to the log receiver of WebTrit Core.
///
/// The body is the newline-delimited JSON of [LogzIoApiAppender], which the
/// receiver accepts as it is. Batching is done here rather than by the base
/// class: the base sends one request per record when its buffer size is 0 and
/// then keeps posting empty bodies, and its `dispose` closes the HTTP client
/// before the last batch is sent, which loses that batch.
///
/// DO NOT USE Logger inside this class, to avoid logging cycles; use
/// debugPrint instead.
class FilteredLogzIoAppender extends LogzIoApiAppender {
  FilteredLogzIoAppender({
    required LogRecordFormatter super.formatter,
    required super.url,
    required this.minLevel,
    this.batchSize = defaultBatchSize,
    this.batchDelay = defaultBatchDelay,
    super.labels = const {},
    http.Client? httpClient,
  }) : _httpClient = httpClient,
       // The receiver takes no credential from the app. A token in the query
       // would also end up in the request line the receiver logs.
       super(apiToken: '');

  /// Records sent in one request at most.
  static const defaultBatchSize = 100;

  /// How long the first record of a batch waits for the batch to fill up.
  static const defaultBatchDelay = Duration(seconds: 10);

  final Level minLevel;

  final int batchSize;

  final Duration batchDelay;

  final http.Client? _httpClient;

  late final http.Client _client = _httpClient ?? http.Client();

  @override
  http.Client get client => _client;

  List<LogEntry> _batch = [];
  Timer? _batchTimer;

  /// The sends started so far, one after the other, so that batches arrive in
  /// order and [dispose] can wait for the last of them.
  Future<void> _sending = Future.value();

  /// Tracks the connection state to avoid spamming "connection lost" messages.
  bool _isConnectionLost = false;

  /// Set by [discard]: records still waiting for their batch are dropped, not sent.
  bool _isDiscarded = false;

  bool _isDisposed = false;

  /// Releases the appender without sending the records it still holds.
  ///
  /// [dispose] sends them first; when remote logging is switched off or
  /// expires, nothing more may leave the device, those records included.
  Future<void> discard() {
    _isDiscarded = true;
    _batch = [];
    return dispose();
  }

  @override
  Future<void> log(Level logLevel, DateTime time, String line, Map<String, String> lineLabels) {
    if (_isDisposed) return Future.value();
    _batch.add(LogEntry(logLevel: logLevel, ts: time, line: line, lineLabels: lineLabels));
    if (_batch.length >= batchSize) {
      _sendBatch();
    } else {
      _batchTimer ??= Timer(batchDelay, _sendBatch);
    }
    return Future.value();
  }

  void _sendBatch() {
    _batchTimer?.cancel();
    _batchTimer = null;
    if (_batch.isEmpty) return;
    final entries = _batch;
    _batch = [];
    _sending = _sending.then((_) => sendLogEventsWithHttp(entries, const {}, Completer<void>().future));
  }

  /// Sends what is batched now and completes when every send started so far is done.
  @override
  Future<void> flush() {
    _sendBatch();
    return _sending;
  }

  /// Sends what is still batched, waits for it, and only then closes the client.
  @override
  Future<void> dispose() async {
    if (_isDisposed) return _sending;
    if (!_isDiscarded) _sendBatch();
    _isDisposed = true;
    _batchTimer?.cancel();
    _batchTimer = null;
    await _sending;
    // Closes the client; the base flush that follows finds nothing to send.
    await super.dispose();
  }

  @override
  Future<void> sendLogEventsWithHttp(
    List<LogEntry> entries,
    Map<String, String> userProperties,
    Future<void> cancelToken,
  ) async {
    if (_isDiscarded || entries.isEmpty) return;
    try {
      await sendRequest(_buildRequest(entries, userProperties));

      if (_isConnectionLost) {
        _isConnectionLost = false;
        debugPrint('FilteredLogzIoAppender: Connection restored. Resuming remote logging.');
      }
    } on http.ClientException catch (e) {
      _markConnectionLostOnce('ClientException: $e');
    } on SocketException catch (e) {
      _markConnectionLostOnce('SocketException: $e');
    } on TimeoutException catch (e) {
      _markConnectionLostOnce('TimeoutException: $e');
    } catch (e, stackTrace) {
      debugPrint('FilteredLogzIoAppender: Unhandled Exception: $e\n$stackTrace');
    }
  }

  http.Request _buildRequest(List<LogEntry> entries, Map<String, String> userProperties) {
    final body = entries
        .map(
          (entry) => json.encode({
            '@timestamp': entry.ts.toUtc().toIso8601String(),
            'message': entry.line,
            'user': userProperties,
            ...labels,
            ...entry.lineLabels,
          }),
        )
        .join('\n');
    final uri = Uri.parse(url).replace(queryParameters: {'type': type});
    return http.Request('POST', uri)
      ..body = body
      ..headers[HttpHeaders.contentTypeHeader] = ContentType(
        ContentType.json.primaryType,
        ContentType.json.subType,
      ).value;
  }

  void _markConnectionLostOnce(String details) {
    if (_isConnectionLost) return;
    _isConnectionLost = true;
    debugPrint('FilteredLogzIoAppender: Connection lost. Pausing remote logging. Will retry silently. $details');
  }

  @override
  void handle(LogRecord record) {
    if (!RemoteLogFilter.shouldLog(record, url, minLevel: minLevel)) return;

    // The same entry the base appender builds, but the error text that goes
    // into the `e` label is masked as the message is: the base appender
    // writes `error.toString()` there as it is.
    final message = formatter.format(record);
    final lineLabels = {'lvl': record.level.name, 'logger': record.loggerName};
    final error = record.error;
    if (error != null) {
      lineLabels['e'] = _sanitize(error.toString());
      lineLabels['eType'] = error.runtimeType.toString();
    }
    log(record.level, record.time, message, lineLabels);
  }

  String _sanitize(String text) {
    final formatter = this.formatter;
    return formatter is AnonymizingFormatter ? formatter.sanitize(text) : text;
  }
}

class RemoteLogFilter {
  static bool shouldLog(LogRecord record, String url, {Level? minLevel}) {
    if (minLevel != null && record.level < minLevel) {
      return false;
    }

    final error = record.error;
    if (error is http.ClientException) {
      return !_isErrorForLoggerHost(error, url);
    }
    return true;
  }

  /// Skip records whose error is a network failure to the logger's own host —
  /// avoids logging cycles when the logger itself is unreachable.
  static bool _isErrorForLoggerHost(http.ClientException error, String url) {
    final loggerHost = Uri.tryParse(url)?.host;
    if (loggerHost == null) {
      return false;
    }
    return error.uri?.host == loggerHost;
  }
}
