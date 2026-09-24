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
      // A delete that says nothing is the permanent one, so the trash is what
      // has to be asked for. Saying the word is what keeps the message
      // reachable.
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.deleteUserVoicemail(token, 'vm-1');

      expect(captured.url.path, endsWith('/user/voicemails/vm-1'));
      expect(captured.url.queryParameters['trash'], 'true');
      expect(captured.url.queryParameters.containsKey('permanent'), isFalse);
    });

    test('a permanent delete says nothing at all', () async {
      // There is no parameter for it: a bare DELETE is the permanent one, and
      // a backend refuses `permanent=true` as an unexpected field.
      late Request captured;
      final apiClient = clientCapturing((request) => captured = request);

      await apiClient.deleteUserVoicemail(token, 'vm-1', permanent: true);

      expect(captured.url.path, endsWith('/user/voicemails/vm-1'));
      expect(captured.url.queryParameters, isEmpty);
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
