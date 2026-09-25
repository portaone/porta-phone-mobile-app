import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/disposable.dart';

/// The [IsolateNameServer] key held by the one forwarder in the process that forwards.
///
/// Every isolate of the process (the UI one, the FCM background handler, the push
/// isolate) builds its own [NativeLogForwarder] over the same file. Without a single
/// owner each of them would forward every native line, once per live isolate.
const kNativeLogForwarderPortName = 'webtrit_native_log_forwarder';

final _ownershipLogger = Logger('NativeLogForwarder');

// Sent to the current owner when another forwarder takes the forwarding over.
const _yieldMessage = 'yield';

class NativeLogForwarder implements Disposable {
  NativeLogForwarder({
    required String nativeLogFilePath,
    required Logger logger,
    this.takeOver = false,
    String portName = kNativeLogForwarderPortName,
    Duration probeTimeout = const Duration(milliseconds: 500),
    Level Function(String line)? levelParser,
    // dart:io File is unavailable on web; this forwarder is only start()ed on
    // Android, so the file stays null and unused elsewhere.
  }) : _file = kIsWeb ? null : File(nativeLogFilePath),
       _logger = logger,
       _portName = portName,
       _probeTimeout = probeTimeout,
       _levelParser = levelParser ?? _callkeepLevelParser;

  /// Whether [start] takes the forwarding over from whichever forwarder holds it.
  ///
  /// The UI isolate passes true: it owns the file log, so its copy is the one that
  /// must reach every appender. Background isolates leave it false and forward only
  /// while no live forwarder holds [kNativeLogForwarderPortName].
  final bool takeOver;

  final File? _file;
  final Logger _logger;
  final String _portName;
  final Duration _probeTimeout;
  final Level Function(String line) _levelParser;
  int _readOffset = 0;
  String _remainder = '';
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  Future<void>? _pendingForward;

  // Non-null while this forwarder holds the name, i.e. while it forwards.
  ReceivePort? _ownerPort;
  Future<bool>? _pendingClaim;

  void start() {
    final file = _file;
    if (file == null) return; // never started on web
    _watchSubscription?.cancel();
    _readOffset = file.existsSync() ? file.lengthSync() : 0;
    _remainder = '';
    if (takeOver) {
      _takeOver();
    } else if (_ownerPort == null && _register()) {
      _ownershipLogger.info('${Isolate.current.debugName}: forwarding (name was free)');
    }
    final absolutePath = file.absolute.path;
    _watchSubscription = file.parent
        .watch()
        .where((e) => File(e.path).absolute.path == absolutePath)
        .listen(_onFileEvent);
  }

  void _takeOver() {
    final holder = IsolateNameServer.lookupPortByName(_portName);
    if (holder != null && holder == _ownerPort?.sendPort) return;
    holder?.send(_yieldMessage);
    IsolateNameServer.removePortNameMapping(_portName);
    if (_register()) {
      _ownershipLogger.info('${Isolate.current.debugName}: took forwarding over (had holder: ${holder != null})');
    }
  }

  bool _register() {
    final port = ReceivePort();
    if (!IsolateNameServer.registerPortWithName(port.sendPort, _portName)) {
      port.close();
      return false;
    }
    port.listen(_onOwnerMessage);
    _ownerPort = port;
    return true;
  }

  void _onOwnerMessage(Object? message) {
    if (message is SendPort) {
      message.send(true); // liveness probe from a standby forwarder
    } else if (message == _yieldMessage) {
      _ownershipLogger.info('${Isolate.current.debugName}: forwarding taken over, standing by');
      _release(unregister: false);
    }
  }

  void _release({required bool unregister}) {
    final port = _ownerPort;
    if (port == null) return;
    _ownerPort = null;
    if (unregister && IsolateNameServer.lookupPortByName(_portName) == port.sendPort) {
      IsolateNameServer.removePortNameMapping(_portName);
    }
    port.close();
  }

  Future<bool> _ensureOwner() {
    if (_ownerPort != null) return Future.value(true);
    return _pendingClaim ??= _claimIfHolderGone().whenComplete(() => _pendingClaim = null);
  }

  // A holder that died without dispose (its engine destroyed) leaves its mapping behind;
  // a probe that goes unanswered frees the name for this forwarder.
  Future<bool> _claimIfHolderGone() async {
    final holder = IsolateNameServer.lookupPortByName(_portName);
    if (holder != null) {
      if (await _answers(holder)) return false;
      if (IsolateNameServer.lookupPortByName(_portName) != holder) return false;
      // In case it is only slow rather than gone, tell it to stop.
      holder.send(_yieldMessage);
      IsolateNameServer.removePortNameMapping(_portName);
    }
    final claimed = _register();
    if (claimed) {
      _ownershipLogger.info('${Isolate.current.debugName}: forwarding (holder gone: ${holder != null})');
    }
    return claimed;
  }

  Future<bool> _answers(SendPort holder) async {
    final reply = ReceivePort();
    try {
      holder.send(reply.sendPort);
      await reply.first.timeout(_probeTimeout);
      return true;
    } on TimeoutException {
      return false;
    } finally {
      reply.close();
    }
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
    if (!await _ensureOwner()) {
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
    await _pendingClaim;
    _release(unregister: true);
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
