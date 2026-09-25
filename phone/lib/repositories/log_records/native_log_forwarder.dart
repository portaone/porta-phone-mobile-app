import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/disposable.dart';

/// The [ProcessRole] name held by the one forwarder in the process that forwards.
///
/// Every isolate of the process (the UI one, the FCM background handler, the push
/// isolate) builds its own [NativeLogForwarder] over the same file. Without a single
/// owner each of them would forward every native line, once per live isolate.
const _roleName = 'webtrit_native_log_forwarder';

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
  }) : this._(nativeLogFilePath, logger, role, levelParser, inUiIsolate: false);

  /// The forwarder of the UI isolate, which takes the forwarding over on [start].
  ///
  /// The UI isolate is the only one with the file log, so its copy is the one that
  /// reaches every appender; a background forwarder that got there first stands by.
  NativeLogForwarder.inUiIsolate({
    required String nativeLogFilePath,
    required Logger logger,
    ProcessRole? role,
    Level Function(String line)? levelParser,
  }) : this._(nativeLogFilePath, logger, role, levelParser, inUiIsolate: true);

  NativeLogForwarder._(
    String nativeLogFilePath,
    Logger logger,
    ProcessRole? role,
    Level Function(String line)? levelParser, {
    required bool inUiIsolate,
    // dart:io File is unavailable on web; this forwarder is only start()ed on
    // Android, so the file stays null and unused elsewhere.
  }) : _file = kIsWeb ? null : File(nativeLogFilePath),
       _logger = logger,
       _role = role ?? ProcessRole(_roleName),
       _inUiIsolate = inUiIsolate,
       _levelParser = levelParser ?? _callkeepLevelParser;

  final File? _file;
  final Logger _logger;
  final ProcessRole _role;
  final bool _inUiIsolate;
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
    if (_inUiIsolate) _role.forceAcquire();
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
    _pendingForward = (_pendingForward ?? Future.value()).then((_) => _forwardAppendedLines());
  }

  Future<void> _forwardAppendedLines() async {
    final file = _file;
    if (file == null) return; // never reached on web (watch is not started)
    if (!file.existsSync()) {
      _readOffset = 0;
      _remainder = '';
      return;
    }
    // A background forwarder may have taken the role while this isolate was busy
    // past the probe timeout; the UI isolate takes it back rather than stand by.
    if (_inUiIsolate && !_role.isHeld) _role.forceAcquire();
    if (!await _role.tryAcquire()) {
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

final _roleLogger = Logger('ProcessRole');

/// A role that at most one isolate of the process holds at a time.
///
/// The app runs several isolates in one process - the UI one, the FCM background
/// handler, the push isolate - and each builds its own dependencies. When a job must
/// run once per process rather than once per isolate, every candidate creates a
/// [ProcessRole] under the same [name] and does the job only while it holds the role.
///
/// The holder is whoever the process-wide [IsolateNameServer] records under [name] -
/// that mapping is the only truth. The name server has no compare-and-set, so a
/// candidate never trusts its own memory: one whose port is no longer recorded has
/// lost the role, whoever replaced it and however. The holder answers liveness
/// probes, so a holder that died without [release] (its engine destroyed) loses the
/// role to the next [tryAcquire].
///
/// Native only: the web name server throws.
class ProcessRole {
  ProcessRole(this.name, {Duration probeTimeout = const Duration(milliseconds: 500)}) : _probeTimeout = probeTimeout;

  /// The [IsolateNameServer] key shared by every candidate for this role.
  final String name;

  final Duration _probeTimeout;

  // The port this isolate registered last; [isHeld] says whether it is still recorded.
  ReceivePort? _port;
  Future<bool>? _pendingAcquire;

  /// Whether the name server currently records this isolate as the holder.
  bool get isHeld {
    final port = _port;
    return port != null && IsolateNameServer.lookupPortByName(name) == port.sendPort;
  }

  /// Takes the role from whoever holds it.
  void forceAcquire() {
    if (isHeld) return;
    final hadHolder = IsolateNameServer.removePortNameMapping(name);
    if (_registerOwnPort()) {
      _roleLogger.info('$name: taken over by ${Isolate.current.debugName} (had holder: $hadHolder)');
    }
  }

  /// Returns whether the role is held, claiming it first if it is free or its holder
  /// no longer answers. Concurrent calls share one probe.
  Future<bool> tryAcquire() {
    if (isHeld) return Future.value(true);
    return _pendingAcquire ??= _acquireIfFreeOrAbandoned().whenComplete(() => _pendingAcquire = null);
  }

  /// Gives the role up. Leaves the mapping alone when someone else has taken it since.
  Future<void> release() async {
    await _pendingAcquire;
    if (isHeld) IsolateNameServer.removePortNameMapping(name);
    _port?.close();
    _port = null;
  }

  Future<bool> _acquireIfFreeOrAbandoned() async {
    final holder = IsolateNameServer.lookupPortByName(name);
    if (holder != null) {
      if (await _isAlive(holder)) return false;
      if (IsolateNameServer.lookupPortByName(name) != holder) return false;
      IsolateNameServer.removePortNameMapping(name);
    }
    final claimed = _registerOwnPort();
    if (claimed) {
      _roleLogger.info('$name: claimed by ${Isolate.current.debugName} (holder gone: ${holder != null})');
    }
    return claimed;
  }

  bool _registerOwnPort() {
    _port?.close();
    _port = null;
    final port = ReceivePort();
    if (!IsolateNameServer.registerPortWithName(port.sendPort, name)) {
      port.close();
      return false;
    }
    // The only message a holder gets is a liveness probe carrying the reply port.
    port.listen((reply) => (reply as SendPort).send(true));
    _port = port;
    return true;
  }

  Future<bool> _isAlive(SendPort holder) async {
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
