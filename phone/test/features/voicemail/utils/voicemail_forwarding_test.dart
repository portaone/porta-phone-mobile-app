import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/voicemail/utils/utils.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Repository extends Mock implements VoicemailRepository {}

// Passing a message on, and saying what came of it wherever the person ended
// up: the colleague is chosen two sections away, so by the time the backend
// answers the screen that started this is gone.
void main() {
  late _Repository repository;
  late DestinationPickingCubit picking;
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

  void refuses(Object error) {
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId')))
        .thenAnswer((_) => Future.error(error));
  }

  setUp(() async {
    repository = _Repository();
    picking = DestinationPickingCubit();
    when(() => repository.forwardVoicemail(any(), toUserId: any(named: 'toUserId'))).thenAnswer((_) async => 'fwd_1');
    forwarding = VoicemailForwarding(
      repository: repository,
      picking: picking,
      l10n: await AppLocalizations.delegate.load(const Locale('en')),
    );
  });

  tearDown(() async => picking.close());

  test('a colleague is addressed by the id the backend issued', () async {
    await forwarding.send(message, colleague);

    verify(() => repository.forwardVoicemail('vm-1', toUserId: 'user-7')).called(1);
  });

  test('what arrived is said by name', () async {
    await forwarding.send(message, colleague);

    expect(picking.state.report?.message, 'Forwarded to Iryna Shevchuk');
    expect(picking.state.report?.isFailure, isFalse);
  });

  group('what the backend refused', () {
    test('a recording too big to pass on says so and offers nothing', () async {
      refuses(api.VoicemailForwardAttachmentTooLargeException(url: Uri(), requestId: 'r', statusCode: 413));

      await forwarding.send(message, colleague);

      expect(picking.state.report?.message, 'Message too large to forward');
      expect(picking.state.report?.isRetryable, isFalse);
    });

    test('a backend that does not forward at all can be tried again', () async {
      refuses(
        api.EndpointNotSupportedException(
          url: Uri(),
          requestId: 'r',
          statusCode: 501,
          recognizedNotSupportedCodes: const [],
        ),
      );

      await forwarding.send(message, colleague);

      expect(picking.state.report?.message, 'Forwarding is not available');
      expect(picking.state.report?.isRetryable, isTrue);
    });

    test('and a retry goes to the same colleague without asking again', () async {
      refuses(
        api.EndpointNotSupportedException(
          url: Uri(),
          requestId: 'r',
          statusCode: 501,
          recognizedNotSupportedCodes: const [],
        ),
      );
      await forwarding.send(message, colleague);

      picking.state.report!.onRetry!();
      await pumpEventQueue();

      // The person already chose, and the refusal was not about who.
      verify(() => repository.forwardVoicemail('vm-1', toUserId: 'user-7')).called(2);
    });
  });

  test('a request that never reached the backend is a plain failure', () async {
    refuses(Exception('no route to host'));

    await forwarding.send(message, colleague);

    expect(picking.state.report?.message, 'Could not forward');
    expect(picking.state.report?.isFailure, isTrue);
  });
}
