import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/blocs/local_contacts_sync/local_contacts_sync_bloc.dart';
import 'package:webtrit_phone/features/contacts/contacts.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockLocalContactsRepository extends Mock implements LocalContactsRepository {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockContactsAgreementStatusRepository extends Mock implements ContactsAgreementStatusRepository {}

class _MockContactsBloc extends MockBloc<ContactsEvent, ContactsState> implements ContactsBloc {}

/// The tab over a real [LocalContactsSyncBloc]: the refresh boundary is only
/// as good as what the sync bloc does when a gate turns a refresh down.
void main() {
  setUpAll(() => registerFallbackValue(<LocalContact>[]));

  late _MockLocalContactsRepository localContactsRepository;
  late _MockContactsRepository contactsRepository;
  late _MockContactsBloc contactsBloc;
  late StreamController<List<LocalContact>> deviceContacts;

  setUp(() {
    localContactsRepository = _MockLocalContactsRepository();
    contactsRepository = _MockContactsRepository();
    contactsBloc = _MockContactsBloc();
    deviceContacts = StreamController<List<LocalContact>>.broadcast();
    addTearDown(deviceContacts.close);

    when(() => localContactsRepository.contacts()).thenAnswer((_) => deviceContacts.stream);
    when(() => localContactsRepository.load()).thenAnswer((_) async => deviceContacts.add(const []));
    when(() => contactsRepository.syncLocalContacts(any())).thenAnswer((_) async {});
    when(() => contactsRepository.watchContacts(any(), any())).thenAnswer((_) => Stream.value(const <Contact>[]));
    whenListen(
      contactsBloc,
      const Stream<ContactsState>.empty(),
      initialState: const ContactsState(sourceType: ContactSourceType.local),
    );
  });

  Future<(ContactsLocalTabBloc, LocalContactsSyncBloc)> start({required bool permissionGranted}) async {
    final syncBloc = LocalContactsSyncBloc(
      localContactsRepository: localContactsRepository,
      contactsRepository: contactsRepository,
      contactsAgreementStatusRepository: _MockContactsAgreementStatusRepository(),
      isFeatureEnabled: () async => true,
      isAgreementAccepted: () async => true,
      isContactsPermissionGranted: () async => permissionGranted,
      requestContactPermission: () async => permissionGranted,
    );
    final tabBloc = ContactsLocalTabBloc(
      contactsRepository: contactsRepository,
      contactsSearchBloc: contactsBloc,
      localContactsSyncBloc: syncBloc,
    )..add(const ContactsLocalTabStarted(search: ''));
    syncBloc.add(const LocalContactsSyncStarted());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return (tabBloc, syncBloc);
  }

  test('refresh completes while contacts permission is denied, and closing afterwards throws nothing', () async {
    final (tabBloc, syncBloc) = await start(permissionGranted: false);
    expect(tabBloc.state.status, ContactsLocalTabStatus.permissionFailure);

    final errors = <Object>[];
    await runZonedGuarded(() async {
      await tabBloc.refresh().timeout(const Duration(seconds: 1));
      await tabBloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }, (error, _) => errors.add(error));

    expect(errors, isEmpty);
    await syncBloc.close();
  });

  test('refresh completes with permission granted, and the tab settles on success', () async {
    final (tabBloc, syncBloc) = await start(permissionGranted: true);
    addTearDown(tabBloc.close);
    addTearDown(syncBloc.close);

    await tabBloc.refresh().timeout(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(tabBloc.state.status, ContactsLocalTabStatus.success);
  });
}
