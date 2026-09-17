import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/extensions/extensions.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';

// What the backend's refusals mean for a forward. Three of them change what
// the person can do next; the rest do not, and saying them apart would only
// read as noise.
void main() {
  test('a recording too big to pass on', () {
    final failure = VoicemailForwardAttachmentTooLargeException(url: Uri(), requestId: 'r', statusCode: 413);

    expect(failure.voicemailForwardOutcome, VoicemailForwardOutcome.tooLarge);
    expect(failure.voicemailForwardOutcome.isRetryable, isFalse);
  });

  test('a colleague who can hold no more', () {
    final failure = VoicemailForwardLimitReachedException(url: Uri(), requestId: 'r', statusCode: 422);

    expect(failure.voicemailForwardOutcome, VoicemailForwardOutcome.recipientFull);
    expect(failure.voicemailForwardOutcome.isRetryable, isFalse);
  });

  test('a backend that does not forward at all', () {
    final failure = EndpointNotSupportedException(
      url: Uri(),
      requestId: 'r',
      statusCode: 501,
      recognizedNotSupportedCodes: const [],
    );

    expect(failure.voicemailForwardOutcome, VoicemailForwardOutcome.unavailable);
    // Worth another try: the deployment may be answering for a mailbox that
    // is not configured yet rather than one that never will be.
    expect(failure.voicemailForwardOutcome.isRetryable, isTrue);
  });

  test('a mailbox the deployment never set up', () {
    final failure = VoicemailNotConfiguredException(url: Uri(), requestId: 'r', statusCode: 422);

    expect(failure.voicemailForwardOutcome, VoicemailForwardOutcome.unavailable);
  });

  test('anything else, including a colleague who is no longer there', () {
    final failure = VoicemailForwardRecipientNotFoundException(url: Uri(), requestId: 'r', statusCode: 404);

    expect(failure.voicemailForwardOutcome, VoicemailForwardOutcome.failed);
  });
}
