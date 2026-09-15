import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/voicemail/bloc/voicemail_cubit.dart';
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
}
