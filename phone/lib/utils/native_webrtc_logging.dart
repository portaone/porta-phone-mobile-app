import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart' as native;
import 'package:logging/logging.dart';

import 'package:webtrit_phone/environment_config.dart';

final _logger = Logger('WebRTC.Native');

/// Severity levels the native side understands, lowest first.
///
/// A threshold, not a selection. `warning` delivers warnings AND errors, but
/// measured against this library that is codec and socket housekeeping only:
/// nothing about ICE or TURN is written above `info`, so `info` is the lowest
/// level at which a gathering failure leaves any trace. `verbose` adds the
/// per-candidate trace on top.
const _severities = ['none', 'error', 'warning', 'info', 'verbose'];

/// How a native line is recorded, per configured threshold.
///
/// At `warning` and `error` every line the native side sends IS one, so it is
/// recorded as such. `info` and `verbose` are a trace - voluminous, and read
/// when something is being investigated - so they go at [FINER], where they do
/// not crowd out the application's own records, and the logger's level is
/// raised to let them through: an operator who asked for an ICE trace should
/// not discover that a separate setting swallowed it.
Level _recordLevelFor(String severity) => switch (severity) {
  'error' || 'warning' => Level.WARNING,
  _ => Level.FINER,
};

/// Routes libwebrtc's own log into the application log.
///
/// Everything below the plugin is otherwise invisible. The Dart side reports a
/// peer connection's state, not what the native ICE stack did to reach it, so a
/// failure inside gathering - a TURN server that never answers, a TLS handshake
/// the library refuses - surfaces as candidates that simply never arrive, with
/// nothing logged anywhere to say why.
///
/// Records arrive on the `WebRTC.Native` logger and go through the same pipeline
/// as everything else: the on-device log file, and the remote sink when one is
/// configured. That is the point of bridging rather than printing - a native
/// failure becomes something a support log can be searched for afterwards.
///
/// Two ordering constraints, both of which make a misplaced call silently do
/// nothing:
///
/// - AFTER the application logger is built, because this raises the level of its
///   own logger, and a per-logger level needs `hierarchicalLoggingEnabled`;
/// - BEFORE the first [WebRTC.initialize], because the native factory reads the
///   severity once when it is created, and the Android channel that would change
///   it afterwards is a documented no-op.
///
/// Between `bootstrap` and `runApp` satisfies both: the first peer connection is
/// created with a call, long after the tree is up.
void initializeNativeWebrtcLogging() {
  // There is no native stack on web - WebRTC there is the browser's, and it exposes
  // no such sink. The plugin's sink is reached over a method channel that web
  // registers no handler for, so asking would throw on a path that runs before
  // `runApp` and take the whole startup with it.
  if (kIsWeb) return;

  final severity = EnvironmentConfig.WEBRTC_NATIVE_LOG_SEVERITY.trim().toLowerCase();

  if (severity == 'none' || severity.isEmpty) return;

  if (!_severities.contains(severity)) {
    _logger.warning(
      'Unknown ${EnvironmentConfig.WEBRTC_NATIVE_LOG_SEVERITY__NAME} "$severity", '
      'expected one of ${_severities.join(', ')}; native logging stays off',
    );
    return;
  }

  final recordLevel = _recordLevelFor(severity);
  if (recordLevel < Level.INFO) _logger.level = Level.ALL;

  Helper.setLogger(
    native.Logger(printer: _PassThroughPrinter(), output: _LoggingOutput(recordLevel), level: native.Level.all),
    severity,
  );

  _logger.info('Native WebRTC logging enabled at "$severity"');
}

/// Hands the line over unchanged.
///
/// The package's default printer draws a box around every record and wraps long
/// ones, which turns a grep over an ICE trace into an exercise in reassembly.
/// The native line already carries its own structure.
class _PassThroughPrinter extends native.LogPrinter {
  @override
  List<String> log(native.LogEvent event) => ['${event.message}'];
}

/// Forwards into `package:logging` instead of the console, at the level
/// [_recordLevelFor] chose for the configured threshold.
class _LoggingOutput extends native.LogOutput {
  _LoggingOutput(this.level);

  final Level level;

  @override
  void output(native.OutputEvent event) {
    for (final line in event.lines) {
      _logger.log(level, line);
    }
  }
}
