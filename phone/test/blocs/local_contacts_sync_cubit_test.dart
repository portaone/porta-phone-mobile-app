import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/blocs/local_contacts_sync/local_contacts_sync_cubit.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/repositories/contacts/local_contacts_repository_html.dart' as web;

class _MockDeviceRepository extends Mock implements ILocalContactsRepository {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

final _first = [LocalContact(id: 'first', phones: const [], emails: const [])];
final _latest = [LocalContact(id: 'latest', phones: const [], emails: const [])];

class _Harness {
  _Harness() {
    when(() => device.watchChanges()).thenAnswer((_) => changes.stream);
    when(() => device.fetchContacts()).thenAnswer((_) => read());
    when(() => store.syncLocalContacts(any())).thenAnswer(_sync);
    cubit = LocalContactsSyncCubit(
      localContactsRepository: device,
      contactsRepository: store,
      isFeatureEnabled: () => feature(),
      isAgreementAccepted: () => agreement(),
      contactsAccess: () async => await permission() ? access : ContactsAccess.none,
    );
  }

  final device = _MockDeviceRepository();
  final store = _MockContactsRepository();
  final changes = StreamController<void>.broadcast(sync: true);
  final writes = <List<LocalContact>>[];
  late final LocalContactsSyncCubit cubit;

  Future<bool> Function() feature = () async => true;
  Future<bool> Function() agreement = () async => true;
  Future<bool> Function() permission = () async => true;
  ContactsAccess access = ContactsAccess.all;
  Future<List<LocalContact>> Function() read = () async => _first;
  Future<void> Function() write = () async {};

  Future<void> _sync(Invocation invocation) {
    writes.add(invocation.positionalArguments.single as List<LocalContact>);
    return write();
  }

  Future<void> close() async {
    await cubit.close();
    await changes.close();
  }
}

void _check(void Function(FakeAsync, _Harness) body) {
  fakeAsync((async) {
    final harness = _Harness();
    try {
      body(async, harness);
    } finally {
      unawaited(harness.close());
      async.flushMicrotasks();
    }
  });
}

void main() {
  test('starts idle without reading or subscribing', () {
    _check((async, h) {
      expect(h.cubit.state, const LocalContactsSyncInitial());
      verifyNever(() => h.device.fetchContacts());
      expect(h.changes.hasListener, isFalse);
    });
  });

  for (final gate in ['feature', 'agreement', 'permission']) {
    test('repeated $gate refusal completes even without a new state', () {
      _check((async, h) {
        final expected = switch (gate) {
          'feature' => const ContactsFeatureDisabledException(),
          'agreement' => const ContactsAgreementMissingException(),
          _ => const LocalContactsSyncPermissionFailure(),
        };
        switch (gate) {
          case 'feature':
            h.feature = () async => false;
          case 'agreement':
            h.agreement = () async => false;
          case 'permission':
            h.permission = () async => false;
        }
        unawaited(h.cubit.refresh());
        async.flushMicrotasks();
        final states = <LocalContactsSyncState>[];
        h.cubit.stream.listen(states.add);
        var completed = false;
        unawaited(h.cubit.refresh().then((_) => completed = true));
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(h.cubit.state, expected);
        expect(states, isEmpty);
        expect(h.changes.hasListener, isFalse);
        verifyNever(() => h.device.fetchContacts());
      });
    });

    test('$gate check errors settle as refresh failures', () {
      _check((async, h) {
        Future<bool> fail() async => throw StateError('Gate failed');
        switch (gate) {
          case 'feature':
            h.feature = fail;
          case 'agreement':
            h.agreement = fail;
          case 'permission':
            h.permission = fail;
        }
        var completed = false;
        unawaited(h.cubit.refresh().then((_) => completed = true));
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(h.cubit.state, const LocalContactsSyncRefreshFailure());
        verifyNever(() => h.device.fetchContacts());
      });
    });
  }

  test('a permission granted in settings is picked up on the next refresh', () {
    _check((async, h) {
      h.permission = () async => false;
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      h.permission = () async => true;
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
      expect(h.writes, [_first]);
      expect(h.changes.hasListener, isTrue);
    });
  });

  test('a selection of contacts is read, stored and reported as a selection', () {
    _check((async, h) {
      h.access = ContactsAccess.selected;
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.selected));
      expect(h.writes, [_first]);
      expect(h.changes.hasListener, isTrue);
    });
  });

  test('concurrent callers join one cycle through the read and store commit', () {
    _check((async, h) {
      final read = Completer<List<LocalContact>>();
      final write = Completer<void>();
      h.read = () => read.future;
      h.write = () => write.future;
      var completed = 0;
      unawaited(h.cubit.refresh().then((_) => completed++));
      unawaited(h.cubit.refresh().then((_) => completed++));
      async.flushMicrotasks();
      unawaited(h.cubit.refresh().then((_) => completed++));
      expect(h.writes, isEmpty);
      read.complete(_first);
      async.flushMicrotasks();
      unawaited(h.cubit.refresh().then((_) => completed++));
      expect(completed, 0);
      expect(h.cubit.state, const LocalContactsSyncRefreshInProgress());
      expect(h.writes, [_first]);
      write.complete();
      async.flushMicrotasks();
      expect(completed, 4);
      expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
      verify(() => h.device.fetchContacts()).called(1);
      verify(() => h.device.watchChanges()).called(1);
    });
  });

  test('a later refresh starts a new cycle without resubscribing', () {
    _check((async, h) {
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      expect(h.writes, [_first, _first]);
      verify(() => h.device.watchChanges()).called(1);
    });
  });

  for (final phase in ['read', 'write']) {
    test('device changes during $phase coalesce into a reread and persist the latest snapshot', () {
      _check((async, h) {
        final read = Completer<List<LocalContact>>();
        final write = Completer<void>();
        h.read = () => phase == 'read' ? read.future : Future.value(_first);
        h.write = () => phase == 'write' ? write.future : Future.value();
        var completed = false;
        unawaited(h.cubit.refresh().then((_) => completed = true));
        async.flushMicrotasks();
        h.read = () async => _latest;
        h.changes.add(null);
        h.changes.add(null);
        h.changes.add(null);
        async.flushMicrotasks();
        expect(completed, isFalse);
        verify(() => h.device.fetchContacts()).called(1);
        read.complete(_first);
        write.complete();
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(h.writes, [_first, _latest]);
        expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
        verify(() => h.device.fetchContacts()).called(1);
      });
    });
  }

  test('a device change when idle runs the same gated pipeline', () {
    _check((async, h) {
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      h.permission = () async => false;
      h.changes.add(null);
      async.flushMicrotasks();
      expect(h.cubit.state, const LocalContactsSyncPermissionFailure());
      expect(h.writes, [_first]);
    });
  });

  test('a device change at completion starts another read', () {
    _check((async, h) {
      unawaited(h.cubit.refresh().then((_) => h.changes.add(null)));
      async.flushMicrotasks();
      expect(h.writes, [_first, _first]);
    });
  });

  test('a failed read settles and a later refresh can recover', () {
    _check((async, h) {
      h.read = () => throw StateError('Read failed');
      var completed = false;
      unawaited(h.cubit.refresh().then((_) => completed = true));
      async.flushMicrotasks();
      expect(completed, isTrue);
      expect(h.cubit.state, const LocalContactsSyncRefreshFailure());
      expect(h.writes, isEmpty);
      h.read = () async => _latest;
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      expect(h.writes, [_latest]);
      expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
    });
  });

  test('an invalidation during a failed read still triggers a new snapshot', () {
    _check((async, h) {
      final read = Completer<List<LocalContact>>();
      h.read = () => read.future;
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      h.read = () async => _latest;
      h.changes.add(null);
      read.completeError(Exception('Read failed'));
      async.flushMicrotasks();
      expect(h.writes, [_latest]);
      expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
    });
  });

  for (final recovers in [true, false]) {
    test('store retries are awaited through ${recovers ? 'recovery' : 'final failure'}', () {
      _check((async, h) {
        h.write = () async => throw Exception('Write failed');
        var completed = false;
        unawaited(h.cubit.refresh().then((_) => completed = true));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        expect(h.writes, hasLength(3));
        expect(completed, isFalse);
        if (recovers) h.write = () async {};
        async.elapse(const Duration(seconds: 1));
        expect(completed, isTrue);
        expect(h.writes, hasLength(4));
        expect(
          h.cubit.state,
          recovers
              ? const LocalContactsSyncSuccess(access: ContactsAccess.all)
              : const LocalContactsSyncUpdateFailure(),
        );
        verify(() => h.device.fetchContacts()).called(1);
      });
    });
  }

  for (final failsLate in [false, true]) {
    test('close settles a blocked read and ignores its late ${failsLate ? 'error' : 'result'}', () {
      _check((async, h) {
        final read = Completer<List<LocalContact>>();
        h.read = () => read.future;
        var completed = false;
        unawaited(h.cubit.refresh().then((_) => completed = true));
        async.flushMicrotasks();
        h.changes.add(null);
        unawaited(h.cubit.close());
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(h.cubit.isClosed, isTrue);
        expect(h.changes.hasListener, isFalse);
        if (failsLate) {
          read.completeError(StateError('Late read failure'));
        } else {
          read.complete(_first);
        }
        async.flushMicrotasks();
        expect(h.writes, isEmpty);
        verify(() => h.device.fetchContacts()).called(1);
      });
    });
  }

  test('close settles a blocked gate and prevents a later read', () {
    _check((async, h) {
      final permission = Completer<bool>();
      h.permission = () => permission.future;
      var completed = false;
      unawaited(h.cubit.refresh().then((_) => completed = true));
      async.flushMicrotasks();
      unawaited(h.cubit.close());
      async.flushMicrotasks();
      expect(completed, isTrue);
      permission.complete(true);
      async.flushMicrotasks();
      verifyNever(() => h.device.fetchContacts());
      expect(h.changes.hasListener, isFalse);
    });
  });

  test('close during a write releases callers and prevents retries and rereads', () {
    _check((async, h) {
      final write = Completer<void>();
      h.write = () => write.future;
      var completed = false;
      unawaited(h.cubit.refresh().then((_) => completed = true));
      async.flushMicrotasks();
      h.changes.add(null);
      unawaited(h.cubit.close());
      async.flushMicrotasks();
      expect(completed, isTrue);
      write.completeError(Exception('Late store failure'));
      async.elapse(const Duration(seconds: 5));
      expect(h.writes, [_first]);
      expect(h.cubit.state, const LocalContactsSyncRefreshInProgress());
      verify(() => h.device.fetchContacts()).called(1);
    });
  });

  test('close during retry delay prevents another store attempt', () {
    _check((async, h) {
      h.write = () async => throw Exception('Write failed');
      var completed = false;
      unawaited(h.cubit.refresh().then((_) => completed = true));
      async.flushMicrotasks();
      unawaited(h.cubit.close());
      async.flushMicrotasks();
      expect(completed, isTrue);
      async.elapse(const Duration(seconds: 5));
      expect(h.writes, [_first]);
    });
  });

  test('refresh after close completes without touching dependencies', () {
    _check((async, h) {
      unawaited(h.cubit.close());
      var completed = false;
      unawaited(h.cubit.refresh().then((_) => completed = true));
      async.flushMicrotasks();
      expect(completed, isTrue);
      verifyNever(() => h.device.fetchContacts());
    });
  });

  test('change stream errors are handled and subsequent changes still refresh', () {
    _check((async, h) {
      unawaited(h.cubit.refresh());
      async.flushMicrotasks();
      h.changes.addError(Exception('Observer failed'));
      h.changes.add(null);
      async.flushMicrotasks();
      expect(h.writes, [_first, _first]);
      expect(h.cubit.state, const LocalContactsSyncSuccess(access: ContactsAccess.all));
    });
  });

  test('web repository completes with an empty snapshot without needing an emission', () async {
    final repository = web.LocalContactsRepository();
    expect(await repository.fetchContacts(), isEmpty);
    expect(await repository.watchChanges().toList(), isEmpty);
  });
}
