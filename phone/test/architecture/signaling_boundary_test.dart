import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The session's signaling module is held by the shell; a feature takes its
/// events from SignalingInbound and sends through the port it is given. A
/// feature that held the module could listen to it around the routing, and
/// nothing else would notice: this test is what keeps the seam.
///
/// In lib/features the type is allowed only where the module itself is the
/// subject: the adapter of the call feature's port, and the background
/// isolate, which runs a session of its own.
const _featuresAllowedToHoldTheModule = {
  'lib/features/call/services/call_signaling.dart',
  'lib/features/call/services/isolate_manager.dart',
  'lib/features/call/services/background_isolate_callbacks.dart',
};

final _moduleType = RegExp(r'\bSignalingModule\b');

/// The source of [file] without its comments, which may name the type freely.
String _code(File file) => file.readAsLinesSync().map((line) => line.replaceFirst(RegExp(r'//.*$'), '')).join('\n');

void main() {
  test('no feature holds the signaling module but the port adapter and the background isolate', () {
    final holders = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => _moduleType.hasMatch(_code(file)))
        .map((file) => file.path)
        .toSet();

    expect(holders.difference(_featuresAllowedToHoldTheModule), isEmpty);
  });

  test('the shell gives the call feature the routed call stream, for its events and for its answers', () {
    final blocs = _code(File('lib/app/router/main_shell_blocs.dart'));

    expect(blocs, contains('signalingEvents: signalingInbound.call'));
    expect(blocs, contains('ModuleCallSignaling(signalingModule, events: signalingInbound.call)'));
  });
}
