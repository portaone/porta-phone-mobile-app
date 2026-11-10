import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/favorites/favorites.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockFavoritesBloc extends MockBloc<FavoritesEvent, FavoritesState> implements FavoritesBloc {}

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _MockSmsRepository extends Mock implements SmsRepository {}

class _MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

final _jane = Contact(
  id: 7,
  sourceType: ContactSourceType.external,
  sourceId: 'jane',
  kind: ContactKind.visible,
  firstName: 'Jane',
  lastName: 'Smith',
);

FavoriteWithContact _favorite(String number, {Contact? contact, int position = 0}) => (
  favorite: Favorite(
    number: number,
    sourceType: FavoriteSourceType.pbx,
    sourceId: contact?.sourceId ?? number,
    label: 'work',
    position: position,
  ),
  contact: contact,
);

void main() {
  late _MockFavoritesBloc favoritesBloc;
  late _MockCallBloc callBloc;
  late _MockSmsRepository smsRepository;
  late _MockCallRoutingCubit callRoutingCubit;
  late _MockStackRouter router;

  final favorites = [_favorite('1234', contact: _jane), _favorite('+380441234567', position: 1)];

  setUpAll(() {
    registerFallbackValue(CallLogScreenPageRoute(number: ''));
    registerFallbackValue(const CallControlEvent.started(video: false));
    registerFallbackValue(FavoritesRemoved(favorite: favorites.first.favorite));
  });

  setUp(() {
    favoritesBloc = _MockFavoritesBloc();
    callBloc = _MockCallBloc();
    smsRepository = _MockSmsRepository();
    callRoutingCubit = _MockCallRoutingCubit();
    router = _MockStackRouter();
    when(() => router.navigate(any())).thenAnswer((_) async {});
    when(() => callBloc.state).thenReturn(const CallState());
    when(() => smsRepository.watchUserSmsNumbers()).thenAnswer((_) => Stream.value(const []));
    when(() => callRoutingCubit.state).thenReturn(null);
  });

  void shown(List<FavoriteWithContact>? favorites) {
    whenListen(favoritesBloc, const Stream<FavoritesState>.empty(), initialState: FavoritesState(favorites: favorites));
  }

  Widget app(Widget screen) {
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          navigatorObservers: const [],
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: PresenceViewParams(
              hybridPresenceSupport: false,
              blfViaSipSupport: false,
              presenceViaSipSupport: false,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<FavoritesBloc>.value(value: favoritesBloc),
                  BlocProvider<CallBloc>.value(value: callBloc),
                  BlocProvider<CallRoutingCubit>.value(value: callRoutingCubit),
                ],
                child: RepositoryProvider<SmsRepository>.value(
                  value: smsRepository,
                  child: CallControllerScope(
                    controller: CallController(callBloc: callBloc),
                    child: screen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget screen() => app(
    const FavoritesScreen(
      watchTitle: 'Favorites',
      transferEnabled: false,
      videoEnabled: false,
      chatsEnabled: false,
      smssEnabled: false,
      cdrsEnabled: false,
    ),
  );

  for (final preset in watchPresets) {
    testWidgets('on $preset the favourites are rows under the title, with no reorder button', (tester) async {
      preset.apply(tester);
      shown(favorites);
      expect(await pumpCollectingOverflows(tester, screen()), isEmpty);

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.byType(FavoritesWatchTile), findsNWidgets(2));
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.bySemanticsIdentifier(favoritesReorderId), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('on $preset an empty list says how a favourite is added', (tester) async {
      preset.apply(tester);
      shown(const []);
      expect(await pumpCollectingOverflows(tester, screen()), isEmpty);

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.text('Star a contact to add it'), findsOneWidget);
    });
  }

  testWidgets('on its way the list is a loading page', (tester) async {
    watchPresets.first.apply(tester);
    shown(null);
    await tester.pumpWidget(screen());

    expect(find.byType(WatchSpinner), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });

  testWidgets('a tap opens the calls with the number, never a call', (tester) async {
    watchPresets.first.apply(tester);
    shown(favorites);
    await tester.pumpWidget(screen());

    final handle = tester.ensureSemantics();
    await tapViaSemantics(tester, find.bySemanticsLabel('Jane Smith, 1234'));

    verify(() => router.navigate(CallLogScreenPageRoute(number: '1234'))).called(1);
    handle.dispose();
    verifyNever(() => callBloc.add(any()));
  });

  testWidgets('while somebody is being chosen a refused row does nothing, not open its calls', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(favorites);
    await tester.pumpWidget(DestinationPicking(purpose: _OnlyPurpose('+380441234567'), child: screen()));

    final refused = tester.getSemantics(find.byType(FavoritesWatchTile).first);
    expect(refused, isSemantics(hasTapAction: false, hasLongPressAction: false));
    await tester.tap(find.text('Jane Smith'), warnIfMissed: false);
    await tester.longPress(find.text('Jane Smith'), warnIfMissed: false);
    await tester.pumpAndSettle();

    verifyNever(() => router.navigate(any()));
    expect(find.text('Remove from favorites?'), findsNothing);
    handle.dispose();
  });

  testWidgets('a long press removes the favourite only once it is confirmed', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(favorites);
    await tester.pumpWidget(screen());

    expect(
      tester.getSemantics(find.byType(FavoritesWatchTile).first),
      isSemantics(hasLongPressAction: true, onLongPressHint: 'Remove from favorites'),
    );

    await tester.longPress(find.text('Jane Smith'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from favorites?'), findsOneWidget);
    expect(find.text('Jane Smith, 1234'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(confirmDialogNoButtonId));
    await tester.pumpAndSettle();
    verifyNever(() => favoritesBloc.add(any()));

    await tester.longPress(find.text('+380441234567'));
    await tester.pumpAndSettle();
    // A number with no contact is named once.
    expect(find.text('+380441234567'), findsNWidgets(2));
    await tapViaSemantics(tester, find.bySemanticsIdentifier(confirmDialogYesButtonId));
    await tester.pumpAndSettle();
    verify(() => favoritesBloc.add(FavoritesRemoved(favorite: favorites.last.favorite))).called(1);
    handle.dispose();
  });

  testWidgets('a screen that heads the list its own way gets the favourites and their rows', (tester) async {
    watchPresets.first.apply(tester);
    shown(favorites);
    List<FavoriteWithContact>? handed;
    await tester.pumpWidget(
      app(
        FavoritesList(
          watchBody: (context, favorites, tileBuilder) {
            handed = favorites;
            return Column(children: [for (final (index, item) in favorites!.indexed) tileBuilder(item, index)]);
          },
          transferEnabled: false,
          videoEnabled: false,
          chatsEnabled: false,
          smssEnabled: false,
          cdrsEnabled: false,
        ),
      ),
    );

    expect(handed, favorites);
    expect(find.byType(FavoritesWatchTile), findsNWidgets(2));
    expect(find.text('Favorites'), findsNothing);
  });

  test('a search finds a favourite by name or number, ignoring case', () {
    expect(favorites.first.matches('jANE'), isTrue);
    expect(favorites.first.matches('234'), isTrue);
    expect(favorites.first.matches('smith x'), isFalse);
    expect(favorites.last.matches(' '), isTrue);
  });
}

/// Takes one number only, so the other rows are refused.
class _OnlyPurpose implements DestinationPickPurpose {
  _OnlyPurpose(this.number);

  final String number;

  @override
  String get announcement => 'Pick somebody';

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get closedByChoice => true;

  @override
  bool get cancellable => false;

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => candidate.number == number;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Choose ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) {}
}
