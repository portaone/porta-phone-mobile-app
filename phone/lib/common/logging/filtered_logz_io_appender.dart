import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:logging_appenders/base_remote_appender.dart';
import 'package:logging_appenders/logging_appenders.dart';

import 'anonymizing_formatter.dart';

// DO NOT USE Logger inside FilteredLogzIoAppender
// to avoid logging cycles. Use debugPrint instead.
class FilteredLogzIoAppender extends LogzIoApiAppender {
  FilteredLogzIoAppender({
    required LogRecordFormatter super.formatter,
    required super.url,
    required super.apiToken,
    required this.minLevel,
    super.bufferSize,
    super.labels = const {},
  });

  final Level minLevel;

  /// Tracks the connection state to avoid spamming "connection lost" messages.
  bool _isConnectionLost = false;

  /// Set by [discard]: records still waiting for their batch are dropped, not sent.
  bool _isDiscarded = false;

  /// Releases the appender without sending the records it still holds.
  ///
  /// [dispose] sends them first; when remote logging is switched off or
  /// expires, nothing more may leave the device, those records included.
  Future<void> discard() {
    _isDiscarded = true;
    return dispose();
  }

  @override
  Future<void> sendLogEventsWithHttp(
    List<LogEntry> entries,
    Map<String, String> userProperties,
    Future<void> cancelToken,
  ) async {
    if (_isDiscarded) return;
    try {
      await super.sendLogEventsWithHttp(entries, userProperties, cancelToken);

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
