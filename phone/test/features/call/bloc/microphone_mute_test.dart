import 'package:flutter_test/flutter_test.dart';

import 'call_bloc_harness.dart';

/// Muting one call must not silence another.
///
/// The app captures one microphone and lends the same track to every call, so
/// a mute expressed by switching that track off reaches all of them. It is
/// expressed as a property of one connection instead: the track leaves that
/// call's audio sender and comes back to it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a muted call stops sending while the others keep their microphone', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    final first = h.seedEstablishedCall('first', line: 0);
    final second = h.seedEstablishedCall('second', line: 1);
    expect(first.fakeSenders.single.track, h.media.microphone, reason: 'one microphone, lent to both');
    expect(second.fakeSenders.single.track, h.media.microphone);

    await h.bloc.performSetMuted('first', true);
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('first')!.muted, isTrue);
    expect(first.fakeSenders.single.track, isNull, reason: 'this call sends nothing');
    expect(second.fakeSenders.single.track, isNotNull, reason: 'the other call is untouched');
    // Switching the track itself off is what used to reach across calls.
    expect(h.media.microphone.enabled, isTrue);
  });

  test('unmuting gives the call its microphone back', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    final peer = h.seedEstablishedCall('call', line: 0);

    await h.bloc.performSetMuted('call', true);
    await pumpEventQueue();
    await h.bloc.performSetMuted('call', false);
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('call')!.muted, isFalse);
    expect(peer.fakeSenders.single.track, h.media.microphone);
    expect(peer.fakeSenders.single.replaced, [null, h.media.microphone]);
  });

  test('unmuting a call that already sends leaves its sender alone', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    final peer = h.seedEstablishedCall('call', line: 0);

    await h.bloc.performSetMuted('call', false);
    await pumpEventQueue();

    expect(peer.fakeSenders.single.track, h.media.microphone);
    expect(peer.fakeSenders.single.replaced, isEmpty, reason: 'the microphone never left, so nothing is put back');
  });
}
