import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_ios/src/common/callkeep.pigeon.dart';
import 'package:webtrit_callkeep_ios/webtrit_callkeep_ios.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

const _prefix = 'dev.flutter.pigeon.webtrit_callkeep_ios';

WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

/// What the iOS platform implementation tells the native side for a declaration.
///
/// The native side is only ever told what to do; the reconciliation happens here. So the
/// contract is checked at this boundary: which uuids are asked to group and which to ungroup.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<List<Object?>> setCalls;
  late List<List<Object?>> unsetCalls;

  void record(String channel, List<List<Object?>> into) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(channel, (message) async {
      final args = const StandardMessageCodec().decodeMessage(message)! as List<Object?>;
      into.add((args[0]! as List<Object?>).cast<String>());
      return const StandardMessageCodec().encodeMessage([null]);
    });
  }

  setUp(() {
    WebtritCallkeep.registerWith();
    setCalls = [];
    unsetCalls = [];
    record('$_prefix.PHostApi.setCallGroup', setCalls);
    record('$_prefix.PHostApi.unsetCallGroup', unsetCalls);
  });

  test('a member of a group is not held on its own', () async {
    final heldCalls = <List<Object?>>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      '$_prefix.PHostApi.setHeld',
      (message) async {
        heldCalls.add(const StandardMessageCodec().decodeMessage(message)! as List<Object?>);
        return const StandardMessageCodec().encodeMessage([null]);
      },
    );
    await platform.setCallGroup('room', ['a', 'b']);
    expect(await platform.setHeld('a', true), CallkeepCallRequestError.callIsGrouped);
    expect(heldCalls, isEmpty);
    await platform.unsetCallGroup(['a', 'b']);
    expect(await platform.setHeld('a', true), isNull);
    expect(heldCalls, hasLength(1));
  });

  test('grouping two calls asks the native side once, with the whole membership', () async {
    expect(await platform.setCallGroup('room', ['A', 'B']), isNull);
    expect(setCalls, hasLength(1));
    expect(setCalls.single, hasLength(2));
    expect(unsetCalls, isEmpty);
  });

  test('shrinking a group ungroups the member that left, then restates the rest', () async {
    await platform.setCallGroup('room', ['A', 'B', 'C']);
    setCalls.clear();

    expect(await platform.setCallGroup('room', ['A', 'B']), isNull);

    expect(unsetCalls, hasLength(1), reason: 'C must be taken out of the group it was in');
    expect(unsetCalls.single, hasLength(1));
    expect(setCalls, hasLength(1));
    expect(setCalls.single, hasLength(2));
  });

  test('declaring a single call takes the whole group apart natively', () async {
    await platform.setCallGroup('room', ['A', 'B', 'C']);
    setCalls.clear();

    expect(await platform.setCallGroup('room', ['A']), isNull);

    expect(unsetCalls.single, hasLength(3), reason: 'B and C must not stay grouped without A');
    expect(setCalls, isEmpty);
  });

  test('restating the same membership does not ungroup anyone', () async {
    await platform.setCallGroup('room', ['A', 'B']);
    setCalls.clear();

    await platform.setCallGroup('room', ['B', 'A']);

    expect(unsetCalls, isEmpty);
    expect(setCalls.single, hasLength(2));
  });

  test('an empty list reaches the native side as nothing at all', () async {
    await platform.setCallGroup('room', ['A', 'B']);
    setCalls.clear();

    expect(await platform.setCallGroup('room', []), isNull);
    expect(await platform.unsetCallGroup([]), isNull);

    expect(setCalls, isEmpty);
    expect(unsetCalls, isEmpty);
  });

  test('releasing one of two ungroups both, because one call is not a group', () async {
    await platform.setCallGroup('room', ['A', 'B']);

    expect(await platform.unsetCallGroup(['A']), isNull);

    expect(unsetCalls.single, hasLength(2));
  });

  test('a call that is reported ended leaves its group', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      '$_prefix.PHostApi.reportEndCall',
      (message) async => const StandardMessageCodec().encodeMessage([null]),
    );
    await platform.setCallGroup('room', ['A', 'B', 'C']);
    setCalls.clear();

    await platform.reportEndCall('C', 'Carol', CallkeepEndCallReason.remoteEnded);
    await platform.setCallGroup('room', ['A', 'B']);

    expect(unsetCalls, isEmpty, reason: 'C was already forgotten, there is nothing to ungroup');
    expect(setCalls.single, hasLength(2));
  });

  group('what CallKit refused stays as it was', () {
    late bool rejectSet;
    late bool rejectRelease;

    void answer(String method, List<List<Object?>> into, bool Function() rejected) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$_prefix.PHostApi.$method',
        (message) async {
          final codec = PHostApi.pigeonChannelCodec;
          final args = codec.decodeMessage(message)! as List<Object?>;
          into.add((args[0]! as List<Object?>).cast<String>());
          return codec.encodeMessage([
            if (rejected()) PCallRequestError(value: PCallRequestErrorEnum.internal) else null,
          ]);
        },
      );
    }

    setUp(() {
      rejectSet = false;
      rejectRelease = false;
      answer('setCallGroup', setCalls, () => rejectSet);
      answer('unsetCallGroup', unsetCalls, () => rejectRelease);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$_prefix.PHostApi.setHeld',
        (message) async => const StandardMessageCodec().encodeMessage([null]),
      );
    });

    test('a refused grouping leaves nobody grouped, so an ordinary hold goes through', () async {
      rejectSet = true;
      expect(await platform.setCallGroup('room', ['a', 'b']), CallkeepCallRequestError.internal);
      expect(await platform.setHeld('a', true), isNull);
    });

    test('a refused ungrouping is asked again on retry', () async {
      await platform.setCallGroup('room', ['a', 'b']);
      rejectRelease = true;
      expect(await platform.unsetCallGroup(['a', 'b']), CallkeepCallRequestError.internal);
      rejectRelease = false;
      expect(await platform.unsetCallGroup(['a', 'b']), isNull);
      expect(unsetCalls, hasLength(2));
    });

    test('a refused shrink still removes the omitted member on retry', () async {
      await platform.setCallGroup('room', ['a', 'b', 'c']);
      rejectRelease = true;
      expect(await platform.setCallGroup('room', ['a', 'b']), CallkeepCallRequestError.internal);
      rejectRelease = false;
      expect(await platform.setCallGroup('room', ['a', 'b']), isNull);
      expect(unsetCalls, hasLength(2));
      expect(unsetCalls.last, hasLength(1));
    });

    test('a hold CallKit puts on a member is answered without the delegate', () async {
      final delegate = _HoldCountingDelegate();
      platform.setDelegate(delegate);
      await platform.setCallGroup('room', ['a', 'b']);
      final uuid = setCalls.single.first! as String;
      final done = Completer<ByteData?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        '$_prefix.PDelegateFlutterApi.performSetHeld',
        PDelegateFlutterApi.pigeonChannelCodec.encodeMessage([uuid, true]),
        done.complete,
      );
      final reply = PDelegateFlutterApi.pigeonChannelCodec.decodeMessage(await done.future)! as List<Object?>;
      expect(reply.first, isTrue);
      expect(delegate.holds, 0);
    });
  });

  group('the record follows the calls', () {
    late Completer<void> gate;
    late Completer<void> releaseGate;
    late List<List<Object?>> groupings;

    /// A host method that just succeeds.
    void ok(String channel) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        channel,
        (message) async => const StandardMessageCodec().encodeMessage([null]),
      );
    }

    setUp(() {
      gate = Completer<void>();
      releaseGate = Completer<void>()..complete();
      groupings = [];
      // CallKit answers a grouping only once the test opens the gate, so something can
      // happen to the calls while the request is in flight.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$_prefix.PHostApi.setCallGroup',
        (message) async {
          final args = const StandardMessageCodec().decodeMessage(message)! as List<Object?>;
          groupings.add((args[0]! as List<Object?>).cast<String>());
          await gate.future;
          return const StandardMessageCodec().encodeMessage([null]);
        },
      );
      // Ungrouping answers once the release gate opens; it is open unless a test closes it.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        '$_prefix.PHostApi.unsetCallGroup',
        (message) async {
          await releaseGate.future;
          return const StandardMessageCodec().encodeMessage([null]);
        },
      );
      for (final method in ['tearDown', 'setUp', 'reportEndCall', 'reportNewIncomingCall', 'setHeld']) {
        ok('$_prefix.PHostApi.$method');
      }
    });

    test('a release answered after tearDown asks CallKit for nothing more', () async {
      gate.complete();
      await platform.setCallGroup('room', ['a', 'b', 'c']);
      expect(groupings, hasLength(1));
      releaseGate = Completer<void>();
      final shrinking = platform.setCallGroup('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      await platform.tearDown();
      releaseGate.complete();
      expect(await shrinking, isNull);
      expect(groupings, hasLength(1), reason: 'the provider is gone; the old work stops at the release');
    });

    test('a release answered after a new session leaves that session\'s group alone', () async {
      gate.complete();
      await platform.setCallGroup('room', ['a', 'b']);
      releaseGate = Completer<void>();
      final leaving = platform.unsetCallGroup(['a']);
      await Future<void>.delayed(Duration.zero);
      await platform.tearDown();
      await platform.setUp(_options);
      for (final id in ['a', 'b']) {
        await platform.reportNewIncomingCall(id, CallkeepHandle.number(id), id, false);
      }
      expect(await platform.setCallGroup('room', ['a', 'b']), isNull);
      releaseGate.complete();
      expect(await leaving, isNull);
      expect(
        await platform.setHeld('b', true),
        CallkeepCallRequestError.callIsGrouped,
        reason: 'the old provider released a; the new session\'s group stands',
      );
    });

    test('a second group is refused while one is live', () async {
      gate.complete();
      expect(await platform.setCallGroup('room', ['a', 'b']), isNull);
      expect(await platform.setCallGroup('other', ['c', 'd']), CallkeepCallRequestError.maximumCallGroupsReached);
      expect(groupings, hasLength(1), reason: 'CallKit was not asked for the second group');
      expect(await platform.setCallGroup('room', ['a', 'b', 'c']), isNull, reason: 'the live name restates its group');
      await platform.unsetCallGroup(['a', 'b', 'c']);
      expect(
        await platform.setCallGroup('other', ['c', 'd']),
        isNull,
        reason: 'the group is gone, so its name is free',
      );
    });

    test('a group does not outlive tearDown', () async {
      gate.complete();
      await platform.setCallGroup('room', ['a', 'b']);
      await platform.tearDown();
      await platform.setUp(_options);
      groupings.clear();
      unsetCalls.clear();
      expect(await platform.setCallGroup('room', ['c', 'd']), isNull);
      expect(unsetCalls, isEmpty, reason: 'the old session\'s members went with its provider');
      expect(groupings, hasLength(1));
    });

    test('a grouping answered after a member ended does not put it back', () async {
      final grouping = platform.setCallGroup('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      expect(groupings, hasLength(1), reason: 'CallKit has been asked and has not answered yet');
      await platform.reportEndCall('a', 'Alice', CallkeepEndCallReason.remoteEnded);
      gate.complete();
      expect(await grouping, isNull);
      expect(await platform.setHeld('b', true), isNull, reason: 'a ended while CallKit was asked; b is alone');
    });

    test('a grouping answered after a reset records nothing', () async {
      platform.setDelegate(_HoldCountingDelegate());
      final grouping = platform.setCallGroup('room', ['a', 'b']);
      await Future<void>.delayed(Duration.zero);
      expect(groupings, hasLength(1));
      final reset = Completer<ByteData?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        '$_prefix.PDelegateFlutterApi.didReset',
        PDelegateFlutterApi.pigeonChannelCodec.encodeMessage(<Object?>[]),
        reset.complete,
      );
      await reset.future;
      gate.complete();
      expect(await grouping, isNull);
      expect(await platform.setHeld('b', true), isNull, reason: 'the provider was reset while CallKit was asked');
    });
  });
}

const _options = CallkeepOptions(
  ios: CallkeepIOSOptions(
    localizedName: 'test',
    maximumCallGroups: 13,
    maximumCallsPerCallGroup: 13,
    supportedHandleTypes: {CallkeepHandleType.number},
  ),
  android: CallkeepAndroidOptions(),
);

class _HoldCountingDelegate implements CallkeepDelegate {
  int holds = 0;

  @override
  Future<bool> performSetHeld(String callId, bool onHold) async {
    holds++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
