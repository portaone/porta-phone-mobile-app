import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/contacts/contacts.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockDeviceRepository extends Mock implements ILocalContactsRepository {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockSearchBloc extends MockBloc<ContactsEvent, ContactsState> implements ContactsBloc {}

ContactsAccess _allContacts() => ContactsAccess.all;

void main() {
  late _MockDeviceRepository device;
  late _MockContactsRepository store;
  late _MockSearchBloc search;

  setUp(() {
    device = _MockDeviceRepository();
    store = _MockContactsRepository();
    search = _MockSearchBloc();
    when(() => device.watchChanges()).thenAnswer((_) => const Stream.empty());
    when(() => device.fetchContacts()).thenAnswer((_) async => const []);
    when(() => store.syncLocalContacts(any())).thenAnswer((_) async {});
    when(() => store.watchContacts(any(), any())).thenAnswer((_) => Stream.value(const <Contact>[]));
    whenListen(
      search,
      const Stream<ContactsState>.empty(),
      initialState: const ContactsState(sourceType: ContactSourceType.local),
    );
  });

  LocalContactsSyncCubit syncCubit(
    Future<bool> Function() permission, {
    ContactsAccess Function() granted = _allContacts,
  }) => LocalContactsSyncCubit(
    localContactsRepository: device,
    contactsRepository: store,
    isFeatureEnabled: () async => true,
    isAgreementAccepted: () async => true,
    contactsAccess: () async => await permission() ? granted() : ContactsAccess.none,
  );

  ContactsLocalTabBloc tabBloc(LocalContactsSyncCubit sync) =>
      ContactsLocalTabBloc(contactsRepository: store, contactsSearchBloc: search, localContactsSyncCubit: sync)
        ..add(const ContactsLocalTabStarted(search: ''));

  testWidgets('repeated resumes with denied permission settle before logout without stream errors', (tester) async {
    var permissionChecks = 0;
    final sync = syncCubit(() async {
      permissionChecks++;
      return false;
    });
    addTearDown(sync.close);
    await sync.refresh();
    final tab = tabBloc(sync);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ContactsLocalTabBloc>(
          create: (_) => tab,
          child: const Scaffold(body: ContactsLocalTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tab.state.status, ContactsLocalTabStatus.permissionFailure);

    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    }
    expect(permissionChecks, 4);
    await tab.refresh();
    expect(tab.state.status, ContactsLocalTabStatus.permissionFailure);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tab.isClosed, isTrue);
    expect(tester.takeException(), isNull);
    verifyNever(() => device.fetchContacts());
  });

  test('tab refresh waits for persistence and survives tab disposal', () async {
    final enteredStore = Completer<void>();
    final releaseStore = Completer<void>();
    when(() => store.syncLocalContacts(any())).thenAnswer((_) {
      enteredStore.complete();
      return releaseStore.future;
    });
    final sync = syncCubit(() async => true);
    addTearDown(sync.close);
    final tab = tabBloc(sync);
    var completed = false;
    final refresh = tab.refresh().then((_) => completed = true);
    await enteredStore.future;
    expect(completed, isFalse);
    expect(sync.state, const LocalContactsSyncRefreshInProgress());

    await tab.close();
    expect(sync.isClosed, isFalse);
    expect(completed, isFalse);
    releaseStore.complete();
    await refresh;
    expect(sync.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
  });

  test('the tab follows the access level across refreshes', () async {
    var access = ContactsAccess.selected;
    final sync = syncCubit(() async => true, granted: () => access);
    addTearDown(sync.close);
    final tab = tabBloc(sync);
    addTearDown(tab.close);

    await tab.refresh();
    await pumpEventQueue();
    expect(tab.state.status, ContactsLocalTabStatus.success);
    expect(tab.state.selectionOnly, isTrue);

    // The user widened the selection to the whole address book in settings.
    access = ContactsAccess.all;
    await tab.refresh();
    await pumpEventQueue();
    expect(tab.state.selectionOnly, isFalse);
  });

  test('a failed pass leaves the selection notice with the list it belongs to', () async {
    final sync = syncCubit(() async => true, granted: () => ContactsAccess.selected);
    addTearDown(sync.close);
    final tab = tabBloc(sync);
    addTearDown(tab.close);
    await tab.refresh();
    await pumpEventQueue();
    expect(tab.state.selectionOnly, isTrue);

    // The stored contacts stay on screen when a later read fails.
    when(() => device.fetchContacts()).thenThrow(StateError('address book unavailable'));
    await tab.refresh();
    await pumpEventQueue();
    expect(tab.state.status, ContactsLocalTabStatus.failure);
    expect(tab.state.selectionOnly, isTrue);
  });

  test('a refusal drops the selection notice', () async {
    var allowed = true;
    final sync = syncCubit(() async => allowed, granted: () => ContactsAccess.selected);
    addTearDown(sync.close);
    final tab = tabBloc(sync);
    addTearDown(tab.close);
    await tab.refresh();
    await pumpEventQueue();
    expect(tab.state.selectionOnly, isTrue);

    allowed = false;
    await tab.refresh();
    await pumpEventQueue();
    expect(tab.state.status, ContactsLocalTabStatus.permissionFailure);
    expect(tab.state.selectionOnly, isFalse);
  });
}
