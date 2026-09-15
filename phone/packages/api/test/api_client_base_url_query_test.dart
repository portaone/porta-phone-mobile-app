import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// A deployment may be configured with a base URL that carries a query of its
// own. It has to survive every call, including the ones that add parameters.
void main() {
  WebtritApiClient clientCapturing(Uri baseUrl, void Function(Request request) onRequest) {
    Future<Response> handler(Request request) async {
      onRequest(request);
      return Response(
        '{"has_new_messages": false, "items": []}',
        200,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    }

    return WebtritApiClient.inner(baseUrl, '', httpClient: MockClient(handler));
  }

  final baseUrl = Uri.https('demo.webtrit.com', '/', {'apikey': 'abc'});

  test('a call that adds nothing keeps what the base URL carries', () async {
    late Request captured;
    final apiClient = clientCapturing(baseUrl, (request) => captured = request);

    await apiClient.getUserVoicemailList('token');

    expect(captured.url.queryParameters['apikey'], 'abc');
  });

  test('a call that adds a parameter keeps it too', () async {
    late Request captured;
    final apiClient = clientCapturing(baseUrl, (request) => captured = request);

    await apiClient.getUserVoicemailList('token', folder: VoicemailFolder.trash);

    expect(captured.url.queryParameters['apikey'], 'abc');
    expect(captured.url.queryParameters['folder'], 'trash');
  });

  test('a plain base URL still produces no query at all', () async {
    late Request captured;
    final apiClient = clientCapturing(Uri.https('demo.webtrit.com'), (request) => captured = request);

    await apiClient.getUserVoicemailList('token');

    expect(captured.url.hasQuery, isFalse);
  });
}
