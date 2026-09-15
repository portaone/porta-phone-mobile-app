import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Repository extends Mock implements VoicemailRepository {}

// A message waiting for somebody to pass it to. It outlives the voicemail
// screen because the colleague is chosen in the address book, two sections
// away, and the answer has to come back to something that still knows which
// message it was.
void main() {
  late _Repository repository;
  late VoicemailForwardingCubit cubit;

  final message = Voicemail(
    id: 'vm-1',
    date: '2026-09-16T10:00:00Z',
    duration: 10,
    sender: '1000',
    displaySender: '1000',
    receiver: '2000',
    status: ReadStatus.read,
    size: 100,
    type: 'audio',
    url: null,
  );

  Contact colleague({int id = 1, String name = 'Iryna Shevchuk', String sourceId = 'user-7'}) => Contact(
    id: id,
    sourceType: ContactSourceType.external,
    kind: ContactKind.visible,
    sourceId: sourceId,
    isCurrentUser: false,
    aliasName: name,
  );

  setUp(() {
    repository = _Repository();
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer((_) async => 'fwd_1');
    cubit = VoicemailForwardingCubit(repository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('nothing is waiting until one is started', () {
    expect(cubit.state.isForwarding, isFalse);
  });

  test('starting remembers the message', () {
    cubit.start(message);

    expect(cubit.state.pending?.id, 'vm-1');
  });

  test('leaving the address book gives up on it', () {
    cubit.start(message);

    cubit.cancel();

    expect(cubit.state.isForwarding, isFalse);
  });

  test('choosing a colleague sends the waiting message to their account', () async {
    cubit.start(message);

    await cubit.sendTo(colleague());

    verify(() => repository.forwardVoicemail('vm-1', toUserId: 'user-7')).called(1);
    expect(cubit.state.report?.outcome, VoicemailForwardOutcome.sent);
    // Nothing is waiting any more: a second choice would be a second forward.
    expect(cubit.state.isForwarding, isFalse);
  });

  test('choosing with nothing waiting sends nothing', () async {
    await cubit.sendTo(colleague());

    verifyNever(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId')));
  });

  test('a refusal from the backend becomes the outcome it is reported with', () async {
    // Which refusal means what belongs to the extension and is tested there.
    // What matters here is that the answer reaches the report at all.
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer(
      (_) => Future.error(api.VoicemailForwardLimitReachedException(url: Uri(), requestId: 'r', statusCode: 422)),
    );
    cubit.start(message);

    await cubit.sendTo(colleague());

    expect(cubit.state.report?.outcome, VoicemailForwardOutcome.recipientFull);
  });

  test('a request that never reached the backend is a plain failure', () async {
    // A socket that died on the way there says nothing about the message or
    // the colleague, so there is nothing more specific to tell the person.
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId')))
        .thenAnswer((_) => Future.error(const SocketException('no route to host')));
    cubit.start(message);

    await cubit.sendTo(colleague());

    expect(cubit.state.report?.outcome, VoicemailForwardOutcome.failed);
  });

  test('a retry goes to the same colleague without asking again', () async {
    cubit.start(message);
    await cubit.sendTo(colleague());
    final report = cubit.state.report!;

    await cubit.retry(report);

    // The person already chose, and the failure was not about who they chose.
    verify(() => repository.forwardVoicemail('vm-1', toUserId: 'user-7')).called(2);
  });

  test('an outcome is said once and then forgotten', () async {
    cubit.start(message);
    await cubit.sendTo(colleague());
    expect(cubit.state.report, isNotNull);

    cubit.reportShown();

    expect(cubit.state.report, isNull);
  });
}
