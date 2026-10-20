import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/microphone_status/microphone_status.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class _MockUserInfoCubit extends MockCubit<UserInfoState> implements UserInfoCubit {}

class _MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class _MockMicrophoneStatusBloc extends MockBloc<MicrophoneStatusEvent, MicrophoneStatusState>
    implements MicrophoneStatusBloc {}

/// Semantics nodes on screen that carry [identifier].
Iterable<SemanticsNode> _stateNode(String identifier) =>
    find.semantics.byPredicate((node) => node.getSemanticsData().identifier == identifier).evaluate();

void main() {
  late _MockUserInfoCubit userInfoCubit;
  late _MockSessionStatusCubit sessionStatusCubit;
  late _MockMicrophoneStatusBloc microphoneStatusBloc;

  setUp(() {
    userInfoCubit = _MockUserInfoCubit();
    sessionStatusCubit = _MockSessionStatusCubit();
    microphoneStatusBloc = _MockMicrophoneStatusBloc();
    when(() => userInfoCubit.state).thenReturn(const UserInfoState());
    when(() => sessionStatusCubit.state).thenReturn(const SessionStatusState());
    when(() => microphoneStatusBloc.state).thenReturn(const MicrophoneStatusState());
  });

  Future<void> pumpBar(WidgetTester tester, {Widget? title}) async {
    await tester.pumpWidget(
      ThemeProvider(
        settings: const ThemeSettings(),
        lightDynamic: null,
        darkDynamic: null,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<UserInfoCubit>.value(value: userInfoCubit),
              BlocProvider<SessionStatusCubit>.value(value: sessionStatusCubit),
              BlocProvider<MicrophoneStatusBloc>.value(value: microphoneStatusBloc),
            ],
            // Read by the bar's own controls, which it shows only once the
            // session is up.
            child: AppBarParams(
              systemNotificationsEnabled: false,
              pullableCallDialogs: const [],
              child: Builder(
                builder: (context) => Scaffold(
                  appBar: MainAppBar(context: context, title: title),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the account button keeps the whole minimum touch target', (tester) async {
    await pumpBar(tester);
    final handle = tester.ensureSemantics();

    // The bar is given the height of one touch target; a toolbar left at the
    // framework's taller default does not fit in it, and the button, centred
    // in the toolbar, loses its lower edge to the bar's.
    final rect = tester.getSemantics(find.bySemanticsIdentifier(mainAppBarId)).rect;
    expect(rect.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('the bar says connecting until the session is up', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpBar(tester);

    // A run waits on this before it does anything; the visible status line is
    // translated and disappears once connected, so the id is the contract.
    expect(_stateNode(mainAppBarConnectionStatusConnectingId), hasLength(1));
    expect(_stateNode(mainAppBarConnectionStatusConnectedId), isEmpty);

    handle.dispose();
  });

  testWidgets('the bar says connected once the session is up, and nothing out loud', (tester) async {
    final handle = tester.ensureSemantics();
    when(() => sessionStatusCubit.state)
        .thenReturn(const SessionStatusState(status: SessionStatus(signalingStatus: CallStatus.ready)));

    await pumpBar(tester, title: const Text('Recents'));

    expect(_stateNode(mainAppBarConnectionStatusConnectingId), isEmpty);
    final state = _stateNode(mainAppBarConnectionStatusConnectedId).single;
    // Whatever text a node carries is what a screen reader speaks.
    expect(state.getSemanticsData().label, isEmpty);
    expect(state.getSemanticsData().value, isEmpty);

    // TalkBack announces a newly opened tab by the node flagged as naming the
    // route; it keeps the screen's name and nothing else.
    final header = find.semantics.byPredicate((node) => node.getSemanticsData().flagsCollection.namesRoute);
    final data = header.evaluate().single.getSemanticsData();
    expect(data.label, 'Recents');
    expect(data.value, isEmpty);

    handle.dispose();
  });

  testWidgets('exactly one of the two states is on screen in every session state', (tester) async {
    // A run reads the absence of both as a build without the ids, not as
    // "not connected" - so neither may ever be missing, and both never shown.
    final handle = tester.ensureSemantics();

    for (final signalingStatus in CallStatus.values) {
      for (final pushTokenError in [null, 'failed']) {
        final status = SessionStatus(signalingStatus: signalingStatus, pushTokenError: pushTokenError);
        when(() => sessionStatusCubit.state).thenReturn(SessionStatusState(status: status));

        // A fresh bar for every state: the mock never emits, so a bar left in
        // place would keep showing the state it was first built with.
        await tester.pumpWidget(const SizedBox());
        await pumpBar(tester, title: const Text('Recents'));

        final connected = _stateNode(mainAppBarConnectionStatusConnectedId).length;
        final connecting = _stateNode(mainAppBarConnectionStatusConnectingId).length;
        expect(connected + connecting, 1, reason: '$status');
        expect(connected, status.isReady ? 1 : 0, reason: '$status');
      }
    }

    handle.dispose();
  });
}
