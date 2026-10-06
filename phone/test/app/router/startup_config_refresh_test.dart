import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:signaling/signaling.dart' show Line, Registration, RegistrationStatus, StateHandshake;

import 'package:webtrit_phone/app/router/startup_config_refresh.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/feature_access_factories.dart';

class MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _FakeLine extends Fake implements Line {}

/// A signaling session with one line, taken by a call or free.
class _FakeHandshake extends Fake implements StateHandshake {
  _FakeHandshake({required bool lineTaken}) : lines = [lineTaken ? _FakeLine() : null];

  @override
  final List<Line?> lines;

  @override
  Line? get guestLine => null;
}

class _FakeSignalingModule extends Fake implements SignalingModule {
  @override
  StateHandshake? sessionHandshake;
}

const _connecting = CallState();

const _registered = CallState(
  callServiceState: CallServiceState(registration: Registration(status: RegistrationStatus.registered)),
);

/// The server cannot be reached at all.
final _unreachable = CallState(
  callServiceState: CallServiceState(lastSignalingClientConnectError: Exception('refused')),
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

void main() {
  late MockCallBloc callBloc;
  late StreamController<CallState> states;
  late StreamController<Object?> reads;
  late FeatureAccess started;
  late FeatureAccess offered;
  late int restarts;
  late _FakeSignalingModule signaling;

  Future<void> pumpRefresh(WidgetTester tester, {CallState initial = _connecting}) async {
    when(() => callBloc.state).thenReturn(initial);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FeatureAccess>.value(value: started),
          Provider<StartupFeatureAccessCheck>.value(
            value: StartupFeatureAccessCheck(systemInfoReads: reads.stream, current: () async => offered),
          ),
          BlocProvider<CallBloc>.value(value: callBloc),
        ],
        child: StartupConfigRefresh(
          signalingModule: signaling,
          sessionEnded: Future<void>.value(),
          startAnew: () => restarts++,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> backendRead(WidgetTester tester) async {
    reads.add(null);
    await tester.pump();
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
    reads = StreamController<Object?>.broadcast();
    started = featureAccessFor(systemInfoWithSupported(['voicemail', 'voicemailForward']));
    offered = featureAccessFor(systemInfoWithSupported(['voicemail']));
    restarts = 0;
    signaling = _FakeSignalingModule()..sessionHandshake = _FakeHandshake(lineTaken: false);
  });

  tearDown(() async {
    await states.close();
    await reads.close();
  });

  testWidgets('a session the backend agrees with is left alone', (tester) async {
    offered = started;
    await pumpRefresh(tester, initial: _registered);

    await backendRead(tester);
    await emit(tester, _registered);

    expect(restarts, 0);
  });

  testWidgets('nothing is asked before the backend has been read', (tester) async {
    await pumpRefresh(tester, initial: _registered);

    await emit(tester, _registered);

    expect(restarts, 0);
  });

  testWidgets('a session behind the backend is started anew once it is idle', (tester) async {
    await pumpRefresh(tester, initial: _registered);

    await backendRead(tester);

    expect(restarts, 1);
  });

  testWidgets('waits for the session to be heard of: the call the app was started for may not be known yet', (
    tester,
  ) async {
    await pumpRefresh(tester);

    await backendRead(tester);
    expect(restarts, 0);

    await emit(tester, _registered);
    expect(restarts, 1);
  });

  // A call the platform presented is taken up by the bloc only after the
  // caller has been looked up; with the server out of reach nothing but the
  // handshake could say that no such call is on its way.
  testWidgets('a server that cannot be reached is no proof that no call is there', (tester) async {
    signaling.sessionHandshake = null;
    await pumpRefresh(tester);

    await backendRead(tester);
    await emit(tester, _unreachable);
    expect(restarts, 0);

    signaling.sessionHandshake = _FakeHandshake(lineTaken: false);
    await emit(tester, _registered);
    expect(restarts, 1);
  });

  testWidgets('a handshake the bloc reports before the module holds the session is not enough', (tester) async {
    signaling.sessionHandshake = null;
    await pumpRefresh(tester, initial: _registered);

    await backendRead(tester);

    expect(restarts, 0);
  });

  testWidgets('a call is not ended for it: the restart follows the call', (tester) async {
    final inCall = _registered.copyWith(activeCalls: [_ringing]);
    await pumpRefresh(tester, initial: inCall);

    await backendRead(tester);
    expect(restarts, 0);

    await emit(tester, _registered);
    expect(restarts, 1);
  });

  // Seen on a Redmi A5: the app was started by a call answered from its
  // notification, the bloc reported the handshake 130 ms before it took the
  // call up, and the session was replaced under the call.
  testWidgets('a call the handshake lists and the bloc has not taken up yet is not ended either', (tester) async {
    signaling.sessionHandshake = _FakeHandshake(lineTaken: true);
    await pumpRefresh(tester, initial: _registered);

    await backendRead(tester);
    expect(restarts, 0);

    await emit(tester, _registered.copyWith(activeCalls: [_ringing]));
    signaling.sessionHandshake = _FakeHandshake(lineTaken: false);
    expect(restarts, 0);

    await emit(tester, _registered);
    expect(restarts, 1);
  });

  testWidgets('asks once, whatever the bloc says afterwards', (tester) async {
    await pumpRefresh(tester, initial: _registered);

    await backendRead(tester);
    await emit(tester, _registered.copyWith(activeCalls: [_ringing]));
    await emit(tester, _registered);

    expect(restarts, 1);
  });

  testWidgets('a session that ended before it was idle asks for nothing', (tester) async {
    await pumpRefresh(tester);
    await backendRead(tester);

    await tester.pumpWidget(const SizedBox());
    await emit(tester, _registered);

    expect(restarts, 0);
  });
}
