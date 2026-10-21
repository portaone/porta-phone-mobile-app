import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/contacts/widgets/contact_tile_adapter.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../helpers/feature_access_factories.dart';

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

// A contact row while somebody is being chosen for the call on the screen: a
// contact with one number is the choice, one with several asks which, and the
// number chosen is the one called - through the real row, the real chooser and
// the real purpose.
void main() {
  late _MockCallBloc callBloc;
  late _MockCallRoutingCubit callRoutingCubit;
  late _MockStackRouter router;
  late DestinationPickingCubit picking;
  late AttendedTransferPurpose purpose;

  setUpAll(() => registerFallbackValue(const CallControlEvent.ended('')));

  setUp(() {
    callBloc = _MockCallBloc();
    callRoutingCubit = _MockCallRoutingCubit();
    router = _MockStackRouter();
    when(() => callBloc.state).thenReturn(const CallState());
    when(() => callRoutingCubit.state).thenReturn(null);
    when(() => router.maybePop()).thenAnswer((_) async => true);

    picking = DestinationPickingCubit();
    purpose = AttendedTransferPurpose(
      announcement: 'Choose who to consult before transferring',
      pickLabel: (number) => 'Consult $number before transferring the call',
      controller: CallController(callBloc: callBloc),
      anchorCallId: 'b',
    );
    picking.ask(purpose);
  });

  tearDown(() => picking.close());

  Future<void> pumpRow(WidgetTester tester, Contact contact) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StackRouterScope(
          controller: router,
          stateHash: 0,
          child: Provider<FeatureAccess>.value(
            value: featureAccessFor(createMockSystemInfo()),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<CallBloc>.value(value: callBloc),
                BlocProvider<CallRoutingCubit>.value(value: callRoutingCubit),
                BlocProvider<DestinationPickingCubit>.value(value: picking),
              ],
              child: CallControllerScope(
                controller: CallController(callBloc: callBloc),
                child: PresenceViewParams(
                  hybridPresenceSupport: false,
                  blfViaSipSupport: false,
                  presenceViaSipSupport: false,
                  child: DestinationPicking(
                    purpose: purpose,
                    child: Scaffold(
                      body: ContactTileAdapter(contact: contact, expanded: false, onToggleExpanded: () {}),
                    ),
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

  testWidgets('a contact with several numbers asks which, and the one chosen is called', (tester) async {
    final contact = _contact(phones: const [('1001', 'ext'), ('2001', 'mobile')]);
    await pumpRow(tester, contact);

    await tester.tap(find.text(contact.displayTitle));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier(destinationNumberPickerId), findsOneWidget);
    verifyNever(() => callBloc.add(any()));

    await tester.tap(find.text('2001'));
    await tester.pumpAndSettle();

    verify(
      () => callBloc.add(
        CallControlEvent.attendedTransferCallPlaced(
          anchorCallId: 'b',
          number: '2001',
          displayName: contact.displayTitle,
        ),
      ),
    ).called(1);
    expect(picking.state.purpose, isNull);
    verify(() => router.maybePop()).called(1);
  });

  testWidgets('a contact whose numbers come down to one is called at once', (tester) async {
    final contact = _contact(phones: const [('1001', 'ext'), ('1001', 'sms')]);
    await pumpRow(tester, contact);

    await tester.tap(find.text(contact.displayTitle));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier(destinationNumberPickerId), findsNothing);
    verify(
      () => callBloc.add(
        CallControlEvent.attendedTransferCallPlaced(
          anchorCallId: 'b',
          number: '1001',
          displayName: contact.displayTitle,
        ),
      ),
    ).called(1);
  });
}

Contact _contact({required List<(String, String)> phones}) => Contact(
  id: 1,
  sourceType: ContactSourceType.external,
  kind: ContactKind.visible,
  sourceId: 'user-1',
  firstName: 'Clara',
  phones: [
    for (final (index, (number, label)) in phones.indexed)
      ContactPhone(id: index, number: number, label: label, favorite: false),
  ],
);
