import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/utils/utils.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Repository extends Mock implements VoicemailRepository {}

class _Origin extends PageRouteInfo<void> {
  const _Origin() : super('Origin');
}

class _Contacts extends Mock implements ContactsRepository {}

// Saying what came of passing a message to a colleague, wherever the person
// ended up: the colleague is chosen two sections away, so by the time the
// backend answers the screen that started this can be gone. A refusal is said
// once, with a way to try again; the mark it leaves on the message is the
// session's.
void main() {
  late _Repository repository;
  late DestinationPickingCubit picking;
  late VoicemailSessionCubit session;
  late VoicemailForwarding forwarding;

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

  final colleague = Contact(
    id: 1,
    sourceType: ContactSourceType.external,
    kind: ContactKind.visible,
    sourceId: 'user-7',
    isCurrentUser: false,
    aliasName: 'Iryna Shevchuk',
  );

  setUp(() async {
    repository = _Repository();
    picking = DestinationPickingCubit();
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer((_) async => 'fwd_1');
    session = VoicemailSessionCubit(repository: repository, contactsRepository: _Contacts());
    forwarding = VoicemailForwarding(
      picking: picking,
      session: session,
      l10n: await AppLocalizations.delegate.load(const Locale('en')),
    );
  });

  tearDown(() async {
    await picking.close();
    await session.close();
  });

  test('what arrived is said by name', () async {
    await forwarding.send(message, colleague);

    expect(picking.state.report?.message, 'Forwarded to Iryna Shevchuk');
    expect(picking.state.report?.isFailure, isFalse);
  });

  group('what did not arrive', () {
    void refuses(Object error) {
      when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId')))
          .thenAnswer((_) => Future.error(error));
    }

    test('is said by name with a way to try again, and stays marked on the message', () async {
      refuses(Exception('no route to host'));

      await forwarding.send(message, colleague);

      expect(picking.state.report?.message, "Couldn't forward to Iryna Shevchuk");
      expect(picking.state.report?.isFailure, isTrue);
      expect(picking.state.report?.isRetryable, isTrue);
      expect(
        session.state.forwards['vm-1'],
        VoicemailForwardFailed(outcome: VoicemailForwardOutcome.failed, recipient: colleague),
      );
    });

    test('a recording too big to pass on says so and offers nothing', () async {
      refuses(api.VoicemailForwardAttachmentTooLargeException(url: Uri(), requestId: 'r', statusCode: 413));

      await forwarding.send(message, colleague);

      expect(picking.state.report?.message, 'Message too large to forward');
      expect(picking.state.report?.isRetryable, isFalse);
    });

    test('a retry goes to the same colleague without asking again', () async {
      refuses(Exception('no route to host'));
      await forwarding.send(message, colleague);

      picking.state.report!.onRetry!();
      await pumpEventQueue();

      // The person already chose, and the refusal was not about who.
      verify(() => repository.forwardVoicemail('vm-1', toUserId: 'user-7')).called(2);
    });
  });

  test('a second try while the first is still out sends nothing and says nothing', () async {
    // A refusal can be answered from the sentence that says it and from the
    // menu of the message; both at once must not put two copies in the
    // colleague's mailbox.
    final answer = Completer<String>();
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer((_) => answer.future);
    final first = forwarding.send(message, colleague);

    await forwarding.send(message, colleague);

    verify(() => repository.forwardVoicemail('vm-1', toUserId: 'user-7')).called(1);
    expect(picking.state.report, isNull);

    answer.complete('fwd_1');
    await first;
    expect(picking.state.report?.message, 'Forwarded to Iryna Shevchuk');
  });

  group('a choice still open for the message', () {
    ForwardVoicemailPurpose choiceFor(String messageId) => ForwardVoicemailPurpose(
      announcement: 'Choose who to forward to',
      pickLabel: (name) => 'Forward to $name',
      messageId: messageId,
      origin: const _Origin(),
      onPicked: (_) {},
    );

    test('is closed when the message is sent some other way', () async {
      // Forward is asked for, the lists are left without a choice, and the
      // message is then sent by trying again to whoever it was for. The lists
      // must stop offering to forward a message that is already on its way.
      picking.ask(choiceFor('vm-1'));

      await forwarding.send(message, colleague);

      expect(picking.state.purpose, isNull);
    });

    test('for another message is left standing', () async {
      final other = choiceFor('vm-2');
      picking.ask(other);

      await forwarding.send(message, colleague);

      expect(picking.state.purpose, other);
    });
  });

  test('an answer that arrives after the session ended is not an error', () async {
    await picking.close();

    await forwarding.send(message, colleague);

    expect(picking.state.report, isNull);
  });
}
