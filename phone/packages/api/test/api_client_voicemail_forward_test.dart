import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// Forwarding is the one call that writes into somebody else's mailbox, so what
// it sends and how it reads a refusal both matter more than usual.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  WebtritApiClient clientAnswering(Response Function(Request request) respond) {
    return WebtritApiClient.inner(
      Uri.https(authority),
      '',
      httpClient: MockClient((request) async => respond(request)),
    );
  }

  Response created(Request request, String id) =>
      Response(jsonEncode({'id': id}), 201, request: request, headers: const {'content-type': 'application/json'});

  Response refused(Request request, int status, String code) => Response(
    jsonEncode({'code': code, 'message': code}),
    status,
    request: request,
    headers: const {'content-type': 'application/json'},
  );

  test('posts the recipient and the key, and answers with the new id', () async {
    late Request captured;
    final apiClient = clientAnswering((request) {
      captured = request;
      return created(request, 'fwd_5f1c');
    });

    final id = await apiClient.forwardUserVoicemail(token, 'vm-1', toUserId: '123009', idempotencyKey: 'key-1');

    expect(id, 'fwd_5f1c');
    expect(captured.method.toUpperCase(), 'POST');
    expect(captured.url.path, endsWith('/user/voicemails/vm-1/forward'));
    expect(jsonDecode(captured.body), {'to_user_id': '123009', 'idempotency_key': 'key-1'});
  });

  test('an unknown recipient is told apart from anything else', () async {
    final apiClient = clientAnswering((request) => refused(request, 404, 'recipient_not_found'));

    await expectLater(
      apiClient.forwardUserVoicemail(token, 'vm-1', toUserId: 'nobody', idempotencyKey: 'key-1'),
      throwsA(isA<VoicemailForwardRecipientNotFoundException>()),
    );
  });

  test('a recording too large to copy is told apart', () async {
    final apiClient = clientAnswering((request) => refused(request, 413, 'attachment_too_large'));

    await expectLater(
      apiClient.forwardUserVoicemail(token, 'vm-1', toUserId: '123009', idempotencyKey: 'key-1'),
      throwsA(isA<VoicemailForwardAttachmentTooLargeException>()),
    );
  });

  test('a recipient who can hold no more is told apart', () async {
    final apiClient = clientAnswering((request) => refused(request, 422, 'recipient_forward_limit_reached'));

    await expectLater(
      apiClient.forwardUserVoicemail(token, 'vm-1', toUserId: '123009', idempotencyKey: 'key-1'),
      throwsA(isA<VoicemailForwardLimitReachedException>()),
    );
  });

  test('a deployment that does not offer forwarding reads as unsupported, not as a rejection', () async {
    final apiClient = clientAnswering((request) => refused(request, 501, 'functionality_not_implemented'));

    await expectLater(
      apiClient.forwardUserVoicemail(token, 'vm-1', toUserId: '123009', idempotencyKey: 'key-1'),
      throwsA(isA<EndpointNotSupportedException>()),
    );
  });

  test('another endpoint answering one of those codes is untouched by them', () async {
    // The three codes mean what they mean on the forward route only. Read
    // globally they would rename failures of any endpoint that grew an
    // attachment, so this pins that the mapping does not reach further.
    final apiClient = clientAnswering((request) => refused(request, 413, 'attachment_too_large'));

    await expectLater(
      apiClient.getUserVoicemailList(token),
      throwsA(allOf(isA<RequestFailure>(), isNot(isA<VoicemailForwardAttachmentTooLargeException>()))),
    );
  });

  test('a message that is not there stays a plain failure', () async {
    final apiClient = clientAnswering((request) => refused(request, 404, 'message_not_found'));

    await expectLater(
      apiClient.forwardUserVoicemail(token, 'vm-1', toUserId: '123009', idempotencyKey: 'key-1'),
      throwsA(
        allOf(
          isA<RequestFailure>(),
          isNot(isA<VoicemailForwardRecipientNotFoundException>()),
          isNot(isA<EndpointNotSupportedException>()),
        ),
      ),
    );
  });
}
