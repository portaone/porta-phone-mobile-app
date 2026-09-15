import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// Every voicemail call takes a locale and turns it into an Accept-Language
// header. The helper behind each verb has to carry that header to the request;
// these pin the two verbs where it used to be dropped, with a GET as the
// control that always worked.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';
  const locale = 'uk';

  WebtritApiClient clientCapturing(void Function(Request request) onRequest) {
    Future<Response> handler(Request request) async {
      onRequest(request);
      // The list is the only call here that decodes its body into a model.
      final body = request.url.path.endsWith('/user/voicemails') ? '{"has_new_messages": false, "items": []}' : '{}';
      return Response(body, 200, request: request, headers: const {'content-type': 'application/json'});
    }

    return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
  }

  test('a patch carries the locale', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.updateUserVoicemail(token, 'vm-1', seen: true, locale: locale);

    expect(captured.headers['accept-language'], locale);
  });

  test('a delete carries the locale', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.deleteUserVoicemail(token, 'vm-1', locale: locale);

    expect(captured.headers['accept-language'], locale);
  });

  test('a get carries the locale', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.getUserVoicemailList(token, locale: locale);

    expect(captured.headers['accept-language'], locale);
  });

  test('no locale means no header at all', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.deleteUserVoicemail(token, 'vm-1');

    expect(captured.headers.containsKey('accept-language'), isFalse);
  });
}
