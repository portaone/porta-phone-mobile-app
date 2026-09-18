import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/bloc/voicemail_cubit.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Repository extends Mock implements VoicemailRepository {}

class _Contacts extends Mock implements ContactsRepository {}

Voicemail _voicemail(String id, {bool? saved, String? forwardedBy}) => Voicemail(
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
  saved: saved,
  forwardedBy: forwardedBy,
);

void main() {
  late _Repository repository;
  late StreamController<List<Voicemail>> voicemails;
  late List<Object> said;
  late VoicemailCubit cubit;

  setUp(() {
    repository = _Repository();
    voicemails = StreamController<List<Voicemail>>.broadcast();
    // What the person would be shown. The channel is the app's notifications
    // bloc in the running app; here it is just a list of what was said.
    said = [];
    when(() => repository.isFeatureSupported).thenReturn(true);
    when(() => repository.watchVoicemails()).thenAnswer((_) => voicemails.stream);
    when(() => repository.fetchVoicemails()).thenAnswer((_) async {});
    cubit = VoicemailCubit(
      repository: repository,
      contactsRepository: _Contacts(),
      onCallStarted: (_) {},
      onSubmitNotification: said.add,
      saveSupported: true,
      trashSupported: true,
      forwardSupported: true,
    );
  });

  tearDown(() async {
    await cubit.close();
    await voicemails.close();
  });

  group('selection', () {
    test('toggleSelection adds a message and removes it again', () {
      final message = _voicemail('1');

      cubit.toggleSelection(message);
      expect(cubit.state.selectedVoicemailsIds, ['1']);
      expect(cubit.state.isMultipleVoicemailsSelection, isTrue);

      cubit.toggleSelection(message);
      expect(cubit.state.selectedVoicemailsIds, isEmpty);
      expect(cubit.state.isMultipleVoicemailsSelection, isFalse);
    });

    test('a message that leaves the list leaves the selection', () async {
      voicemails.add([_voicemail('1'), _voicemail('2'), _voicemail('3')]);
      await pumpEventQueue();
      cubit.toggleSelection(_voicemail('1'));
      cubit.toggleSelection(_voicemail('3'));

      voicemails.add([_voicemail('2'), _voicemail('3')]);
      await pumpEventQueue();

      expect(cubit.state.selectedVoicemailsIds, ['3']);
    });

    test('deleting the selection ends selection mode once the list reflects it', () async {
      when(() => repository.removeMultipleVoicemails(any())).thenAnswer((_) async {});
      voicemails.add([_voicemail('1'), _voicemail('2')]);
      await pumpEventQueue();
      cubit.toggleSelection(_voicemail('1'));
      cubit.toggleSelection(_voicemail('2'));

      cubit.removeSelectedVoicemails();
      await pumpEventQueue();
      voicemails.add(const []);
      await pumpEventQueue();

      verify(() => repository.removeMultipleVoicemails(['1', '2'])).called(1);
      expect(cubit.state.selectedVoicemailsIds, isEmpty);
      expect(cubit.state.isMultipleVoicemailsSelection, isFalse);
    });
  });

  group('keeping a message', () {
    setUp(() {
      when(() => repository.updateVoicemailSavedStatus(any(), any())).thenAnswer((_) async {});
    });

    test('an unkept message is asked to be kept', () async {
      cubit.toggleSavedStatus(_voicemail('1', saved: false));
      await pumpEventQueue();

      verify(() => repository.updateVoicemailSavedStatus('1', true)).called(1);
    });

    test('a kept message is asked to stop being kept', () async {
      cubit.toggleSavedStatus(_voicemail('1', saved: true));
      await pumpEventQueue();

      verify(() => repository.updateVoicemailSavedStatus('1', false)).called(1);
    });

    test('a failure leaves the screen loaded rather than stuck', () async {
      // Refused through the future rather than thrown at the call, because
      // that is how every repository method here fails: they are all async, so
      // the error arrives where the cubit awaits it.
      when(() => repository.updateVoicemailSavedStatus(any(), any()))
          .thenAnswer((_) async => throw Exception('refused'));

      cubit.toggleSavedStatus(_voicemail('1', saved: false));
      await pumpEventQueue();

      // The list is still there and still usable; what did not happen is the
      // one message's flag, which the next refresh reports either way.
      expect(cubit.state.status, VoicemailStatus.loaded);
    });
  });

  group('the trash', () {
    setUp(() {
      when(() => repository.restoreVoicemail(any())).thenAnswer((_) async {});
      when(() => repository.removeVoicemailPermanently(any())).thenAnswer((_) async {});
      when(() => repository.fetchTrashedVoicemails()).thenAnswer((_) async => const []);
    });

    test('restoring while the trash is on screen re-reads the trash', () async {
      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();
      clearInteractions(repository);

      await cubit.restoreVoicemail('1');

      // The restored message is no longer in the trash, and the trash has no
      // stored copy that could be corrected in place.
      verify(() => repository.restoreVoicemail('1')).called(1);
      verify(() => repository.fetchTrashedVoicemails()).called(1);
    });

    test('restoring from the mailbox does not read the trash', () async {
      // Undoing a move to the trash happens on the mailbox view, where there
      // is no trash on screen to correct.
      await cubit.restoreVoicemail('1');

      verify(() => repository.restoreVoicemail('1')).called(1);
      verifyNever(() => repository.fetchTrashedVoicemails());
    });

    test('deleting for good while the trash is on screen re-reads the trash', () async {
      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();
      clearInteractions(repository);

      await cubit.removeVoicemailPermanently('1');

      verify(() => repository.removeVoicemailPermanently('1')).called(1);
      verify(() => repository.fetchTrashedVoicemails()).called(1);
    });

    test('a move to the trash offers the way back', () async {
      when(() => repository.removeVoicemail(any())).thenAnswer((_) async {});

      await cubit.removeVoicemail('1');

      // Said where anything else about the mailbox is said, not by the row -
      // which by then has left the list along with the message.
      expect(said, [isA<VoicemailMovedToTrashNotification>()]);
      (said.single as VoicemailMovedToTrashNotification).onUndo();
      await pumpEventQueue();
      verify(() => repository.restoreVoicemail('1')).called(1);
    });

    test('a delete the server refused offers nothing back', () async {
      // Offering to undo something that never happened is worse than saying
      // nothing: the message is still there and the offer says it is not.
      when(() => repository.removeVoicemail(any())).thenAnswer((_) async => throw Exception('refused'));

      await cubit.removeVoicemail('1');

      expect(said, isEmpty);
    });

    test('a message the backend no longer has says so, and the list is re-read', () async {
      // The one refusal that says something about the state: the list is
      // behind, so it is read again and the row goes with it.
      when(() => repository.removeVoicemail(any()))
          .thenAnswer((_) async => throw RequestFailure(url: Uri(), requestId: 'r', statusCode: 404));
      clearInteractions(repository);

      await cubit.removeVoicemail('1');

      expect(said, [isA<VoicemailMessageGoneNotification>()]);
      verify(() => repository.fetchVoicemails()).called(1);
    });

    test('a server that broke leaves the list exactly as it was', () async {
      // Nothing is known about what happened on the other side, so nothing
      // here is guessed at - re-reading would be inventing an answer. The api
      // names that case, so this is the exception it raises rather than a
      // status read here.
      when(() => repository.removeVoicemail(any()))
          .thenAnswer((_) async => throw ServerFailureException(url: Uri(), requestId: 'r', statusCode: 500));
      clearInteractions(repository);

      await cubit.removeVoicemail('1');

      expect(said, isEmpty);
      verifyNever(() => repository.fetchVoicemails());
      verifyNever(() => repository.fetchTrashedVoicemails());
    });

    test('a restore whose re-read fails is still a restore that happened', () async {
      // The write went through and the read after it did not. Treating that as
      // a failed restore would tell the person the opposite of what the backend
      // did, and offer to put back a message that is already back.
      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();
      when(() => repository.fetchTrashedVoicemails()).thenAnswer((_) async => throw Exception('offline'));

      await cubit.restoreVoicemail('1');

      expect(said, isEmpty);
      verify(() => repository.restoreVoicemail('1')).called(1);
    });

    test('a re-read that answers 404 does not make the message gone', () async {
      // Only a refusal of the action itself says anything about the message.
      // A read that failed afterwards is about the list.
      cubit.setFilter(VoicemailFilter.trash);
      await pumpEventQueue();
      when(() => repository.fetchTrashedVoicemails())
          .thenAnswer((_) async => throw RequestFailure(url: Uri(), requestId: 'r', statusCode: 404));

      await cubit.restoreVoicemail('1');

      expect(said, isEmpty);
    });
  });

  test('the caller of a message is asked for by the number that left it', () async {
    // The mailbox holds the number; the address book holds the card. A screen
    // reaching for a repository itself was how this used to be done.
    final contacts = _Contacts();
    when(() => contacts.getContactByPhoneNumber(any())).thenAnswer((_) async => null);
    final cubit = VoicemailCubit(
      repository: repository,
      contactsRepository: contacts,
      onCallStarted: (_) {},
      onSubmitNotification: said.add,
      saveSupported: true,
      trashSupported: true,
      forwardSupported: true,
    );

    await cubit.callerOf(_voicemail('1'));

    verify(() => contacts.getContactByPhoneNumber('101')).called(1);
    await cubit.close();
  });

  group('who forwarded a message on', () {
    test('a name is looked up once and then reused', () async {
      when(() => repository.resolveForwarderNames(any())).thenAnswer((_) async => {'user-7': 'Iryna Shevchuk'});

      voicemails.add([_voicemail('1', forwardedBy: 'user-7')]);
      await pumpEventQueue();

      expect(cubit.state.forwarderOf(_voicemail('1', forwardedBy: 'user-7')), 'Iryna Shevchuk');

      // The same list arriving again, or another message from the same
      // colleague, costs no second lookup.
      voicemails.add([_voicemail('1', forwardedBy: 'user-7'), _voicemail('2', forwardedBy: 'user-7')]);
      await pumpEventQueue();

      verify(() => repository.resolveForwarderNames(any())).called(1);
    });

    test('a colleague the address book does not know falls back to their id', () async {
      when(() => repository.resolveForwarderNames(any())).thenAnswer((_) async => const {});

      voicemails.add([_voicemail('1', forwardedBy: 'user-9')]);
      await pumpEventQueue();

      // A poor name but a true one. Saying nothing would hide that the message
      // was forwarded at all.
      expect(cubit.state.forwarderOf(_voicemail('1', forwardedBy: 'user-9')), 'user-9');
    });

    test('a list with nothing forwarded asks nobody', () async {
      voicemails.add([_voicemail('1')]);
      await pumpEventQueue();

      verifyNever(() => repository.resolveForwarderNames(any()));
      expect(cubit.state.forwarderOf(_voicemail('1')), isNull);
    });

    test('a lookup that fails leaves the list alone', () async {
      when(() => repository.resolveForwarderNames(any())).thenThrow(Exception('offline'));

      voicemails.add([_voicemail('1', forwardedBy: 'user-7')]);
      await pumpEventQueue();

      expect(cubit.state.items.map((item) => item.id), ['1']);
      expect(cubit.state.forwarderOf(_voicemail('1', forwardedBy: 'user-7')), 'user-7');
    });
  });
}
