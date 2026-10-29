import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/settings/settings.dart';
import 'package:webtrit_phone/features/settings/widgets/session_status_list_tile.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

void main() {
  late _MockSettingsBloc settingsBloc;
  late int taps;

  setUp(() {
    settingsBloc = _MockSettingsBloc();
    taps = 0;

    when(() => settingsBloc.state).thenReturn(const SettingsState(progress: false));
  });

  Future<void> pump(WidgetTester tester, {SessionIssue? topIssue}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [BlocProvider<SettingsBloc>.value(value: settingsBloc)],
            child: SessionStatusListTile(
              status: const SessionStatus(signalingStatus: CallStatus.ready),
              registered: true,
              topIssue: topIssue,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the row is a button, not a bare gesture area', (tester) async {
    await pump(tester);

    // It used to be a gesture detector wrapped around the row, which answered
    // a tap without ever announcing that it could be pressed.
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNotNull);

    await tester.tap(find.byType(ListTile));
    expect(taps, 1);
  });

  testWidgets('a tap at the far edge of the row still opens it', (tester) async {
    await pump(tester);

    final row = tester.getRect(find.byType(ListTile));
    await tester.tapAt(Offset(row.right - 8, row.center.dy));

    expect(taps, 1);
  });

  testWidgets('a missing microphone is told on the row itself, in place of the caption', (tester) async {
    await pump(
      tester,
      topIssue: const SessionIssue(id: SessionIssueId.microphoneUnavailable, severity: SessionIssueSeverity.critical),
    );

    expect(find.text('Missing microphone permission. Unable to make calls.'), findsOneWidget);
    // No separate chip under the row any more: the row is the one place to tap.
    expect(find.byIcon(Icons.warning_amber), findsNothing);

    await tester.tap(find.byType(ListTile));
    expect(taps, 1);
  });
}
