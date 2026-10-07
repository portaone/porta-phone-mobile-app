import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Client extends Mock implements api.WebtritApiClient {}

// Putting several messages back from the trash. The read that follows a
// restore asks the backend about every message in the mailbox, so what these
// pin is how often it runs: once for the batch, not once per message. The real
// repository and DAO against a client that keeps an inbox and a trash and
// writes down every request it is sent.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late VoicemailRepositoryImpl repository;
  late List<String> inbox;
  late List<String> trash;
  late List<String> requests;
  late Map<String, Object> refusals;
  Object? listFailure;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
    registerFallbackValue(api.VoicemailFolder.inbox);
  });

  api.UserVoicemailSummary summary(String id) => api.UserVoicemailSummary(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 12,
    seen: true,
    size: 100,
    type: 'audio',
  );

  api.UserVoicemail details(String id) => api.UserVoicemail(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 12,
    sender: '1000',
    receiver: '2000',
    seen: true,
    size: 100,
    type: 'audio',
    attachments: const [],
  );

  Future<api.UserVoicemailListResponse> listed(Invocation invocation) async {
    final inTrash = invocation.namedArguments[#folder] == api.VoicemailFolder.trash;
    requests.add(inTrash ? 'list trash' : 'list inbox');
    if (!inTrash && listFailure != null) throw listFailure!;

    return api.UserVoicemailListResponse(
      hasNewMessages: false,
      items: [for (final id in inTrash ? trash : inbox) summary(id)],
    );
  }

  Future<api.UserVoicemail> detailed(Invocation invocation) async {
    final id = invocation.positionalArguments[1] as String;
    requests.add('details $id');
    return details(id);
  }

  Future<void> restored(Invocation invocation) async {
    final id = invocation.positionalArguments[1] as String;
    requests.add('restore $id');
    if (refusals[id] case final refusal?) throw refusal;

    trash.remove(id);
    inbox.insert(0, id);
  }

  /// A mailbox of [inboxSize] messages with [trashSize] more in its trash, and
  /// the repository over it, past the read its constructor starts.
  Future<void> mailbox({required int inboxSize, required int trashSize}) async {
    inbox = [for (var i = 0; i < inboxSize; i++) 'in-$i'];
    trash = [for (var i = 0; i < trashSize; i++) 'tr-$i'];
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      trashSupported: true,
    );
    await pumpEventQueue();
    requests.clear();
  }

  setUp(() {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    requests = [];
    refusals = {};
    listFailure = null;

    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer(listed);
    when(() => client.getUserVoicemail(any(), any(), locale: any(named: 'locale'))).thenAnswer(detailed);
    when(() => client.getVoicemailAttachmentUrl(any(), fileFormat: any(named: 'fileFormat'))).thenReturn('url');
    when(
      () => client.restoreUserVoicemail(
        any(),
        any(),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(restored);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  int count(String kind) => requests.where((request) => request.startsWith(kind)).length;

  Future<List<String>> storedIds() async =>
      (await appDatabase.voicemailDao.getAllVoicemails()).map((voicemail) => voicemail.id).toList();

  api.RequestFailure refused() => api.RequestFailure(url: Uri(), requestId: 'request', statusCode: 500);

  test('every message is put back before the mailbox is read, and it is read once', () async {
    await mailbox(inboxSize: 2, trashSize: 3);

    await repository.restoreMultipleVoicemails(['tr-0', 'tr-1']);

    expect(requests, [
      'restore tr-0',
      'restore tr-1',
      'list inbox',
      'details tr-1',
      'details tr-0',
      'details in-0',
      'details in-1',
    ]);
    expect(await storedIds(), unorderedEquals(['tr-0', 'tr-1', 'in-0', 'in-1']));
  });

  test('the read does not grow with the number of messages put back', () async {
    // It used to: a read after each restore made ten messages into a mailbox of
    // thirty cost 375 requests, one after another.
    await mailbox(inboxSize: 30, trashSize: 10);

    await repository.restoreMultipleVoicemails([for (var i = 0; i < 10; i++) 'tr-$i']);

    expect(count('restore'), 10);
    expect(count('list inbox'), 1);
    expect(count('details'), 40);
  });

  test('a message the backend refuses does not stop the rest, and the mailbox is still read once', () async {
    await mailbox(inboxSize: 1, trashSize: 3);
    final refusal = refused();
    refusals['tr-1'] = refusal;

    await expectLater(repository.restoreMultipleVoicemails(['tr-0', 'tr-1', 'tr-2']), throwsA(same(refusal)));

    expect(count('restore'), 3);
    expect(count('list inbox'), 1);
    // What did come back is in the stored list, although the batch reports a refusal.
    expect(await storedIds(), unorderedEquals(['tr-0', 'tr-2', 'in-0']));
  });

  test('a batch that put nothing back does not read the mailbox', () async {
    // Nothing moved, so there is nothing for a read to find out.
    await mailbox(inboxSize: 1, trashSize: 2);
    final offline = Exception('no route to host');
    refusals['tr-0'] = offline;

    await expectLater(repository.restoreMultipleVoicemails(['tr-0', 'tr-1']), throwsA(same(offline)));

    expect(requests, ['restore tr-0']);
  });

  test('a batch cut short still reads the mailbox for what it did put back', () async {
    await mailbox(inboxSize: 1, trashSize: 3);
    final offline = Exception('no route to host');
    refusals['tr-1'] = offline;

    await expectLater(repository.restoreMultipleVoicemails(['tr-0', 'tr-1', 'tr-2']), throwsA(same(offline)));

    expect(requests.take(3), ['restore tr-0', 'restore tr-1', 'list inbox']);
    expect(await storedIds(), unorderedEquals(['tr-0', 'in-0']));
  });

  test('a read that fails after the batch is not a failed restore', () async {
    // The messages are back; saying otherwise would tell the person the
    // opposite of what the backend did.
    await mailbox(inboxSize: 1, trashSize: 2);
    listFailure = Exception('no route to host');

    await repository.restoreMultipleVoicemails(['tr-0', 'tr-1']);

    expect(count('restore'), 2);
    expect(count('list inbox'), 1);
  });

  group('a read already under way when the batch starts restoring', () {
    // Polling does not wait for a restore. A read it starts in the middle of a
    // batch has listed the mailbox before the last message came back, so it
    // cannot be the read the batch ends on - joining it left the restored
    // messages out of the stored list until the next poll.

    /// Restores both trashed messages while another read, started during the
    /// first restore and holding a listing without either, is still running.
    /// [failing] makes that other read fail once it is let go.
    Future<void> restoreAcrossAnotherRead({bool failing = false}) async {
      final restoring = Completer<void>();
      final restoreMayFinish = Completer<void>();
      final otherReadListed = Completer<void>();
      final otherReadMayFinish = Completer<void>();

      when(
        () => client.restoreUserVoicemail(
          any(),
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        if (!restoring.isCompleted) {
          restoring.complete();
          await restoreMayFinish.future;
        }
        await restored(invocation);
      });
      when(() => client.getUserVoicemail(any(), any(), locale: any(named: 'locale'))).thenAnswer((invocation) async {
        if (!otherReadListed.isCompleted) {
          otherReadListed.complete();
          await otherReadMayFinish.future;
          if (failing) throw Exception('no route to host');
        }
        return detailed(invocation);
      });

      final batch = repository.restoreMultipleVoicemails(['tr-0', 'tr-1']);
      await restoring.future;
      final otherRead = repository.refresh().catchError((Object _) {});
      await otherReadListed.future;

      restoreMayFinish.complete();
      await pumpEventQueue();
      otherReadMayFinish.complete();
      await Future.wait([batch, otherRead]);
    }

    test('the batch ends on a read of its own, with every restored message stored', () async {
      await mailbox(inboxSize: 1, trashSize: 2);

      await restoreAcrossAnotherRead();

      expect(count('list inbox'), 2);
      expect(await storedIds(), unorderedEquals(['tr-0', 'tr-1', 'in-0']));
    });

    test('the other read failing neither fails the restore nor stands in for its read', () async {
      await mailbox(inboxSize: 1, trashSize: 2);

      await restoreAcrossAnotherRead(failing: true);

      expect(count('list inbox'), 2);
      expect(await storedIds(), unorderedEquals(['tr-0', 'tr-1', 'in-0']));
    });
  });

  test('one message put back on its own is still followed by a read', () async {
    await mailbox(inboxSize: 1, trashSize: 1);

    await repository.restoreVoicemail('tr-0');

    expect(requests, ['restore tr-0', 'list inbox', 'details tr-0', 'details in-0']);
  });
}
