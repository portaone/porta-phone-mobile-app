import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/features/microphone_status/microphone_status.dart';
import 'package:webtrit_phone/features/register_status/register_status.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/settings/settings.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../call_center/fake_call_queues_repository.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

class _MockMicrophoneStatusBloc extends MockBloc<MicrophoneStatusEvent, MicrophoneStatusState>
    implements MicrophoneStatusBloc {}

class _MockUserInfoCubit extends MockCubit<UserInfoState> implements UserInfoCubit {}

class _MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class _MockRegisterStatusCubit extends MockCubit<RegisterStatus> implements RegisterStatusCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

// The settings list is the only entry to the queues, and it has two gates:
// the deployment offers the feature, and this user is an agent of something.
// These pin both, because either one failing open puts a dead row in front of
// every user of every other deployment.
void main() {
  const info = UserInfo(
    numbers: Numbers(main: '555002'),
    aliasName: 'User 555002',
  );

  late _MockSettingsBloc settingsBloc;
  late _MockMicrophoneStatusBloc microphoneStatusBloc;
  late _MockUserInfoCubit userInfoCubit;
  late _MockSessionStatusCubit sessionStatusCubit;
  late _MockRegisterStatusCubit registerStatusCubit;
  late _MockStackRouter router;
  late FakeCallQueuesRepository repository;

  setUpAll(() => registerFallbackValue(const CallCenterScreenPageRoute()));

  setUp(() {
    settingsBloc = _MockSettingsBloc();
    microphoneStatusBloc = _MockMicrophoneStatusBloc();
    userInfoCubit = _MockUserInfoCubit();
    sessionStatusCubit = _MockSessionStatusCubit();
    registerStatusCubit = _MockRegisterStatusCubit();
    router = _MockStackRouter();

    when(() => settingsBloc.state).thenReturn(const SettingsState(progress: false));
    when(() => microphoneStatusBloc.state).thenReturn(const MicrophoneStatusState());
    when(() => userInfoCubit.state).thenReturn(const UserInfoState(userInfo: info));
    when(() => sessionStatusCubit.state).thenReturn(const SessionStatusState());
    when(() => registerStatusCubit.state).thenReturn(const RegisterStatus(value: true));
    when(
      () => router.canPop(
        ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
        ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
        ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
      ),
    ).thenReturn(false);
    when(() => router.topPage).thenReturn(null);
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
    when(() => router.navigate(any())).thenAnswer((_) async {});
  });

  tearDown(() => repository.dispose());

  Future<void> pumpSettings(
    WidgetTester tester, {
    required bool callCenterEnabled,
    required CallQueuesSnapshot snapshot,
  }) async {
    repository = FakeCallQueuesRepository(initial: snapshot);

    await tester.pumpWidget(
      ThemeProvider(
        settings: const ThemeSettings(),
        lightDynamic: null,
        darkDynamic: null,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RouterScope(
            controller: router,
            inheritableObserversBuilder: () => const [],
            stateHash: 0,
            navigatorObservers: const [],
            child: StackRouterScope(
              controller: router,
              stateHash: 0,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<SettingsBloc>.value(value: settingsBloc),
                  BlocProvider<MicrophoneStatusBloc>.value(value: microphoneStatusBloc),
                  BlocProvider<UserInfoCubit>.value(value: userInfoCubit),
                  BlocProvider<SessionStatusCubit>.value(value: sessionStatusCubit),
                  BlocProvider<RegisterStatusCubit>.value(value: registerStatusCubit),
                  BlocProvider(create: (context) => CallQueuesCubit(repository)),
                ],
                child: PresenceViewParams(
                  hybridPresenceSupport: false,
                  blfViaSipSupport: false,
                  presenceViaSipSupport: false,
                  child: SettingsScreen(
                    sections: const [],
                    sessionsEnabled: false,
                    callCenterEnabled: callCenterEnabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('an agent gets the row, with how many queues they are taking calls from', (tester) async {
    await pumpSettings(
      tester,
      callCenterEnabled: true,
      snapshot: CallQueuesSnapshot(known: true, queues: [testQueue('0111'), testQueue('0222', loggedIn: false)]),
    );

    expect(find.text('Call center'), findsOneWidget);
    expect(find.text('Taking calls from 1 of 2 queues'), findsOneWidget);
  });

  testWidgets('tapping it opens the queues', (tester) async {
    await pumpSettings(
      tester,
      callCenterEnabled: true,
      snapshot: CallQueuesSnapshot(known: true, queues: [testQueue('0111')]),
    );

    await tester.tap(find.text('Call center'));
    await tester.pumpAndSettle();

    verify(() => router.navigate(const CallCenterScreenPageRoute())).called(1);
  });

  testWidgets('a user who is not an agent gets no row', (tester) async {
    await pumpSettings(tester, callCenterEnabled: true, snapshot: const CallQueuesSnapshot(known: true));

    expect(find.text('Call center'), findsNothing);
  });

  testWidgets('nothing is shown before the first answer', (tester) async {
    await pumpSettings(tester, callCenterEnabled: false, snapshot: const CallQueuesSnapshot());

    expect(find.text('Call center'), findsNothing);
  });

  testWidgets('a deployment without the feature gets no row, whatever the list says', (tester) async {
    await pumpSettings(
      tester,
      callCenterEnabled: false,
      snapshot: CallQueuesSnapshot(known: true, queues: [testQueue('0111')]),
    );

    expect(find.text('Call center'), findsNothing);
  });
}
