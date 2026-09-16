import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/voicemail/bloc/bloc.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// Three of the four filters are one stored list with a condition applied, and
// the fourth is a fetch. These pin which is which, and that the ones that cost
// nothing keep costing nothing.
void main() {
  late _Repository repository;
  late StreamController<List<Voicemail>> mailbox;

  setUp(() {
    repository = _Repository();
    mailbox = StreamController<List<Voicemail>>.broadcast();
    when(() => repository.isFeatureSupported).thenReturn(true);
    when(repository.watchVoicemails).thenAnswer((_) => mailbox.stream);
    when(() => repository.fetchVoicemails(localeCode: any(named: 'localeCode'))).thenAnswer((_) async {});
    when(() => repository.fetchTrashedVoicemails(localeCode: any(named: 'localeCode')))
        .thenAnswer((_) async => const []);
  });

  tearDown(() async {
    await mailbox.close();
  });

  VoicemailCubit build({bool saveSupported = true, bool trashSupported = true}) => VoicemailCubit(
    repository: repository,
    onCallStarted: (_) {},
    onSubmitNotification: (_) {},
    saveSupported: saveSupported,
    trashSupported: trashSupported,
  );

  Future<void> deliver(VoicemailCubit cubit, List<Voicemail> items) async {
    mailbox.add(items);
    await pumpEventQueue();
  }

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
      expect(cubit.state.visibleItems, everything);
    });

    test('New shows only what has not been heard', () {
      cubit.setFilter(VoicemailFilter.unheard);

      expect(cubit.state.visibleItems.map((item) => item.id), ['unheard']);
    });

    test('Saved shows only what is kept, and a mailbox that cannot keep counts as not kept', () {
      cubit.setFilter(VoicemailFilter.saved);

      // A null `saved` means the mailbox cannot hold the flag at all, so the
      // message is not kept - it is a message the control does not apply to.
      expect(cubit.state.visibleItems.map((item) => item.id), ['kept']);
    });

    test('the unheard count reads the mailbox, not the current view', () async {
      cubit.setFilter(VoicemailFilter.saved);
      await pumpEventQueue();

      // It is what the New filter is offering, so it has to say the same thing
      // whichever filter happens to be on.
      expect(cubit.state.unheardCount, 1);
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

      expect(cubit.state.visibleItems, trashed);
      expect(cubit.state.items.map((item) => item.id), ['inbox']);
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
  displaySender: '1000',
  receiver: '2000',
  status: status,
  size: 100,
  type: 'audio',
  url: null,
  saved: saved,
);

class _Repository extends Mock implements VoicemailRepository {}
