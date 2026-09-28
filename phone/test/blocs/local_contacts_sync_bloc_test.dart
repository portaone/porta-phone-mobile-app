import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/blocs/local_contacts_sync/local_contacts_sync_bloc.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class MockLocalContactsRepository extends Mock implements LocalContactsRepository {}

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockContactsAgreementStatusRepository extends Mock implements ContactsAgreementStatusRepository {}

final _localContact1 = LocalContact(id: '1', firstName: 'Local', lastName: 'User', phones: const [], emails: const []);

void main() {
  late MockLocalContactsRepository localContactsRepository;
  late MockContactsRepository contactsRepository;
  late MockContactsAgreementStatusRepository contactsAgreementStatusRepository;

  late bool featureEnabled;
  late bool agreementAccepted;
  late bool contactsPermissionGranted;
  late bool requestPermissionResult;

  setUp(() {
    localContactsRepository = MockLocalContactsRepository();
    contactsRepository = MockContactsRepository();
    contactsAgreementStatusRepository = MockContactsAgreementStatusRepository();

    when(() => localContactsRepository.load()).thenAnswer((_) async {});
    when(() => contactsRepository.syncLocalContacts(any())).thenAnswer((_) async {});

    featureEnabled = true;
    agreementAccepted = true;
    contactsPermissionGranted = true;
    requestPermissionResult = true;
  });

  LocalContactsSyncBloc buildBloc() {
    return LocalContactsSyncBloc(
      localContactsRepository: localContactsRepository,
      contactsRepository: contactsRepository,
      contactsAgreementStatusRepository: contactsAgreementStatusRepository,
      isFeatureEnabled: () async => featureEnabled,
      isAgreementAccepted: () async => agreementAccepted,
      isContactsPermissionGranted: () async => contactsPermissionGranted,
      requestContactPermission: () async => requestPermissionResult,
    );
  }

  void setupDelayedStreamEmission(StreamController<List<LocalContact>> controller, List<LocalContact> contacts) {
    Future.delayed(Duration.zero, () {
      controller.add(contacts);
      controller.close();
    });
  }

  group('LocalContactsSyncBloc', () {
    test('initial state is LocalContactsSyncInitial', () {
      expect(buildBloc().state, const LocalContactsSyncInitial());
    });

    group('LocalContactsSyncStarted', () {
      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits ContactsFeatureDisabledException when feature is disabled',
        build: () {
          featureEnabled = false;
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocalContactsSyncStarted()),
        expect: () => [const ContactsFeatureDisabledException()],
      );

      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits ContactsAgreementMissingException when agreement is not accepted',
        build: () {
          agreementAccepted = false;
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocalContactsSyncStarted()),
        expect: () => [const ContactsAgreementMissingException()],
      );

      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits LocalContactsSyncPermissionFailure when permission is not granted',
        build: () {
          contactsPermissionGranted = false;
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocalContactsSyncStarted()),
        expect: () => [const LocalContactsSyncPermissionFailure()],
      );

      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'subscribes to contacts and triggers refresh when all checks pass',
        build: () {
          final controller = StreamController<List<LocalContact>>();
          when(() => localContactsRepository.contacts()).thenAnswer((_) => controller.stream);
          setupDelayedStreamEmission(controller, []);
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocalContactsSyncStarted()),
        wait: const Duration(milliseconds: 50),
        expect: () => [const LocalContactsSyncRefreshInProgress(), const LocalContactsSyncSuccess()],
        verify: (_) {
          verify(() => localContactsRepository.contacts()).called(1);
          verify(() => localContactsRepository.load()).called(1);
        },
      );
    });

    group('LocalContactsSyncRefreshed', () {
      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits PermissionFailure if permission is not granted (without requesting)',
        build: () {
          contactsPermissionGranted = false;
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocalContactsSyncRefreshed()),
        expect: () => [const LocalContactsSyncPermissionFailure()],
      );

      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits RefreshInProgress then nothing if load succeeds',
        build: () {
          when(() => localContactsRepository.contacts()).thenAnswer((_) => Stream.empty());
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocalContactsSyncRefreshed()),
        expect: () => [const LocalContactsSyncRefreshInProgress()],
        verify: (_) => verify(() => localContactsRepository.load()).called(1),
      );

      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits RefreshFailure if repository load throws',
        build: () {
          when(() => localContactsRepository.contacts()).thenAnswer((_) => Stream.empty());
          when(() => localContactsRepository.load()).thenThrow(Exception('Load error'));
          return buildBloc();
        },
        act: (bloc) => bloc.add(LocalContactsSyncRefreshed()),
        expect: () => [const LocalContactsSyncRefreshInProgress(), const LocalContactsSyncRefreshFailure()],
      );
    });

    group('refresh()', () {
      /// Tracks whether [future] has completed, without awaiting it.
      bool Function() completion(Future<void> future) {
        var done = false;
        future.then((_) => done = true);
        return () => done;
      }

      Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

      test('completes when a gate turns down a refresh whose state is already current', () async {
        contactsPermissionGranted = false;
        final bloc = buildBloc();
        addTearDown(bloc.close);

        await bloc.refresh();
        expect(bloc.state, const LocalContactsSyncPermissionFailure());

        // The same state again: the bloc drops the emit, so nothing on the
        // stream could end this wait.
        final emitted = <LocalContactsSyncState>[];
        final subscription = bloc.stream.listen(emitted.add);
        addTearDown(subscription.cancel);

        await bloc.refresh().timeout(const Duration(seconds: 1));
        expect(emitted, isEmpty);
      });

      test('completes once the device contacts are read, not before', () async {
        final load = Completer<void>();
        when(() => localContactsRepository.contacts()).thenAnswer((_) => const Stream.empty());
        when(() => localContactsRepository.load()).thenAnswer((_) => load.future);
        final bloc = buildBloc();
        addTearDown(bloc.close);

        final done = completion(bloc.refresh());
        await settle();
        expect(bloc.state, const LocalContactsSyncRefreshInProgress());
        expect(done(), isFalse);

        load.complete();
        await settle();
        expect(done(), isTrue);
      });

      test('completes when the load fails', () async {
        when(() => localContactsRepository.contacts()).thenAnswer((_) => const Stream.empty());
        when(() => localContactsRepository.load()).thenThrow(Exception('Load error'));
        final bloc = buildBloc();
        addTearDown(bloc.close);

        await bloc.refresh().timeout(const Duration(seconds: 1));
        expect(bloc.state, const LocalContactsSyncRefreshFailure());
      });

      test('a call made while a refresh runs is not dropped, and both complete', () async {
        final deviceContacts = StreamController<List<LocalContact>>.broadcast();
        addTearDown(deviceContacts.close);
        final load = Completer<void>();
        when(() => localContactsRepository.contacts()).thenAnswer((_) => deviceContacts.stream);
        when(() => localContactsRepository.load()).thenAnswer((_) async {
          await load.future;
          deviceContacts.add([_localContact1]);
        });
        final bloc = buildBloc();
        addTearDown(bloc.close);

        final first = completion(bloc.refresh());
        await settle();
        final second = completion(bloc.refresh());
        await settle();
        expect([first(), second()], [false, false]);

        load.complete();
        await settle();
        expect([first(), second()], [true, true]);
        verify(() => localContactsRepository.load()).called(2);
      });

      test('completes at once on a closed bloc', () async {
        final bloc = buildBloc();
        await bloc.close();

        await bloc.refresh().timeout(const Duration(seconds: 1));
      });
    });

    group('Logic updates from Stream (_LocalContactsSyncUpdated)', () {
      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'emits Success when contacts repository syncs successfully',
        build: () {
          final controller = StreamController<List<LocalContact>>();
          when(() => localContactsRepository.contacts()).thenAnswer((_) => controller.stream);
          setupDelayedStreamEmission(controller, [_localContact1]);
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocalContactsSyncStarted()),
        wait: const Duration(milliseconds: 100),
        expect: () => [const LocalContactsSyncRefreshInProgress(), const LocalContactsSyncSuccess()],
        verify: (_) => verify(() => contactsRepository.syncLocalContacts([_localContact1])).called(1),
      );

      blocTest<LocalContactsSyncBloc, LocalContactsSyncState>(
        'triggers syncLocalContacts and handles errors',
        build: () {
          final controller = StreamController<List<LocalContact>>();
          when(() => localContactsRepository.contacts()).thenAnswer((_) => controller.stream);
          when(() => contactsRepository.syncLocalContacts(any())).thenThrow(Exception('Sync error'));
          setupDelayedStreamEmission(controller, [_localContact1]);
          return buildBloc();
        },
        act: (bloc) => bloc.add(const LocalContactsSyncStarted()),
        wait: const Duration(milliseconds: 100),
        verify: (_) => verify(() => contactsRepository.syncLocalContacts(any())).called(1),
      );
    });
  });
}
