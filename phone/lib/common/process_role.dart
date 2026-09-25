import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:logging/logging.dart';

final _logger = Logger('ProcessRole');

// Sent to the current holder when another isolate takes the role over.
const _yieldMessage = 'yield';

/// A role that at most one isolate of the process holds at a time.
///
/// The app runs several isolates in one process - the UI one, the FCM background
/// handler, the push isolate - and each builds its own dependencies. When a job must
/// run once per process rather than once per isolate, every candidate creates a
/// [ProcessRole] under the same [name] and does the job only while [isHeld].
///
/// The holder is recorded in [IsolateNameServer], which is process-wide. The holder
/// answers liveness probes, so a holder that died without [release] (its engine
/// destroyed) is detected and its role reclaimed by [holdOrReclaim].
///
/// Native only: the web name server throws.
class ProcessRole {
  ProcessRole(this.name, {Duration probeTimeout = const Duration(milliseconds: 500)}) : _probeTimeout = probeTimeout;

  /// The [IsolateNameServer] key shared by every candidate for this role.
  final String name;

  final Duration _probeTimeout;

  // Non-null while this isolate holds the role.
  ReceivePort? _port;
  Future<bool>? _pendingReclaim;

  bool get isHeld => _port != null;

  /// Takes the role if nobody holds it. Returns whether it is held afterwards.
  bool claimIfFree() {
    if (isHeld) return true;
    final claimed = _register();
    if (claimed) _logger.info('$name: claimed by ${Isolate.current.debugName} (was free)');
    return claimed;
  }

  /// Takes the role from whoever holds it; the previous holder is told to let go.
  void takeOver() {
    final holder = IsolateNameServer.lookupPortByName(name);
    if (isHeld && holder == _port!.sendPort) return;
    holder?.send(_yieldMessage);
    IsolateNameServer.removePortNameMapping(name);
    if (_register()) {
      _logger.info('$name: taken over by ${Isolate.current.debugName} (had holder: ${holder != null})');
    }
  }

  /// Returns whether the role is held, first reclaiming it if the holder no longer answers.
  ///
  /// Concurrent calls share one probe.
  Future<bool> holdOrReclaim() {
    if (isHeld) return Future.value(true);
    return _pendingReclaim ??= _reclaimIfHolderGone().whenComplete(() => _pendingReclaim = null);
  }

  /// Gives the role up, if held. Leaves the mapping alone when someone else has taken it since.
  Future<void> release() async {
    await _pendingReclaim;
    final port = _port;
    if (port == null) return;
    _port = null;
    if (IsolateNameServer.lookupPortByName(name) == port.sendPort) {
      IsolateNameServer.removePortNameMapping(name);
    }
    port.close();
  }

  bool _register() {
    final port = ReceivePort();
    if (!IsolateNameServer.registerPortWithName(port.sendPort, name)) {
      port.close();
      return false;
    }
    port.listen(_onMessage);
    _port = port;
    return true;
  }

  void _onMessage(Object? message) {
    if (message is SendPort) {
      message.send(true); // liveness probe from another candidate
    } else if (message == _yieldMessage) {
      _logger.info('$name: ${Isolate.current.debugName} let go, another isolate took over');
      _port?.close();
      _port = null;
    }
  }

  Future<bool> _reclaimIfHolderGone() async {
    final holder = IsolateNameServer.lookupPortByName(name);
    if (holder != null) {
      if (await _answers(holder)) return false;
      if (IsolateNameServer.lookupPortByName(name) != holder) return false;
      // In case it is only slow rather than gone, tell it to stop.
      holder.send(_yieldMessage);
      IsolateNameServer.removePortNameMapping(name);
    }
    final claimed = _register();
    if (claimed) {
      _logger.info('$name: claimed by ${Isolate.current.debugName} (holder gone: ${holder != null})');
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
}
