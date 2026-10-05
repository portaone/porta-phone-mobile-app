import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signaling/signaling.dart' show Registration, RegistrationStatus;

import 'package:webtrit_phone/app/router/app_update_check.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/services/services.dart';

import '../../mocks/app_update_info.dart';

class MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

const _connecting = CallState();

const _registered = CallState(
  callServiceState: CallServiceState(registration: Registration(status: RegistrationStatus.registered)),
);

/// The server cannot be reached at all.
final _unreachable = CallState(
  callServiceState: CallServiceState(lastSignalingClientConnectError: Exception('refused')),
);

const _offline = CallState(callServiceState: CallServiceState(networkStatus: NetworkStatus.none));

const _unregistered = CallState(
  callServiceState: CallServiceState(registration: Registration(status: RegistrationStatus.unregistered)),
);

final _ringing = ActiveCall(
  callId: 'call-1',
  direction: CallDirection.incoming,
  line: 0,
  handle: const CallkeepHandle.number('1001'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.incomingFromPush,
);

final _android = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  late MockCallBloc callBloc;
  late StreamController<CallState> states;
  late List<String> calls;
  late bool deviceLocked;

  /// What Play would do if asked: an update is there to offer, and the user
  /// turns it down.
  AppUpdateService createService(CanProceedWithUpdate canProceed) {
    return AppUpdateService(
      canProceed: canProceed,
      checkForUpdate: () async {
        calls.add('check');
        return appUpdateInfo(
          updateAvailability: UpdateAvailability.updateAvailable,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: true,
          availableVersionCode: 2,
        );
      },
      performImmediateUpdate: () async => AppUpdateResult.success,
      startFlexibleUpdate: () async {
        calls.add('prompt');
        return AppUpdateResult.userDeniedUpdate;
      },
      completeFlexibleUpdate: () async {},
    );
  }

  Future<void> pumpCheck(
    WidgetTester tester, {
    CallState initial = _connecting,
    Future<bool> Function()? isDeviceLocked,
  }) async {
    when(() => callBloc.state).thenReturn(initial);
    await tester.pumpWidget(
      BlocProvider<CallBloc>.value(
        value: callBloc,
        child: AppUpdateCheck(
          createService: createService,
          isDeviceLocked: isDeviceLocked ?? () async => deviceLocked,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, CallState state) async {
    when(() => callBloc.state).thenReturn(state);
    states.add(state);
    await tester.pump();
    await tester.pump();
  }

  setUp(() {
    callBloc = MockCallBloc();
    states = StreamController<CallState>.broadcast();
    whenListen(callBloc, states.stream, initialState: _connecting);
    calls = [];
    deviceLocked = false;
  });

  tearDown(() => states.close());

  testWidgets('waits for the handshake', variant: _android, (tester) async {
    await pumpCheck(tester);

    expect(calls, isEmpty);
  });

  testWidgets('prompts once the handshake is established and no call is there', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _registered);

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('an account that is not registered is still offered the update', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _unregistered);

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('a session already established when the widget mounts is checked', variant: _android, (tester) async {
    await pumpCheck(tester, initial: _registered);

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('a build that cannot reach the server is still offered the update', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _unreachable);

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('nothing is decided without a network', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _offline);

    expect(calls, isEmpty);
  });

  testWidgets('a call only delays the check until it has ended', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _registered.copyWith(activeCalls: [_ringing]));
    expect(calls, isEmpty);

    await emit(tester, _registered);

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('waits for the app to be in front', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _registered.copyWith(currentAppLifecycleState: AppLifecycleState.paused));
    expect(calls, isEmpty);

    await emit(tester, _registered.copyWith(currentAppLifecycleState: AppLifecycleState.resumed));

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('an update found during a call is offered once the call has ended', variant: _android, (tester) async {
    // Clear for the first question, and the call is there by the second.
    var callArrives = true;
    await pumpCheck(
      tester,
      isDeviceLocked: () async {
        if (callArrives && calls.contains('check')) {
          callArrives = false;
          when(() => callBloc.state).thenReturn(_registered.copyWith(activeCalls: [_ringing]));
        }
        return false;
      },
    );

    await emit(tester, _registered);
    expect(calls, ['check']);

    await emit(tester, _registered);

    expect(calls, ['check', 'check', 'prompt']);
  });

  testWidgets('a locked phone delays the check until it is unlocked', variant: _android, (tester) async {
    deviceLocked = true;
    await pumpCheck(tester);

    await emit(tester, _registered);
    expect(calls, isEmpty);

    deviceLocked = false;
    await emit(tester, _registered.copyWith(currentAppLifecycleState: AppLifecycleState.resumed));

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('one check runs at a time', variant: _android, (tester) async {
    final lockState = Completer<bool>();
    await pumpCheck(tester, isDeviceLocked: () => lockState.future);

    await emit(tester, _registered);
    await emit(tester, _registered);
    lockState.complete(false);
    await tester.pump();
    await tester.pump();

    expect(calls, ['check', 'prompt']);
  });

  testWidgets('a session that ended while the lock state was read gets no prompt', variant: _android, (tester) async {
    final lockState = Completer<bool>();
    await pumpCheck(tester, isDeviceLocked: () => calls.contains('check') ? lockState.future : Future.value(false));

    await emit(tester, _registered);
    expect(calls, ['check']);

    await tester.pumpWidget(const SizedBox());
    lockState.complete(false);
    await tester.pump();
    await tester.pump();

    expect(calls, ['check']);
  });

  testWidgets('a check that reached its end is the last of the session', variant: _android, (tester) async {
    await pumpCheck(tester);

    await emit(tester, _registered);
    await emit(tester, _connecting);
    await emit(tester, _registered);

    expect(calls, ['check', 'prompt']);
  });
}
