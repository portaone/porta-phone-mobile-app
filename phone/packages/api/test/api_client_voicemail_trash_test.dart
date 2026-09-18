import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// The trash lives entirely in the request line: which folder is listed, whether
// a delete is the reversible one, and which route puts a message back or clears
// the lot. These pin all four.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  WebtritApiClient clientCapturing(void Function(Request request) onRequest) {
    Future<Response> handler(Request request) async {
      onRequest(request);
      final body = request.url.path.endsWith('/user/voicemails') ? '{"has_new_messages": false, "items": []}' : '{}';
      return Response(body, 200, request: request, headers: const {'content-type': 'application/json'});
    }

    return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
  }

  group('listing a folder', () {
    test('the inbox is the default and names no folder', () async {
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.getUserVoicemailList(token);

      expect(captured.url.queryParameters.containsKey('folder'), isFalse);
    });

    test('an explicit inbox still names no folder', () async {
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.getUserVoicemailList(token, folder: VoicemailFolder.inbox);

      expect(captured.url.queryParameters.containsKey('folder'), isFalse);
    });

    test('the trash is asked for by name', () async {
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.getUserVoicemailList(token, folder: VoicemailFolder.trash);

      expect(captured.url.queryParameters['folder'], 'trash');
    });
  });

  group('deleting', () {
    test('a move to the trash asks for the trash by name', () async {
      // Not the default any more: a delete that says nothing is becoming
      // permanent, so that clients built before the trash existed keep
      // deleting. Saying the word is what keeps the message reachable.
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.deleteUserVoicemail(token, 'vm-1');

      expect(captured.url.path, endsWith('/user/voicemails/vm-1'));
      expect(captured.url.queryParameters['trash'], 'true');
      expect(captured.url.queryParameters.containsKey('permanent'), isFalse);
    });

    test('a permanent delete says that instead', () async {
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.deleteUserVoicemail(token, 'vm-1', permanent: true);

      expect(captured.url.queryParameters['permanent'], 'true');
      expect(captured.url.queryParameters.containsKey('trash'), isFalse);
    });

    test('a backend that does not take the word yet is asked the way it used to be', () async {
      // It refuses the request outright rather than ignoring what it does not
      // know, and a plain delete there still means the trash - so the same
      // intent is spelled the old way rather than reported as a failure.
      final asked = <Uri>[];
      final apiClient = WebtritApiClient.inner(
        Uri.https(authority),
        '',
        httpClient: MockClient((request) async {
          asked.add(request.url);
          if (request.url.queryParameters.containsKey('trash')) {
            return Response(
              jsonEncode({
                'code': 'parameters_validate_issue',
                'details': [
                  {'reason': 'unexpected_field', 'path': 'trash'},
                ],
              }),
              422,
              request: request,
              headers: const {'content-type': 'application/json'},
            );
          }
          return Response('', 204, request: request);
        }),
      );

      await apiClient.deleteUserVoicemail(token, 'vm-1');

      expect(asked, hasLength(2));
      expect(asked.first.queryParameters['trash'], 'true');
      expect(asked.last.queryParameters, isEmpty);
    });

    test('a refusal about anything else is not asked again', () async {
      // Only the one word is worth a second question. Anything else is an
      // answer about the message, and repeating it without the word would be
      // asking a question nobody wanted answered.
      final asked = <Uri>[];
      final apiClient = WebtritApiClient.inner(
        Uri.https(authority),
        '',
        httpClient: MockClient((request) async {
          asked.add(request.url);
          return Response(
            jsonEncode({'code': 'message_not_found'}),
            404,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(apiClient.deleteUserVoicemail(token, 'vm-1'), throwsA(isA<RequestFailure>()));
      expect(asked, hasLength(1));
    });
  });

  test('restoring posts to the message', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.restoreUserVoicemail(token, 'vm-1');

    expect(captured.method.toUpperCase(), 'POST');
    expect(captured.url.path, endsWith('/user/voicemails/vm-1/restore'));
  });

  test('emptying the trash deletes the trash itself, not a message', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.emptyUserVoicemailTrash(token);

    expect(captured.method.toUpperCase(), 'DELETE');
    expect(captured.url.path, endsWith('/user/voicemails/trash'));
  });
}
