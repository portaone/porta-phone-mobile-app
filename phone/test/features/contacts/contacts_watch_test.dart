import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/contacts/contacts.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/feature_access_factories.dart';
import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

import 'package:webtrit_phone/features/contacts/features/contacts_local_tab/view/widgets/widgets.dart';

import 'contacts_tab_harness.dart';

class _MockContactsBloc extends MockBloc<ContactsEvent, ContactsState> implements ContactsBloc {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late ContactsTabHarness harness;
  late _MockContactsBloc contactsBloc;
  late _MockStackRouter router;

  setUpAll(() {
    registerFallbackValue(const ContactsSourceTypeChanged(ContactSourceType.local));
    registerFallbackValue(ContactScreenPageRoute(contactId: 0));
    registerFallbackValue(const CallControlEvent.started(video: false));
  });

  setUp(() {
    harness = ContactsTabHarness();
    contactsBloc = _MockContactsBloc();
    router = _MockStackRouter();
    when(() => router.navigate(any())).thenAnswer((_) async {});
  });

  void shown(ContactSourceType sourceType, {String search = '', bool favorites = false}) {
    whenListen(
      contactsBloc,
      const Stream<ContactsState>.empty(),
      initialState: ContactsState(sourceType: sourceType, search: search, favorites: favorites),
    );
  }

  void external(ContactsExternalTabState state) {
    whenListen(harness.externalBloc, const Stream<ContactsExternalTabState>.empty(), initialState: state);
  }

  void local(ContactsLocalTabState state) {
    whenListen(harness.localBloc, const Stream<ContactsLocalTabState>.empty(), initialState: state);
    when(() => harness.localBloc.refresh()).thenAnswer((_) async {});
  }

  Widget source(BuildContext context, ContactSourceType sourceType, {bool markFavorites = false}) =>
      switch (sourceType) {
        ContactSourceType.local => BlocProvider<ContactsLocalTabBloc>.value(
          value: harness.localBloc,
          child: const ContactsLocalTab(),
        ),
        ContactSourceType.external => BlocProvider<ContactsExternalTabBloc>.value(
          value: harness.externalBloc,
          child: const ContactsExternalTab(),
        ),
      };

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
            child: Provider<FeatureAccess>.value(
              value: featureAccessFor(createMockSystemInfo()),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<ContactsBloc>.value(value: contactsBloc),
                  BlocProvider<CallBloc>.value(value: harness.callBloc),
                  BlocProvider<CallRoutingCubit>.value(value: harness.callRoutingCubit),
                ],
                child: CallControllerScope(
                  controller: CallController(callBloc: harness.callBloc),
                  child: PresenceViewParams(
                    hybridPresenceSupport: false,
                    blfViaSipSupport: false,
                    presenceViaSipSupport: false,
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

  Widget tabbed({List<ContactSourceType> sources = const [ContactSourceType.external, ContactSourceType.local]}) =>
      app(ContactsScreen(watchTitle: 'Contacts', sourceTypes: sources, sourceTypeWidgetBuilder: source));

  final people = [for (var i = 1; i <= 20; i++) buildListContact(id: i, name: 'Person $i')];

  for (final preset in watchPresets) {
    testWidgets('on $preset the book is a list under the title, the search and the chip, no tabs or bar', (
      tester,
    ) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      shown(ContactSourceType.external);
      external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
      local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));

      expect(await pumpCollectingOverflows(tester, tabbed()), isEmpty);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(TabBar), findsNothing);
      final title = tester.getRect(find.text('Contacts'));
      final search = tester.getRect(find.bySemanticsIdentifier(contactsSearchInputId));
      final toolbar = tester.getRect(find.byType(ContactsWatchToolbar));
      final separator = tester.getRect(find.byType(WatchSeparator));
      final chip = tester.getRect(find.byKey(contactsWatchSourceKey));
      final first = tester.getRect(find.byType(ContactsWatchTile).first);
      // The search and the book share one row under the title, the
      // separator under them, then the rows.
      expect(title.bottom, lessThanOrEqualTo(toolbar.top));
      expect((search.center.dy - chip.center.dy).abs(), lessThan(1));
      expect(search.right, lessThanOrEqualTo(chip.left));
      expect(toolbar.bottom, lessThanOrEqualTo(separator.top));
      expect(separator.bottom, lessThanOrEqualTo(first.top));
      expect(find.text('Person 1'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(contactsWatchSourceId)).getSemanticsData().label,
        'Contact source: Cloud PBX',
      );
      handle.dispose();
    });

    testWidgets('on $preset a tap opens the contact\'s page and calls nobody', (tester) async {
      preset.apply(tester);
      shown(ContactSourceType.external);
      external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
      local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));
      await pumpCollectingOverflows(tester, tabbed());

      await tester.tap(find.text('Person 1'));
      await tester.pump();

      final route = verify(() => router.navigate(captureAny())).captured.single as ContactScreenPageRoute;
      expect(route.args?.contactId, 1);
      verifyNever(() => harness.callBloc.add(any()));
    });

    testWidgets('on $preset the book on its way is a loading page that keeps the chip', (tester) async {
      preset.apply(tester);
      shown(ContactSourceType.external);
      external(const ContactsExternalTabState(status: ContactsExternalTabStatus.inProgress));
      local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));

      expect(await pumpCollectingOverflows(tester, tabbed()), isEmpty);

      expect(find.byType(WatchStatePage), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(contactsWatchSourceKey), findsOneWidget);
      expect(find.byKey(contactsSearchInputKey), findsNothing);
    });

    testWidgets('on $preset no access to the phone book says so, opens the settings and keeps the chip', (
      tester,
    ) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      shown(ContactSourceType.local);
      external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
      local(const ContactsLocalTabState(status: ContactsLocalTabStatus.permissionFailure));

      expect(await pumpCollectingOverflows(tester, tabbed()), isEmpty);

      expect(find.text('There are no permissions to get your phone contacts'), findsOneWidget);
      expect(find.bySemanticsIdentifier(contactsLocalGrantAccessId), findsOneWidget);
      final chip = find.bySemanticsIdentifier(contactsWatchSourceId);
      expect(tester.getSemantics(chip).getSemanticsData().label, 'Contact source: Your phone');
      handle.dispose();
    });
  }

  testWidgets('the chip shows the next book through the tabs the phone keeps', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    shown(ContactSourceType.external);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));
    await pumpCollectingOverflows(tester, tabbed());

    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsWatchSourceId));
    await tester.pumpAndSettle();

    verify(() => contactsBloc.add(const ContactsSourceTypeChanged(ContactSourceType.local))).called(1);
    handle.dispose();
  });

  testWidgets('a phone book of only the shared contacts ends with the note that says so', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.local);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    local(ContactsLocalTabState(status: ContactsLocalTabStatus.success, contacts: people, selectionOnly: true));
    await pumpCollectingOverflows(tester, tabbed());

    await tester.scrollUntilVisible(
      find.byType(ContactsSelectionNotice),
      200,
      scrollable: find.descendant(of: find.byType(ContactsLocalTab), matching: find.byType(Scrollable)).first,
    );
    expect(find.byType(ContactsSelectionNotice), findsOneWidget);
  });

  testWidgets('a unified section with no book left shows its favourites, not a blank face', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external);
    await pumpCollectingOverflows(
      tester,
      app(
        ContactsFilterScreen(
          watchTitle: 'Contacts',
          selections: const [ContactsFavoritesSelection()],
          sourceTypeWidgetBuilder: source,
          favoritesWidgetBuilder: (context, {reorderMode = false, onReorderStart, onReorderEnd, watchBody}) =>
              const Text('favourites', key: Key('favourites')),
        ),
      ),
    );

    expect(find.byKey(const Key('favourites')), findsOneWidget);
  });

  Widget unifiedWithFavorites(List<FavoriteWithContact>? favorites) => app(
    ContactsFilterScreen(
      watchTitle: 'Contacts',
      selections: const [ContactsSourceSelection(ContactSourceType.external), ContactsFavoritesSelection()],
      sourceTypeWidgetBuilder: source,
      favoritesWidgetBuilder: (context, {reorderMode = false, onReorderStart, onReorderEnd, watchBody}) =>
          watchBody!(context, favorites, (item, index) => Text(item.favorite.number)),
    ),
  );

  FavoriteWithContact favorite(String number) => (
    favorite: Favorite(
      number: number,
      sourceType: FavoriteSourceType.pbx,
      sourceId: number,
      label: 'work',
      position: 0,
    ),
    contact: null,
  );

  testWidgets('the favourites of a unified section are one more list of the chip, under the same row', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external, favorites: true);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    expect(
      await pumpCollectingOverflows(tester, unifiedWithFavorites([favorite('555008'), favorite('555004')])),
      isEmpty,
    );

    expect(find.text('Contacts'), findsOneWidget);
    expect(find.bySemanticsIdentifier(contactsSearchInputId), findsOneWidget);
    expect(find.byType(WatchSeparator), findsOneWidget);
    expect(find.text('555008'), findsOneWidget);
    final chip = find.bySemanticsIdentifier(contactsWatchSourceId);
    expect(tester.getSemantics(chip).getSemanticsData().label, 'Contact source: Favorites');
    await tapViaSemantics(tester, chip);

    verify(
      () => contactsBloc.add(const ContactsListSelectionChanged(ContactsSourceSelection(ContactSourceType.external))),
    ).called(1);
    handle.dispose();
  });

  testWidgets('the search narrows the favourites and says when it finds none', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external, favorites: true, search: '5004');
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    await pumpCollectingOverflows(tester, unifiedWithFavorites([favorite('555008'), favorite('555004')]));
    expect(find.text('555004'), findsOneWidget);
    expect(find.text('555008'), findsNothing);

    shown(ContactSourceType.external, favorites: true, search: 'zz');
    await pumpCollectingOverflows(tester, unifiedWithFavorites([favorite('555008')]));
    expect(find.text('No favorites found'), findsOneWidget);
    // The row stays, so the query can be changed.
    expect(find.bySemanticsIdentifier(contactsSearchInputId), findsOneWidget);
  });

  testWidgets('no favourites is the state page of an empty book, the chip under it', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external, favorites: true);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    expect(await pumpCollectingOverflows(tester, unifiedWithFavorites(const [])), isEmpty);

    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.text('Star a contact to add it'), findsOneWidget);
    expect(find.byKey(contactsWatchSourceKey), findsOneWidget);
  });

  testWidgets('a page or dialog over the list takes the search focus, so closing it brings no keyboard', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external, favorites: true);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    await pumpCollectingOverflows(tester, unifiedWithFavorites([favorite('555008')]));

    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsSearchInputId));
    await tester.pump();
    bool focused() => tester.widget<TextField>(find.byKey(contactsSearchInputKey)).focusNode!.hasFocus;
    expect(focused(), isTrue);

    final context = tester.element(find.byType(ContactsWatchToolbar));
    unawaited(showDialog<void>(context: context, useRootNavigator: false, builder: (_) => const Text('over')));
    await tester.pumpAndSettle();
    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    expect(focused(), isFalse);
    handle.dispose();
  });

  testWidgets('one book has no chip', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));

    await pumpCollectingOverflows(tester, tabbed(sources: const [ContactSourceType.external]));

    expect(find.byKey(contactsWatchSourceKey), findsNothing);
    expect(find.byType(ContactsWatchTile), findsWidgets);
  });

  testWidgets('a search that finds nothing keeps its field, so the query can be cleared', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external, search: 'zz');
    external(const ContactsExternalTabState(status: ContactsExternalTabStatus.success, searching: true));
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));

    expect(await pumpCollectingOverflows(tester, tabbed()), isEmpty);

    expect(find.text('No contacts found'), findsOneWidget);
    expect(find.byKey(contactsSearchInputKey), findsOneWidget);
    expect(find.byType(WatchEdgeButton), findsNothing);
  });

  testWidgets('a search that finds nothing while the cloud book syncs keeps its field, not a spinner', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external, search: 'zz');
    external(const ContactsExternalTabState(status: ContactsExternalTabStatus.inProgress, searching: true));
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));

    expect(await pumpCollectingOverflows(tester, tabbed()), isEmpty);

    expect(find.text('No contacts found'), findsOneWidget);
    expect(find.byKey(contactsSearchInputKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('no access to the phone book says so even with contacts read before', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    shown(ContactSourceType.local);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    local(ContactsLocalTabState(status: ContactsLocalTabStatus.permissionFailure, contacts: people));

    await pumpCollectingOverflows(tester, tabbed());

    expect(find.text('There are no permissions to get your phone contacts'), findsOneWidget);
    expect(find.bySemanticsIdentifier(contactsLocalGrantAccessId), findsOneWidget);
    handle.dispose();
  });

  testWidgets('another book shows the query typed in the first one', (tester) async {
    watchPresets.first.apply(tester);
    final states = StreamController<ContactsState>();
    addTearDown(states.close);
    whenListen(contactsBloc, states.stream, initialState: const ContactsState(sourceType: ContactSourceType.external));
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    local(ContactsLocalTabState(status: ContactsLocalTabStatus.success, contacts: people));
    await pumpCollectingOverflows(tester, tabbed());

    // The query reaches the screen's bloc, then the other book is shown.
    states.add(const ContactsState(sourceType: ContactSourceType.external, search: 'Person'));
    await tester.pump();
    states.add(const ContactsState(sourceType: ContactSourceType.local, search: 'Person'));
    await tester.pump();

    final fields = tester.widgetList<EditableText>(find.byType(EditableText, skipOffstage: false));
    expect(fields.map((field) => field.controller.text), everyElement('Person'));
  });

  testWidgets('typing a letter that empties the list keeps the same field, so the keyboard stays', (tester) async {
    watchPresets.first.apply(tester);
    shown(ContactSourceType.external);
    final states = StreamController<ContactsExternalTabState>();
    addTearDown(states.close);
    whenListen(
      harness.externalBloc,
      states.stream,
      initialState: ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people),
    );
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));
    await pumpCollectingOverflows(tester, tabbed());

    await tester.showKeyboard(find.byKey(contactsSearchInputKey));
    final field = tester.state(find.byType(EditableText));
    await tester.enterText(find.byKey(contactsSearchInputKey), 'q');
    states.add(const ContactsExternalTabState(status: ContactsExternalTabStatus.success, searching: true));
    await tester.pump();

    expect(find.text('No contacts found'), findsOneWidget);
    expect(tester.state(find.byType(EditableText)), same(field));
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('the search is a pill: a tap opens the keyboard, the query shows in it, the cross clears it', (
    tester,
  ) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    shown(ContactSourceType.external);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));
    await pumpCollectingOverflows(tester, tabbed());

    final pill = find.bySemanticsIdentifier(contactsSearchInputId);
    expect(tester.getSemantics(pill).getSemanticsData().label, 'Search contacts');
    expect(tester.getSemantics(pill).getSemanticsData().flagsCollection.isTextField, isFalse);
    expect(find.bySemanticsIdentifier(contactsSearchInputClearId), findsNothing);

    await tapViaSemantics(tester, pill);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    tester.testTextInput.enterText('Per');
    await tester.pump();
    // Shown in the pill as it is typed: a Text of its own, not the hidden field.
    expect(
      find.descendant(
        of: find.byType(ContactsWatchToolbar),
        matching: find.byWidgetPredicate((widget) => widget is Text && widget.data == 'Per'),
      ),
      findsOneWidget,
    );
    verify(() => contactsBloc.add(const ContactsSearchChanged('Per'))).called(1);
    // The query takes the row; the book shrinks to a round button beside it,
    // read by the same name.
    final query = tester.getRect(find.bySemanticsIdentifier(contactsSearchInputId));
    final book = tester.getRect(find.byKey(contactsWatchSourceKey));
    expect(query.left, lessThan(book.left));
    expect(query.width, greaterThan(book.width));
    expect(book.width, moreOrLessEquals(book.height, epsilon: 1));
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(contactsWatchSourceId)).getSemanticsData().label,
      'Contact source: Cloud PBX',
    );

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    verify(() => contactsBloc.add(const ContactsSearchSubmitted('Per'))).called(1);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsSearchInputClearId));
    await tester.pump();
    verify(() => contactsBloc.add(const ContactsSearchChanged(''))).called(1);
    expect(tester.getSemantics(pill).getSemanticsData().label, 'Search contacts');
    handle.dispose();
  });

  testWidgets('a failed cloud book offers Refresh on the edge', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    shown(ContactSourceType.external);
    external(const ContactsExternalTabState(status: ContactsExternalTabStatus.failure));
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));
    await pumpCollectingOverflows(tester, tabbed());

    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsWatchRefreshId));

    verify(() => harness.externalBloc.refresh()).called(1);
    handle.dispose();
  });

  testWidgets('the unified screen offers the books on the chip, not the favourites yet', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    shown(ContactSourceType.external);
    external(ContactsExternalTabState(status: ContactsExternalTabStatus.success, contacts: people));
    local(const ContactsLocalTabState(status: ContactsLocalTabStatus.success));
    await pumpCollectingOverflows(
      tester,
      app(
        ContactsFilterScreen(
          watchTitle: 'Contacts',
          selections: const [
            ContactsSourceSelection(ContactSourceType.external),
            ContactsSourceSelection(ContactSourceType.local),
            ContactsFavoritesSelection(),
          ],
          sourceTypeWidgetBuilder: source,
          favoritesWidgetBuilder: (context, {reorderMode = false, onReorderStart, onReorderEnd, watchBody}) =>
              const SizedBox(),
        ),
      ),
    );

    await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsWatchSourceId));

    verify(() => contactsBloc.add(const ContactsListSelectionChanged(ContactsSourceSelection(ContactSourceType.local))))
        .called(1);
    handle.dispose();
  });
}
