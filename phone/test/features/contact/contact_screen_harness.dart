import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/contact/contact.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';
import 'package:webtrit_phone/utils/utils.dart';

class MockContactBloc extends MockBloc<ContactEvent, ContactState> implements ContactBloc {}

class MockSmsRepository extends Mock implements SmsRepository {}

class MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class MockStackRouter extends Mock implements StackRouter {}

/// The user's own SMS numbers reach the card through a watcher that keeps the
/// first repository it is given for the life of the test file, so every
/// harness of a file shares this one and stubs it anew.
final _smsRepository = MockSmsRepository();

/// Builds a contact the way the screen receives it from the backend.
///
/// [numbers] carry the labels the card sorts by, so passing more than one is
/// how a card with several rows is built.
Contact buildContact({
  String number = '1001',
  String label = 'ext',
  List<ContactPhone> numbers = const [],
  bool favorite = false,
  List<ContactEmail> emails = const [],
  List<SipSubscription> sipSubscriptions = const [],
  ContactSourceType sourceType = ContactSourceType.external,
}) {
  return Contact(
    id: 1,
    sourceType: sourceType,
    kind: ContactKind.visible,
    sourceId: 'user-1',
    userRegistered: true,
    isCurrentUser: false,
    firstName: 'Anna',
    lastName: 'Marchenko',
    phones: numbers.isNotEmpty ? numbers : [ContactPhone(id: 1, number: number, label: label, favorite: favorite)],
    emails: emails,
    sipSubscriptions: sipSubscriptions,
  );
}

/// Everything the contact card needs around it: the blocs it reads, the call
/// controller its actions go through and the presence flags that decide
/// whether the options section exists at all.
class ContactScreenHarness {
  ContactScreenHarness() {
    registerFallbackValue(SmsConversationScreenPageRoute(firstNumber: '', secondNumber: ''));
    withUserSmsNumbers(const []);
    when(() => callBloc.state).thenReturn(const CallState());
    when(() => callRoutingCubit.state).thenReturn(null);
    when(() => router.navigate(any())).thenAnswer((_) async {});
  }

  final contactBloc = MockContactBloc();
  final callBloc = MockCallBloc();
  final callRoutingCubit = MockCallRoutingCubit();
  final router = MockStackRouter();

  /// Puts a call on the line with a blind transfer already started, which is
  /// what turns the call buttons of a row into the transfer shortcut.
  /// Whether the card is being shown to somebody who is choosing a
  /// destination, which is what turns its rows into the choice.
  DestinationPickPurpose? pickPurpose;

  void withBlindTransferUnderWay() {
    pickPurpose = _AnyNumberPurpose();
    final call = ActiveCall(
      callId: 'call-1',
      direction: CallDirection.outgoing,
      line: 0,
      handle: const CallkeepHandle.number('1001'),
      createdTime: DateTime(2024),
      video: false,
      processingStatus: CallProcessingStatus.connected,
      transfer: const Transfer.blindTransferInitiated(),
    );
    when(() => callBloc.state).thenReturn(CallState(activeCalls: [call]));
  }

  /// Numbers the account itself can send an SMS from, as Core gives them over
  /// the messaging socket.
  void withUserSmsNumbers(List<String> numbers) {
    when(() => _smsRepository.watchUserSmsNumbers()).thenAnswer((_) => Stream.value(numbers));
  }

  Future<void> pump(
    WidgetTester tester, {
    required Contact contact,
    bool presenceViaSip = false,
    bool dialogsViaSip = false,
    bool enableTileSms = true,
    bool enableTileEmail = true,
    bool enableTileTransfer = false,
  }) async {
    whenListen(contactBloc, const Stream<ContactState>.empty(), initialState: ContactState(contact: contact));

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ContactBloc>.value(value: contactBloc),
              BlocProvider<CallBloc>.value(value: callBloc),
              BlocProvider<CallRoutingCubit>.value(value: callRoutingCubit),
            ],
            child: CallControllerScope(
              controller: CallController(callBloc: callBloc),
              child: DestinationPicking(
                purpose: pickPurpose,
                child: PresenceViewParams(
                  hybridPresenceSupport: presenceViaSip || dialogsViaSip,
                  blfViaSipSupport: dialogsViaSip,
                  presenceViaSipSupport: presenceViaSip,
                  child: RepositoryProvider<SmsRepository>.value(
                    value: _smsRepository,
                    child: ContactScreen(
                      enableAppBarChat: true,
                      enableTileFavorite: true,
                      enableTileVoiceCall: true,
                      enableTileVideoCall: true,
                      enableTileSms: enableTileSms,
                      enableTileChat: true,
                      enableTileTransfer: enableTileTransfer,
                      enableTileCallLog: true,
                      enableTileEmail: enableTileEmail,
                      useCdrsForHistory: false,
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
}

/// Stands in for whatever is asking. Any number will do, which is what handing
/// a call on needs and the loosest a purpose can be.
class _AnyNumberPurpose implements DestinationPickPurpose {
  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => candidate.number != null;

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => false;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Transfer current call to ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) {}
}
