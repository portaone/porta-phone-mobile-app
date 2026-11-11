import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

enum AnonymizationType { none, full }

/// Masks personal data in the text a record is formatted to.
///
/// The whole output of the wrapped formatter is masked - the message, the
/// error, the stack trace and any cause - because an exception text carries
/// the same addresses, numbers and URIs as a message does.
///
/// The text carries no colour codes: they are of no use off the device, and
/// an escape sequence such as `ESC[35m` ends in a word character, so a rule
/// anchored at a word boundary would miss a number or an address that opens
/// the message.
class AnonymizingFormatter extends LogRecordFormatter {
  AnonymizingFormatter({
    this.wrappedFormatter = const DefaultLogRecordFormatter(),
    this.anonymizationType = AnonymizationType.none,
  });

  final LogRecordFormatter wrappedFormatter;

  AnonymizationType anonymizationType;

  @override
  StringBuffer formatToStringBuffer(LogRecord rec, StringBuffer sb) {
    if (anonymizationType == AnonymizationType.none) return wrappedFormatter.formatToStringBuffer(rec, sb);

    final formatted = wrappedFormatter.formatToStringBuffer(rec, StringBuffer()).toString();
    return sb..write(sanitize(formatted));
  }

  // The SIP URI rule runs before the e-mail one: `sip:1234@example.com` would
  // otherwise be taken for an address and lose its host, which is not personal
  // and is what a reader of the log needs.
  static final _rules = <(RegExp, String Function(Match))>[
    (RegExp(r'\b(sips?):[^@\s;>"<,]+@', caseSensitive: false), (Match m) => '${m[1]}:[REDACTED]@'),
    (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'), (Match _) => '[REDACTED_EMAIL]'),
    (RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b'), (Match _) => '[REDACTED_IPADDRESS]'),
    (RegExp(r'\bport\s*=\s*\d+\b'), (Match _) => '[REDACTED_PORT]'),
    (RegExp(r'\b\d{10,15}\b'), (Match _) => '[REDACTED_PHONENUMBER]'),
    (RegExp(r'eyJ[a-zA-Z0-9._-]+'), (Match _) => '[REDACTED_TOKEN]'),
    (RegExp(r'"(first_name|last_name|alias_name|company_name)":"[^"]+"'), (Match _) => '[REDACTED_PERSONALINFO]'),
    (RegExp(r'"identifier":"[^"]+"'), (Match _) => '[REDACTED_IDENTIFIER]'),
    (RegExp(r'"user_id":"[^"]+"'), (Match _) => '[REDACTED_USERID]'),
    (RegExp(r'"tenant_id":"[^"]+"'), (Match _) => '[REDACTED_TENANTID]'),
    (RegExp(r'"balance":\{[^}]+\}'), (Match _) => '[REDACTED_BALANCE]'),
    (RegExp(r'"bundle_id":"[^"]+"'), (Match _) => '[REDACTED_BUNDLEID]'),
    (RegExp(r'"config_token":"[^"]+"'), (Match _) => '[REDACTED_CONFIGTOKEN]'),
    (RegExp(r'"pending_login_token":"[^"]+"'), (Match _) => '[REDACTED_PENDINGLOGINTOKEN]'),
    (RegExp(r'"login":"[^"]+"'), (Match _) => '[REDACTED_LOGIN]'),
    (RegExp(r'"password":"[^"]+"'), (Match _) => '[REDACTED_PASSWORD]'),
    (RegExp(r'"otp_id":"[^"]+"'), (Match _) => '[REDACTED_OTPID]'),
    (RegExp(r'"user_ref":"[^"]+"'), (Match _) => '[REDACTED_USERREF]'),
    (RegExp(r'"code":"[^"]+"'), (Match _) => '[REDACTED_CODE]'),
  ];

  /// [input] with personal data masked, or as it is when [anonymizationType]
  /// is [AnonymizationType.none].
  String sanitize(String input) {
    if (anonymizationType == AnonymizationType.none) return input;

    var sanitized = input;
    for (final (pattern, replace) in _rules) {
      sanitized = sanitized.replaceAllMapped(pattern, replace);
    }
    return sanitized;
  }
}
