import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockCubit extends MockCubit<VoicemailForwardingState> implements VoicemailForwardingCubit {}

// What the person is told once a forward is over. It is said here rather than
// on the voicemail screen because by then they are in the address book, two
// sections away from where they started.
void main() {
  late _MockCubit cubit;
  late StreamController<VoicemailForwardingState> states;

  final message = Voicemail(
    id: 'vm-1',
    date: '2026-09-16T10:00:00Z',
    duration: 10,
    sender: '1000',
    displaySender: '1000',
    receiver: '2000',
    status: ReadStatus.read,
    size: 100,
    type: 'audio',
    url: null,
  );

  final colleague = Contact(
    id: 1,
    sourceType: ContactSourceType.external,
    kind: ContactKind.visible,
    sourceId: 'user-7',
    isCurrentUser: false,
    aliasName: 'Iryna Shevchuk',
  );

  VoicemailForwardingState reported(VoicemailForwardOutcome outcome) => VoicemailForwardingState(
    report: VoicemailForwardReport(outcome, message: message, recipient: colleague),
  );

  setUpAll(() {
    registerFallbackValue(VoicemailForwardReport(VoicemailForwardOutcome.sent, message: message, recipient: colleague));
  });

  setUp(() {
    cubit = _MockCubit();
    states = StreamController<VoicemailForwardingState>.broadcast(sync: true);
    when(() => cubit.reportShown()).thenReturn(null);
    when(() => cubit.retry(any())).thenAnswer((_) async {});
    whenListen(cubit, states.stream, initialState: const VoicemailForwardingState());
  });

  tearDown(() async {
    await states.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<VoicemailForwardingCubit>.value(
          value: cubit,
          child: const VoicemailForwardReporter(child: Scaffold(body: SizedBox.expand())),
        ),
      ),
    );
  }

  testWidgets('a message that arrived names who it reached', (tester) async {
    await pump(tester);

    states.add(reported(VoicemailForwardOutcome.sent));
    await tester.pump();

    expect(find.text('Forwarded to Iryna Shevchuk'), findsOneWidget);
  });

  testWidgets('a refusal worth another try offers one, and takes it to the same colleague', (tester) async {
    await pump(tester);

    states.add(reported(VoicemailForwardOutcome.unavailable));
    // Let the bar finish sliding in: a tap on it mid-animation misses.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('Forwarding is not available'), findsOneWidget);

    await tester.tap(find.text('Try again'));

    // The person already chose; the backend's answer was not about who.
    verify(() => cubit.retry(any())).called(1);
  });

  testWidgets('a refusal that would repeat offers nothing', (tester) async {
    await pump(tester);

    states.add(reported(VoicemailForwardOutcome.tooLarge));
    await tester.pump();

    expect(find.text('Message too large to forward'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('an outcome is said once, however the screen rebuilds', (tester) async {
    await pump(tester);

    states.add(reported(VoicemailForwardOutcome.sent));
    await tester.pump();

    verify(() => cubit.reportShown()).called(1);
  });
}
