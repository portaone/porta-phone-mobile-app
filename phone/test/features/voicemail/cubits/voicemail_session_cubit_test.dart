import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockVoicemailRepository extends Mock implements VoicemailRepository {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

Voicemail _voicemail(String id, {String? forwardedBy}) => Voicemail(
  id: id,
  date: '2026-09-15T10:00:00Z',
  duration: 1,
  sender: '101',
  displaySender: '101',
  receiver: '102',
  status: ReadStatus.unread,
  size: 1,
  type: 'voice',
  url: null,
  forwardedBy: forwardedBy,
);

void main() {
  late StreamController<int> counts;
  late StreamController<List<Voicemail>> mailbox;
  late _MockVoicemailRepository repository;
  late _MockContactsRepository contacts;
  late VoicemailSessionCubit cubit;

  setUpAll(() => registerFallbackValue(ContactSourceType.external));

  setUp(() {
    counts = StreamController<int>.broadcast();
    mailbox = StreamController<List<Voicemail>>.broadcast();
    repository = _MockVoicemailRepository();
    contacts = _MockContactsRepository();
    when(() => repository.isFeatureSupported).thenReturn(true);
    when(() => repository.watchUnreadVoicemailsCount()).thenAnswer((_) => counts.stream);
    when(() => repository.watchVoicemails()).thenAnswer((_) => mailbox.stream);
    when(() => repository.fetchVoicemails()).thenAnswer((_) async {});
    when(() => contacts.getContactBySource(any(), any())).thenAnswer((_) async => null);
    cubit = VoicemailSessionCubit(repository: repository, contactsRepository: contacts)..init();
  });

  tearDown(() async {
    await cubit.close();
    await counts.close();
    await mailbox.close();
  });

  group('the count of waiting messages', () {
    test('is zero until the repository says otherwise', () {
      expect(cubit.state.unreadCount, 0);
    });

    test('follows the count the repository reports, with no screen open', () async {
      final emitted = <int>[];
      cubit.stream.listen((state) => emitted.add(state.unreadCount));

      counts
        ..add(3)
        ..add(1);
      await pumpEventQueue();

      expect(emitted, [3, 1]);
      expect(cubit.state.unreadCount, 1);
    });

    test('stays quiet when the count is unchanged', () async {
      final emitted = <int>[];
      cubit.stream.listen((state) => emitted.add(state.unreadCount));

      counts
        ..add(2)
        ..add(2);
      await pumpEventQueue();

      expect(emitted, [2]);
    });
  });

  group('the stored mailbox', () {
    test('is not followed while no screen is showing it', () async {
      // The query behind it joins the address book and runs again on every
      // write to either; a badge does not need it.
      await pumpEventQueue();

      expect(mailbox.hasListener, isFalse);
      verifyNever(() => repository.watchVoicemails());
    });

    test('is followed from the first screen to the last', () async {
      cubit.attach();
      cubit.attach();
      mailbox.add([_voicemail('1'), _voicemail('2')]);
      await pumpEventQueue();

      expect(cubit.state.items.map((item) => item.id), ['1', '2']);
      // One subscription however many screens there are.
      verify(() => repository.watchVoicemails()).called(1);

      cubit.detach();
      expect(mailbox.hasListener, isTrue);

      cubit.detach();
      expect(mailbox.hasListener, isFalse);
      // What was last seen stays for the next screen to start from.
      expect(cubit.state.items.map((item) => item.id), ['1', '2']);
    });

    test('is picked up again by the next screen', () async {
      cubit.attach();
      cubit.detach();

      cubit.attach();
      mailbox.add([_voicemail('3')]);
      await pumpEventQueue();

      expect(cubit.state.items.map((item) => item.id), ['3']);
    });

    test('arriving says nothing about how the read of it went', () async {
      // The store emits for reasons that are not a read: a write to the
      // address book it is joined with, the cached copy the repository shows
      // before it asks.
      final answer = Completer<void>();
      when(() => repository.fetchVoicemails()).thenAnswer((_) => answer.future);
      cubit.attach();
      final reading = cubit.fetchVoicemails();

      mailbox.add([_voicemail('1')]);
      await pumpEventQueue();

      // A read still out is still out.
      expect(cubit.state.status, VoicemailStatus.loading);

      answer.completeError(Exception('no route to host'));
      await reading;
      mailbox.add([_voicemail('1'), _voicemail('2')]);
      await pumpEventQueue();

      // And one that failed has not become good.
      expect(cubit.state.error, isNotNull);
    });

    test('a forwarded message gets the name the address book knows its forwarder by', () async {
      when(() => contacts.getContactBySource(ContactSourceType.external, 'user-7')).thenAnswer(
        (_) async => Contact(
          id: 1,
          sourceType: ContactSourceType.external,
          kind: ContactKind.visible,
          sourceId: 'user-7',
          aliasName: 'Iryna Shevchuk',
        ),
      );
      cubit.attach();

      mailbox.add([_voicemail('1', forwardedBy: 'user-7'), _voicemail('2', forwardedBy: 'user-9')]);
      await pumpEventQueue();

      // Nobody is behind user-9, so it stays out and the tile shows the id.
      expect(cubit.state.forwarderNames, {'user-7': 'Iryna Shevchuk'});
    });

    // Freshness belongs to the polling registration, which refreshes the
    // repository at the start of the session and every interval after. A
    // session cubit that read on its own would duplicate that.
    test('is never read from the backend unasked', () async {
      cubit.attach();
      await pumpEventQueue();

      verifyNever(() => repository.fetchVoicemails());
      verifyNever(() => repository.refresh());
    });
  });

  group('a backend that serves no voicemail', () {
    // The repository finds this out from its own first read - which polling
    // makes, at a moment of its choosing - keeps it as a flag, and from then
    // on answers every read with nothing instead of an error.
    test('is noticed when a screen opens, however long after the session began', () async {
      expect(cubit.state.isFeatureNotSupported, isFalse);
      when(() => repository.isFeatureSupported).thenReturn(false);

      cubit.attach();

      expect(cubit.state.status, VoicemailStatus.featureNotSupported);
    });

    test('is noticed by a read that came back with nothing', () async {
      when(() => repository.fetchVoicemails()).thenAnswer((_) async {
        when(() => repository.isFeatureSupported).thenReturn(false);
      });

      expect(await cubit.fetchVoicemails(), VoicemailReadOutcome.notSupported);
      expect(cubit.state.status, VoicemailStatus.featureNotSupported);
    });

    test('is not asked for the mailbox again', () async {
      when(() => repository.isFeatureSupported).thenReturn(false);

      expect(await cubit.fetchVoicemails(), VoicemailReadOutcome.notSupported);
      verifyNever(() => repository.fetchVoicemails());
    });

    test('shows no messages, whatever the store still holds', () async {
      when(() => repository.isFeatureSupported).thenReturn(false);
      cubit.attach();

      mailbox.add([_voicemail('1')]);
      await pumpEventQueue();

      expect(cubit.state.status, VoicemailStatus.featureNotSupported);
      expect(cubit.state.items, isEmpty);
    });
  });

  group('a read that was asked for', () {
    test('shows as loading until the backend answers', () async {
      final answer = Completer<void>();
      when(() => repository.fetchVoicemails()).thenAnswer((_) => answer.future);

      final reading = cubit.fetchVoicemails();

      expect(cubit.state.status, VoicemailStatus.loading);

      answer.complete();

      expect(await reading, VoicemailReadOutcome.done);
      expect(cubit.state.status, VoicemailStatus.loaded);
      expect(cubit.state.error, isNull);
    });

    test('that the backend refuses as unsupported is answered as not supported', () async {
      when(() => repository.fetchVoicemails()).thenAnswer(
        (_) => Future.error(
          EndpointNotSupportedException(
            url: Uri(),
            requestId: 'r',
            statusCode: 501,
            recognizedNotSupportedCodes: const [],
          ),
        ),
      );

      expect(await cubit.fetchVoicemails(), VoicemailReadOutcome.notSupported);
      expect(cubit.state.status, VoicemailStatus.featureNotSupported);
    });

    test('that fails is answered rather than thrown, and keeps the reason', () async {
      final failure = Exception('no route to host');
      when(() => repository.fetchVoicemails()).thenAnswer((_) => Future.error(failure));

      expect(await cubit.fetchVoicemails(), VoicemailReadOutcome.failed);
      expect(cubit.state.status, VoicemailStatus.loaded);
      expect(cubit.state.error, failure);
    });

    test('whose answer arrives after the session ended is not an error', () async {
      final answer = Completer<void>();
      when(() => repository.fetchVoicemails()).thenAnswer((_) => answer.future);
      final reading = cubit.fetchVoicemails();

      await cubit.close();
      answer.complete();

      expect(await reading, VoicemailReadOutcome.done);
    });
  });

  test('releases its subscriptions when closed', () async {
    cubit.attach();
    expect(counts.hasListener, isTrue);
    expect(mailbox.hasListener, isTrue);

    await cubit.close();

    expect(counts.hasListener, isFalse);
    expect(mailbox.hasListener, isFalse);
  });
}
