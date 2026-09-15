import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// A backend that creates something answers 201, and the client used to treat
// every status but 200, 204 and 304 as a failure - so a success would arrive as
// a RequestFailure carrying a 2xx, which reads as a server fault. The status
// handling is shared by every call, so any one of them exercises it.
void main() {
  const authority = 'demo.webtrit.com';

  WebtritApiClient clientAnswering(int status, String body) {
    return WebtritApiClient.inner(
      Uri.https(authority),
      '',
      httpClient: MockClient(
        (request) async =>
            Response(body, status, request: request, headers: const {'content-type': 'application/json'}),
      ),
    );
  }

  test('a 201 is a success and its body is decoded', () async {
    final apiClient = clientAnswering(201, '{"has_new_messages": true, "items": []}');

    final response = await apiClient.getUserVoicemailList('token');

    expect(response.hasNewMessages, isTrue);
  });

  test('a status outside the successful set is still a failure', () async {
    final apiClient = clientAnswering(202, '{"has_new_messages": true, "items": []}');

    await expectLater(apiClient.getUserVoicemailList('token'), throwsA(isA<RequestFailure>()));
  });
}
