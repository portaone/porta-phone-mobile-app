import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/voicemail/bloc/voicemail_cubit.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Repository extends Mock implements VoicemailRepository {}

Voicemail _voicemail(String id) =>
    Voicemail(id, '2026-09-15T10:00:00Z', 1, '101', '101', '102', ReadStatus.unread, 1, 'voice', null);

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
    cubit = VoicemailCubit(repository: repository, onCallStarted: (_) {}, onSubmitNotification: (_) {});
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
}
