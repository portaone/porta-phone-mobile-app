import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

class MockWebtritApiClient extends Mock implements api.WebtritApiClient {
  @override
  Future<api.UserVoicemailListResponse> getUserVoicemailList(
    String token, {
    api.VoicemailFolder folder = api.VoicemailFolder.inbox,
    String? locale,
    api.RequestOptions options = const api.RequestOptions(),
  }) async {
    return api.UserVoicemailListResponse(hasNewMessages: false, items: []);
  }

  @override
  Future<void> deleteUserVoicemail(
    String token,
    String messageId, {
    bool permanent = false,
    String? locale,
    api.RequestOptions options = const api.RequestOptions(),
  }) async {}

  @override
  Future<String> forwardUserVoicemail(
    String token,
    String messageId, {
    required String toUserId,
    required String idempotencyKey,
    String? locale,
    api.RequestOptions options = const api.RequestOptions(),
  }) async {
    return 'fwd_stub';
  }

  @override
  Future<void> restoreUserVoicemail(
    String token,
    String messageId, {
    String? locale,
    api.RequestOptions options = const api.RequestOptions(),
  }) async {}

  @override
  Future<void> emptyUserVoicemailTrash(
    String token, {
    String? locale,
    api.RequestOptions options = const api.RequestOptions(),
  }) async {}

  @override
  Future<void> updateUserVoicemail(
    String token,
    String messageId, {
    bool? seen,
    bool? saved,
    String? locale,
    api.RequestOptions options = const api.RequestOptions(),
  }) async {}
}
