import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/common/process_role.dart';

// Each ProcessRole stands in for one isolate of the process; they share the name server.
void main() {
  const name = 'process_role_test';
  final roles = <ProcessRole>[];

  ProcessRole candidate() {
    final role = ProcessRole(name, probeTimeout: const Duration(milliseconds: 50));
    roles.add(role);
    return role;
  }

  // Lets a yield message sent to a holder's port be delivered.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  tearDown(() async {
    for (final role in roles) {
      await role.release();
    }
    roles.clear();
    IsolateNameServer.removePortNameMapping(name);
  });

  test('the first candidate claims a free role, the second does not', () {
    final first = candidate();
    final second = candidate();
    expect(first.claimIfFree(), isTrue);
    expect(second.claimIfFree(), isFalse);
    expect(first.isHeld, isTrue);
    expect(second.isHeld, isFalse);
  });

  test('takeOver moves the role and the previous holder lets go', () async {
    final background = candidate()..claimIfFree();
    final ui = candidate()..takeOver();
    await settle();
    expect(ui.isHeld, isTrue);
    expect(background.isHeld, isFalse);
  });

  test('holdOrReclaim leaves a live holder alone', () async {
    final holder = candidate()..claimIfFree();
    final standby = candidate();
    expect(await standby.holdOrReclaim(), isFalse);
    expect(holder.isHeld, isTrue);
  });

  test('holdOrReclaim takes the role once the holder released it', () async {
    final holder = candidate()..claimIfFree();
    final standby = candidate();
    await holder.release();
    expect(await standby.holdOrReclaim(), isTrue);
  });

  test('holdOrReclaim takes the role from a holder that died without release', () async {
    final dead = ReceivePort();
    IsolateNameServer.registerPortWithName(dead.sendPort, name);
    dead.close();
    final standby = candidate();
    expect(standby.claimIfFree(), isFalse);
    expect(await standby.holdOrReclaim(), isTrue);
  });

  test('a holder displaced in the name server no longer holds the role', () async {
    final first = candidate()..claimIfFree();
    // Two candidates acting at once: the other one removes and replaces the mapping
    // without the first ever being told to let go.
    IsolateNameServer.removePortNameMapping(name);
    final second = candidate()..claimIfFree();
    expect(first.isHeld, isFalse);
    expect(await first.holdOrReclaim(), isFalse);
    expect(second.isHeld, isTrue);
  });

  test('release does not remove a mapping someone else took over', () async {
    final background = candidate()..claimIfFree();
    final ui = candidate()..takeOver();
    await settle();
    await background.release();
    final third = candidate();
    expect(third.claimIfFree(), isFalse);
    expect(ui.isHeld, isTrue);
  });
}
