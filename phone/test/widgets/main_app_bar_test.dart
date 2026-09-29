import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/microphone_status/microphone_status.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class _MockUserInfoCubit extends MockCubit<UserInfoState> implements UserInfoCubit {}

class _MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class _MockMicrophoneStatusBloc extends MockBloc<MicrophoneStatusEvent, MicrophoneStatusState>
    implements MicrophoneStatusBloc {}

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

  Future<void> pumpBar(WidgetTester tester) async {
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
            child: Builder(
              builder: (context) => Scaffold(appBar: MainAppBar(context: context)),
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
}
