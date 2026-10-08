import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// Three of the four filters are one stored list with a condition applied, and
// the fourth is a fetch. These pin which is which, and that the ones that cost
// nothing keep costing nothing.
void main() {
  late _Repository repository;
  late StreamController<List<Voicemail>> mailbox;
  late VoicemailSessionCubit session;

  setUp(() {
    repository = _Repository();
    mailbox = StreamController<List<Voicemail>>.broadcast();
    when(() => repository.isFeatureSupported).thenReturn(true);
    when(repository.watchVoicemails).thenAnswer((_) => mailbox.stream);
    when(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).thenAnswer((_) async {});
    when(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode')))
        .thenAnswer((_) async => const []);
    when(repository.watchUnreadVoicemailsCount).thenAnswer((_) => const Stream.empty());
    session = VoicemailSessionCubit(repository: repository, contactsRepository: _Contacts())..init();
  });

  tearDown(() async {
    await session.close();
    await mailbox.close();
  });

  VoicemailCubit build({bool saveSupported = true, bool trashSupported = true, bool forwardSupported = true}) =>
      VoicemailCubit(
        repository: repository,
        session: session,
        contactsRepository: _Contacts(),
        onCallStarted: (_) {},
        onSubmitNotification: (_) {},
        saveSupported: saveSupported,
        trashSupported: trashSupported,
        forwardSupported: forwardSupported,
      );

  Future<void> deliver(VoicemailCubit cubit, List<Voicemail> items) async {
    mailbox.add(items);
    await pumpEventQueue();
  }

  group('reading the mailbox as a screen opens', () {
    late List<Object> said;

    VoicemailCubit open() => VoicemailCubit(
      repository: repository,
      session: session,
      contactsRepository: _Contacts(),
      onCallStarted: (_) {},
      onSubmitNotification: said.add,
      saveSupported: true,
      trashSupported: true,
      forwardSupported: true,
    );

    setUp(() => said = []);

    test('the first screen of a session asks for it', () async {
      final cubit = open();
      await pumpEventQueue();

      verify(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).called(1);
      await cubit.close();
    });

    test('a screen opened after that does not ask again', () async {
      // The screen reached from settings is built again on every visit. With
      // the connection down each of those reads would fail the same way, and
      // its sentence would push aside whatever else the person was just told.
      final first = open();
      await pumpEventQueue();
      await first.close();
      clearInteractions(repository);

      final second = open();
      await pumpEventQueue();

      verifyNever(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode')));
      await second.close();
    });

    test('unless the last read failed: then it asks again, and says nothing twice', () async {
      // A poll that finds an empty mailbox writes nothing, so nothing else
      // would ever clear the failure the first read left.
      when(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode')))
          .thenAnswer((_) async => throw Exception('offline'));
      // An empty mailbox: with a list on screen, the list arriving from the
      // store is what clears a failed read, and here nothing arrives.
      final first = open();
      await pumpEventQueue();
      await first.close();
      expect(session.state.error, isNotNull);
      final saidAfterFirst = said.length;
      when(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).thenAnswer((_) async {});
      clearInteractions(repository);

      final second = open();
      await pumpEventQueue();

      verify(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).called(1);
      expect(session.state.error, isNull);
      expect(said.length, saidAfterFirst);
      await second.close();
    });

    test('and a failure of that second read is not said again either', () async {
      when(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode')))
          .thenAnswer((_) async => throw Exception('offline'));
      // An empty mailbox: with a list on screen, the list arriving from the
      // store is what clears a failed read, and here nothing arrives.
      final first = open();
      await pumpEventQueue();
      await first.close();
      expect(session.state.error, isNotNull);
      final saidAfterFirst = said.length;

      final second = open();
      await pumpEventQueue();

      expect(said.length, saidAfterFirst);
      await second.close();
    });

    test('a pull to refresh always reads', () async {
      final first = open();
      await pumpEventQueue();
      await first.close();
      final second = open();
      await pumpEventQueue();
      clearInteractions(repository);

      await second.refresh();

      verify(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).called(1);
      await second.close();
    });
  });

  group('which filters are offered', () {
    test('a mailbox that does everything offers all four', () {
      expect(build().state.filters, VoicemailFilter.values);
    });

    test('no save means no Saved filter', () {
      // Absent rather than disabled: a list the backend cannot serve would come
      // back empty for a reason the person cannot see.
      expect(build(saveSupported: false).state.filters, isNot(contains(VoicemailFilter.saved)));
    });

    test('no trash means no Trash filter', () {
      expect(build(trashSupported: false).state.filters, isNot(contains(VoicemailFilter.trash)));
    });

    test('a plain mailbox still offers All and New', () {
      expect(build(saveSupported: false, trashSupported: false).state.filters, [
        VoicemailFilter.all,
        VoicemailFilter.unheard,
      ]);
    });
  });

  group('what each filter shows', () {
    late VoicemailCubit cubit;
    final everything = [
      _voicemail('heard'),
      _voicemail('unheard', status: ReadStatus.unread),
      _voicemail('kept', saved: true),
      _voicemail('unkept', saved: false),
      _voicemail('cannot-be-kept'),
    ];

    setUp(() async {
      cubit = build();
      await deliver(cubit, everything);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('All shows the whole mailbox', () {
      expect(cubit.view.visibleItems, everything);
    });

    test('New shows only what has not been heard', () {
      cubit.setFilter(VoicemailFilter.unheard);

      expect(cubit.view.visibleItems.map((item) => item.id), ['unheard']);
    });

    test('Saved shows only what is kept, and a mailbox that cannot keep counts as not kept', () {
      cubit.setFilter(VoicemailFilter.saved);

      // A null `saved` means the mailbox cannot hold the flag at all, so the
      // message is not kept - it is a message the control does not apply to.
      expect(cubit.view.visibleItems.map((item) => item.id), ['kept']);
    });

    test('the unheard count reads the mailbox, not the current view', () async {
      cubit.setFilter(VoicemailFilter.saved);
      await pumpEventQueue();

      // It is what the New filter is offering, so it has to say the same thing
      // whichever filter happens to be on.
      expect(cubit.view.unheardCount, 1);
    });
  });

  group('the trash', () {
    test('switching to it fetches it, and the mailbox is not touched', () async {
      final trashed = [_voicemail('trashed')];
      when(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode')))
          .thenAnswer((_) async => trashed);
      final cubit = build();
      await deliver(cubit, [_voicemail('inbox')]);
      clearInteractions(repository);

      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();

      expect(cubit.view.visibleItems, trashed);
      expect(session.state.items.map((item) => item.id), ['inbox']);
      verify(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode'))).called(1);
      verifyNever(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode')));

      await cubit.close();
    });

    test('leaving it drops the copy that was read', () async {
      when(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode')))
          .thenAnswer((_) async => [_voicemail('trashed')]);
      final cubit = build();
      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();

      cubit.setFilter(VoicemailFilter.all);

      // Coming back has to show the trash as it is now. It is the list most
      // likely to have been changed from somewhere else in the meantime, so a
      // stale copy here is worse than a moment of loading.
      expect(cubit.state.trashedItems, isEmpty);

      await cubit.close();
    });

    test('a refresh on the trash re-reads the trash, and elsewhere the mailbox', () async {
      final cubit = build();
      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();
      clearInteractions(repository);

      await cubit.refresh();

      verify(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode'))).called(1);
      verifyNever(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode')));

      cubit.setFilter(VoicemailFilter.all);
      await cubit.refresh();

      verify(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).called(1);

      await cubit.close();
    });
  });

  group('a message heard by listening to it under New', () {
    late VoicemailCubit cubit;
    final first = _voicemail('first', status: ReadStatus.unread);
    final second = _voicemail('second', status: ReadStatus.unread);

    /// What the mailbox reads once the backend has taken the mark.
    Voicemail heard(Voicemail voicemail) => _voicemail(voicemail.id);

    setUp(() async {
      when(() => repository.updateVoicemailSeenStatus(any(), any())).thenAnswer((_) async {});
      cubit = build();
      await deliver(cubit, [first, second]);
      cubit.setFilter(VoicemailFilter.unheard);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('stays listed', () async {
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);

      // Playing a message is what marks it heard. Dropped from New at that
      // moment, it would take its player with it and never be listened to.
      expect(cubit.view.visibleItems.map((item) => item.id), ['first', 'second']);
      // The count is of what is still new, and that message is not.
      expect(cubit.view.unheardCount, 1);
      verify(() => repository.updateVoicemailSeenStatus('first', true)).called(1);
    });

    test('and so does the one listened to after it', () async {
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);
      await cubit.markHeardByListening(second);
      await deliver(cubit, [heard(first), heard(second)]);

      // Going through what is new, one message after another: starting the
      // second must not take the first from the list.
      expect(cubit.view.visibleItems.map((item) => item.id), ['first', 'second']);
    });

    test('a message marked heard from the menu leaves New at once', () async {
      await cubit.toggleSeenStatus(first);
      await deliver(cubit, [heard(first), second]);

      expect(cubit.view.visibleItems.map((item) => item.id), ['second']);
    });

    test('and so does one that was listened to before the menu was used on it', () async {
      // The mark made by playing did not go through - the mailbox still lists
      // the message as new - and the person then marks it by hand.
      await cubit.markHeardByListening(first);
      await cubit.toggleSeenStatus(first);
      await deliver(cubit, [heard(first), second]);

      // What is said by hand is the last word: listening earlier must not
      // keep a message under New that the person has just marked heard.
      expect(cubit.view.visibleItems.map((item) => item.id), ['second']);
    });

    test('stays when an action on another message finds that one gone', () async {
      when(() => repository.removeVoicemail('second'))
          .thenThrow(VoicemailMessageGoneException(url: Uri(), requestId: 'r', statusCode: 404));
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);

      await cubit.removeVoicemail('second');
      await deliver(cubit, [heard(first)]);

      // The list is read again because of the other message. That is no
      // reason to take the one being listened to off it.
      expect(cubit.view.visibleItems.map((item) => item.id), ['first']);
    });

    test('leaves New when the filter changes', () async {
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);

      cubit.setFilter(VoicemailFilter.all);
      cubit.setFilter(VoicemailFilter.unheard);

      expect(cubit.view.visibleItems.map((item) => item.id), ['second']);
    });

    test('leaves New on a refresh', () async {
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);

      await cubit.refresh();

      // Asking for the list again is asking what is new now.
      expect(cubit.view.visibleItems.map((item) => item.id), ['second']);
    });

    test('leaves New and the selection when it is let go of', () async {
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);
      cubit.toggleSelection(heard(first));
      cubit.toggleSelection(second);

      cubit.forgetHeardByListening();

      expect(cubit.view.visibleItems.map((item) => item.id), ['second']);
      // A bulk action must not reach a message nobody is looking at.
      expect(cubit.state.selectedVoicemailsIds, ['second']);
    });

    test('is not remembered when it was listened to under another filter', () async {
      cubit.setFilter(VoicemailFilter.all);
      await cubit.markHeardByListening(first);
      await deliver(cubit, [heard(first), second]);

      cubit.setFilter(VoicemailFilter.unheard);

      // New never showed it as new to this person, so it has no place there.
      expect(cubit.view.visibleItems.map((item) => item.id), ['second']);
    });

    test('a message that was already heard is not marked again', () async {
      await cubit.markHeardByListening(heard(first));

      verifyNever(() => repository.updateVoicemailSeenStatus(any(), any()));
      expect(cubit.state.heardByListening, isEmpty);
    });
  });

  test('changing the filter drops the selection', () async {
    final cubit = build();
    final items = [_voicemail('one'), _voicemail('two')];
    await deliver(cubit, items);
    cubit.toggleSelection(items.first);

    cubit.setFilter(VoicemailFilter.unheard);

    // The selection was made over a list that is no longer on screen, so acting
    // on it would act on messages the person can no longer see.
    expect(cubit.state.selectedVoicemailsIds, isEmpty);

    await cubit.close();
  });

  test('picking the filter that is already on does nothing', () async {
    final cubit = build();
    cubit.setFilter(VoicemailFilter.trash);
    await pumpEventQueue();
    clearInteractions(repository);

    cubit.setFilter(VoicemailFilter.trash);
    await pumpEventQueue();

    verifyNever(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode')));

    await cubit.close();
  });
}

Voicemail _voicemail(String id, {ReadStatus status = ReadStatus.read, bool? saved}) => Voicemail(
  id: id,
  date: '2026-09-15T10:00:00Z',
  duration: 10,
  sender: '1000',
  receiver: '2000',
  status: status,
  size: 100,
  type: 'audio',
  url: null,
  saved: saved,
);

class _Repository extends Mock implements VoicemailRepository {}

class _Contacts extends Mock implements ContactsRepository {}
