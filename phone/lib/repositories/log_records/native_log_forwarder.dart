import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/disposable.dart';
import 'package:webtrit_phone/common/process_role.dart';

/// The [ProcessRole] name held by the one forwarder in the process that forwards.
///
/// Every isolate of the process (the UI one, the FCM background handler, the push
/// isolate) builds its own [NativeLogForwarder] over the same file. Without a single
/// owner each of them would forward every native line, once per live isolate.
const kNativeLogForwarderRoleName = 'webtrit_native_log_forwarder';

class NativeLogForwarder implements Disposable {
  /// A forwarder for a background isolate (FCM handler, push isolate).
  ///
  /// It forwards only while no live forwarder in the process holds the role, and
  /// stands by otherwise.
  NativeLogForwarder({
    required String nativeLogFilePath,
    required Logger logger,
    ProcessRole? role,
    Level Function(String line)? levelParser,
  }) : this._(nativeLogFilePath, logger, role, levelParser, takeOver: false);

  /// The forwarder of the UI isolate, which takes the forwarding over on [start].
  ///
  /// The UI isolate is the only one with the file log, so its copy is the one that
  /// reaches every appender; a background forwarder that got there first stands by.
  NativeLogForwarder.inUiIsolate({
    required String nativeLogFilePath,
    required Logger logger,
    ProcessRole? role,
    Level Function(String line)? levelParser,
  }) : this._(nativeLogFilePath, logger, role, levelParser, takeOver: true);

  NativeLogForwarder._(
    String nativeLogFilePath,
    Logger logger,
    ProcessRole? role,
    Level Function(String line)? levelParser, {
    required bool takeOver,
    // dart:io File is unavailable on web; this forwarder is only start()ed on
    // Android, so the file stays null and unused elsewhere.
  }) : _file = kIsWeb ? null : File(nativeLogFilePath),
       _logger = logger,
       _role = role ?? ProcessRole(kNativeLogForwarderRoleName),
       _takeOver = takeOver,
       _levelParser = levelParser ?? _callkeepLevelParser;

  final File? _file;
  final Logger _logger;
  final ProcessRole _role;
  final bool _takeOver;
  final Level Function(String line) _levelParser;
  int _readOffset = 0;
  String _remainder = '';
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  Future<void>? _pendingForward;

  void start() {
    final file = _file;
    if (file == null) return; // never started on web
    _watchSubscription?.cancel();
    _readOffset = file.existsSync() ? file.lengthSync() : 0;
    _remainder = '';
    if (_takeOver) {
      _role.takeOver();
    } else {
      _role.claimIfFree();
    }
    final absolutePath = file.absolute.path;
    _watchSubscription = file.parent
        .watch()
        .where((e) => File(e.path).absolute.path == absolutePath)
        .listen(_onFileEvent);
  }

  void _onFileEvent(FileSystemEvent event) {
    if (event.type == FileSystemEvent.delete) {
      _readOffset = 0;
      _remainder = '';
      return;
    }
    _pendingForward = (_pendingForward ?? Future.value()).then((_) => _forwardNewBytes());
  }

  Future<void> _forwardNewBytes() async {
    final file = _file;
    if (file == null) return; // never reached on web (watch is not started)
    if (!file.existsSync()) {
      _readOffset = 0;
      _remainder = '';
      return;
    }
    if (!await _role.holdOrReclaim()) {
      // Another isolate forwards these lines; keep up so a later claim starts from here.
      _readOffset = file.lengthSync();
      _remainder = '';
      return;
    }
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final length = await raf.length();
      if (length < _readOffset) {
        // file was rotated or truncated
        _readOffset = 0;
        _remainder = '';
      }
      if (length == _readOffset) return;
      await raf.setPosition(_readOffset);
      final bytes = await raf.read(length - _readOffset);
      _readOffset = length;
      final chunk = _remainder + utf8.decode(bytes, allowMalformed: true);
      final lines = chunk.split('\n');
      // last element is empty on a complete write, or a partial line — buffer it
      _remainder = lines.removeLast();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        _logger.log(_levelParser(trimmed), trimmed);
      }
    } catch (e, st) {
      _logger.warning('NativeLogForwarder: failed to read ${file.path}', e, st);
    } finally {
      await raf?.close();
    }
  }

  @override
  Future<void> dispose() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
    await _pendingForward;
    _pendingForward = null;
    await _role.release();
  }
}

// Default parser for the format written by webtrit_callkeep's Kotlin Log.kt:
// "yyyy-MM-dd HH:mm:ss.SSS <level> <tag>: <message>"
// parts[2] is the single-character level: D=FINE, I=INFO, W=WARNING, E=SEVERE, V=FINEST.
Level _callkeepLevelParser(String line) {
  final parts = line.split(' ');
  if (parts.length < 3) return Level.INFO;
  return switch (parts[2]) {
    'D' => Level.FINE,
    'I' => Level.INFO,
    'W' => Level.WARNING,
    'E' => Level.SEVERE,
    'V' => Level.FINEST,
    _ => Level.INFO,
  };
}
