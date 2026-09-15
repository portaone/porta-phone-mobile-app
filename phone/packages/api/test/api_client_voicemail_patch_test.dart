import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// `seen` and `saved` are independent flags, and the body is what carries that
// independence: an attribute nobody changed must not appear in it at all.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  WebtritApiClient clientCapturing(void Function(Request request) onRequest) {
    Future<Response> handler(Request request) async {
      onRequest(request);
      return Response('{}', 200, request: request, headers: const {'content-type': 'application/json'});
    }

    return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
  }

  Map<String, dynamic> bodyOf(Request request) => jsonDecode(request.body) as Map<String, dynamic>;

  test('a seen-only change carries seen alone', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.updateUserVoicemail(token, 'vm-1', seen: true);

    expect(bodyOf(captured), {'seen': true});
  });

  test('a saved-only change carries saved alone', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.updateUserVoicemail(token, 'vm-1', saved: true);

    expect(bodyOf(captured), {'saved': true});
  });

  test('unsaving is the same call with the flag cleared, not a route of its own', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.updateUserVoicemail(token, 'vm-1', saved: false);

    expect(captured.url.path, endsWith('/user/voicemails/vm-1'));
    expect(bodyOf(captured), {'saved': false});
  });

  test('both can travel together when both are given', () async {
    late Request captured;
    final apiClient = clientCapturing((request) => captured = request);

    await apiClient.updateUserVoicemail(token, 'vm-1', seen: true, saved: false);

    expect(bodyOf(captured), {'seen': true, 'saved': false});
  });

  test('a change with nothing to change is refused rather than sent', () async {
    var requests = 0;
    final apiClient = clientCapturing((_) => requests++);

    expect(() => apiClient.updateUserVoicemail(token, 'vm-1'), throwsArgumentError);
    expect(requests, 0);
  });
}
