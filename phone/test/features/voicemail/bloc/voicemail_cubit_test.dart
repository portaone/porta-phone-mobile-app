import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/features/voicemail/bloc/voicemail_cubit.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Repository extends Mock implements VoicemailRepository {}

Voicemail _voicemail(String id, {bool? saved}) => Voicemail(
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
);

void main() {
  late _Repository repository;
  late StreamController<List<Voicemail>> voicemails;
  late VoicemailCubit cubit;

  setUp(() {
    repository = _Repository();
    voicemails = StreamController<List<Voicemail>>.broadcast();
    when(() => repository.isFeatureSupported).thenReturn(true);
    when(() => repository.watchVoicemails()).thenAnswer((_) => voicemails.stream);
    when(() => repository.fetchVoicemails()).thenAnswer((_) async {});
    cubit = VoicemailCubit(
      repository: repository,
      onCallStarted: (_) {},
      onSubmitNotification: (_) {},
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
      when(() => repository.updateVoicemailSavedStatus(any(), any())).thenThrow(Exception('refused'));

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

    test('a delete the server refused is reported as not done', () async {
      when(() => repository.removeVoicemail(any())).thenThrow(Exception('refused'));

      expect(await cubit.removeVoicemail('1'), isFalse);
    });

    test('a delete the server took is reported as done', () async {
      when(() => repository.removeVoicemail(any())).thenAnswer((_) async {});

      expect(await cubit.removeVoicemail('1'), isTrue);
    });
  });

  group('forwarding', () {
    void forwardFails(Object error) {
      when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId')))
          .thenAnswer((_) => Future.error(error));
    }

    api.RequestFailure failure(Type type) => switch (type) {
      const (api.VoicemailForwardAttachmentTooLargeException) => api.VoicemailForwardAttachmentTooLargeException(
        url: Uri(),
        requestId: 'r',
        statusCode: 413,
      ),
      const (api.VoicemailForwardLimitReachedException) => api.VoicemailForwardLimitReachedException(
        url: Uri(),
        requestId: 'r',
        statusCode: 422,
      ),
      const (api.VoicemailForwardRecipientNotFoundException) => api.VoicemailForwardRecipientNotFoundException(
        url: Uri(),
        requestId: 'r',
        statusCode: 404,
      ),
      _ => api.EndpointNotSupportedException(
        url: Uri(),
        requestId: 'r',
        statusCode: 501,
        recognizedNotSupportedCodes: const [],
      ),
    };

    test('a copy that reached the colleague is reported as sent', () async {
      when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer((_) async => 'fwd_1');

      expect(await cubit.forwardVoicemail('1', toUserId: 'user-7'), VoicemailForwardOutcome.sent);
      verify(() => repository.forwardVoicemail('1', toUserId: 'user-7')).called(1);
    });

    test('a recording too big to forward says so', () async {
      forwardFails(failure(api.VoicemailForwardAttachmentTooLargeException));

      final outcome = await cubit.forwardVoicemail('1', toUserId: 'user-7');

      expect(outcome, VoicemailForwardOutcome.tooLarge);
      // Retrying sends the same recording, so there is nothing to offer.
      expect(outcome.isRetryable, isFalse);
    });

    test('a colleague who cannot take another one says so', () async {
      forwardFails(failure(api.VoicemailForwardLimitReachedException));

      final outcome = await cubit.forwardVoicemail('1', toUserId: 'user-7');

      expect(outcome, VoicemailForwardOutcome.recipientFull);
      expect(outcome.isRetryable, isFalse);
    });

    test('a backend that does not forward at all says so, and is worth retrying', () async {
      forwardFails(failure(api.EndpointNotSupportedException));

      final outcome = await cubit.forwardVoicemail('1', toUserId: 'user-7');

      expect(outcome, VoicemailForwardOutcome.unavailable);
      expect(outcome.isRetryable, isTrue);
    });

    test('a recipient who is no longer there falls under the one general answer', () async {
      // Past the three specific cases the difference does not change what the
      // person can do about it, so it is not spelled out.
      forwardFails(failure(api.VoicemailForwardRecipientNotFoundException));

      expect(await cubit.forwardVoicemail('1', toUserId: 'user-7'), VoicemailForwardOutcome.failed);
    });

    test('anything else does too', () async {
      forwardFails(Exception('no route to host'));

      final outcome = await cubit.forwardVoicemail('1', toUserId: 'user-7');

      expect(outcome, VoicemailForwardOutcome.failed);
      expect(outcome.isRetryable, isTrue);
    });

    test('a failed forward leaves the screen usable', () async {
      forwardFails(Exception('refused'));

      await cubit.forwardVoicemail('1', toUserId: 'user-7');

      expect(cubit.state.status, VoicemailStatus.loaded);
    });
  });
}
