import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

/// What the platform reports says nothing about who asked for it, so the only
/// thing that tells an answer from an intention is what was asked and when.
class _FakeCallkeep extends Fake implements Callkeep {
  final List<(String, bool)> commands = [];
  CallkeepCallRequestError? error;

  @override
  Future<CallkeepCallRequestError?> setMuted(String callId, {required bool muted}) async {
    commands.add((callId, muted));
    return error;
  }
}

void main() {
  test('every leg is told the room mute, and each command is remembered', () async {
    final callkeep = _FakeCallkeep();
    final sync = LegMuteSync(callkeep);

    await sync.apply(['a', 'b'], true);

    expect(callkeep.commands, [('a', true), ('b', true)]);
    expect(sync.consume('a', true), isTrue, reason: 'the report of our own command');
    expect(sync.consume('b', true), isTrue);
  });

  test('a report with nothing outstanding is somebody pressing mute', () {
    final sync = LegMuteSync(_FakeCallkeep());

    expect(sync.consume('a', true), isFalse);
  });

  test('a report is matched against the oldest command, not the newest', () async {
    final callkeep = _FakeCallkeep();
    final sync = LegMuteSync(callkeep);

    await sync.apply(['a'], false);
    await sync.apply(['a'], true);

    expect(sync.consume('a', true), isFalse, reason: 'the false is still outstanding and comes first');
    expect(sync.consume('a', false), isTrue);
    expect(sync.consume('a', true), isTrue);
    expect(sync.consume('a', true), isFalse, reason: 'nothing is outstanding any more');
  });

  test('a command the platform refused is not waited for', () async {
    final callkeep = _FakeCallkeep()..error = CallkeepCallRequestError.internal;
    final sync = LegMuteSync(callkeep);

    await sync.apply(['a'], true);

    expect(sync.consume('a', true), isFalse, reason: 'nothing will come back for it');
  });

  test('a room that is over owes nothing', () async {
    final sync = LegMuteSync(_FakeCallkeep());

    await sync.apply(['a'], true);
    sync.forgetAll();

    expect(sync.consume('a', true), isFalse);
  });
}
