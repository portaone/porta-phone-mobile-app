import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/base_remote_appender.dart';

import 'package:webtrit_phone/common/logging/anonymizing_formatter.dart';
import 'package:webtrit_phone/common/logging/logging.dart';

class _CapturingAppender extends FilteredLogzIoAppender {
  _CapturingAppender(AnonymizingFormatter formatter)
    : super(formatter: formatter, url: 'https://core.example.com/mobile-logs', minLevel: Level.ALL);

  final capturedLabels = <Map<String, String>>[];

  @override
  Future<void> log(Level logLevel, DateTime time, String line, Map<String, String> lineLabels) async {
    capturedLabels.add(lineLabels);
  }

  @override
  Future<void> sendLogEventsWithHttp(
    List<LogEntry> entries,
    Map<String, String> userProperties,
    Future<void> cancelToken,
  ) async {}
}

void main() {
  AnonymizingFormatter full() =>
      AnonymizingFormatter(anonymizationType: AnonymizationType.full, wrappedFormatter: const RemoteFormatter());

  String format(AnonymizingFormatter formatter, LogRecord record) =>
      formatter.formatToStringBuffer(record, StringBuffer()).toString();

  group('SIP URIs', () {
    test('lose their user part and keep the host', () {
      final f = full();

      expect(f.sanitize('INVITE sip:1234@pbx.example.com SIP/2.0'), 'INVITE sip:[REDACTED]@pbx.example.com SIP/2.0');
      expect(f.sanitize('<sips:alice.smith@example.org;transport=tls>'), '<sips:[REDACTED]@example.org;transport=tls>');
      expect(f.sanitize('From: "Bob" <SIP:+380441234567@sbc.example.com>'), contains('SIP:[REDACTED]@sbc.example.com'));
    });

    test('without a user part stay as they are', () {
      expect(full().sanitize('Route: <sip:proxy.example.com;lr>'), 'Route: <sip:proxy.example.com;lr>');
    });
  });

  // Coloured output once hid these: the escape before a WARNING, SEVERE or
  // FINE message ends in a word character, and the rules anchored at a word
  // boundary did not see a number or an address that opens the message.
  group('personal data that opens the message', () {
    for (final level in [Level.FINE, Level.WARNING, Level.SEVERE, Level.SHOUT]) {
      test('is masked at $level', () {
        final f = full();

        expect(format(f, LogRecord(level, '380501234567 dialed', 'test')), '[REDACTED_PHONENUMBER] dialed');
        expect(format(f, LogRecord(level, '10.0.0.1 unreachable', 'test')), '[REDACTED_IPADDRESS] unreachable');
        expect(format(f, LogRecord(level, 'port=5060 closed', 'test')), '[REDACTED_PORT] closed');
        expect(format(f, LogRecord(level, 'sip:alice@example.com rang', 'test')), 'sip:[REDACTED]@example.com rang');
      });
    }

    test('carries no colour codes', () {
      expect(format(full(), LogRecord(Level.SEVERE, 'boom', 'test')), isNot(contains('\x1B')));
    });
  });

  group('a record', () {
    test('has its error text masked', () {
      final record = LogRecord(
        Level.SEVERE,
        'call failed',
        'test',
        Exception('cannot reach sip:5551234@pbx.example.com from 192.168.1.10, mail bob@example.com'),
      );

      final text = format(full(), record);

      expect(text, contains('call failed'));
      expect(text, contains('sip:[REDACTED]@pbx.example.com'));
      expect(text, contains('[REDACTED_IPADDRESS]'));
      expect(text, contains('[REDACTED_EMAIL]'));
      expect(text, isNot(contains('5551234')));
      expect(text, isNot(contains('192.168.1.10')));
      expect(text, isNot(contains('bob@example.com')));
    });

    test('has its stack trace masked', () {
      final record = LogRecord(
        Level.SEVERE,
        'boom',
        'test',
        StateError('x'),
        StackTrace.fromString('#0 handle (package:app/a.dart:1) user 380441234567'),
      );

      final text = format(full(), record);

      expect(text, contains('[REDACTED_PHONENUMBER]'));
      expect(text, isNot(contains('380441234567')));
    });

    test('is left untouched without anonymization', () {
      final formatter = AnonymizingFormatter(wrappedFormatter: const RemoteFormatter());
      final record = LogRecord(Level.INFO, 'to sip:1234@pbx.example.com', 'test', Exception('bob@example.com'));

      final text = format(formatter, record);

      expect(text, contains('sip:1234@pbx.example.com'));
      expect(text, contains('bob@example.com'));
    });
  });

  test('the error label sent beside the message is masked too', () {
    final appender = _CapturingAppender(full());

    appender.handle(LogRecord(Level.SEVERE, 'failed', 'test', Exception('user bob@example.com at 10.1.2.3')));

    final label = appender.capturedLabels.single['e']!;
    expect(label, isNot(contains('bob@example.com')));
    expect(label, isNot(contains('10.1.2.3')));
    expect(appender.capturedLabels.single['eType'], '_Exception');
  });
}
