import 'package:api/api.dart';

import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

/// Remote gateway for the external contact list.
///
/// Deliberately fetch-only: `ExternalContactsSyncWorker` is registered once
/// with the polling service, and manual calls use its owner's runner capability,
/// so the app has no competing download path (see `docs/polling.md`).
///
/// An abstract contract on purpose: the backend serves the list through two
/// API generations - the full-list v1 and the paginated v2 - and each is an
/// implementation of this same gateway. Pagination is an implementation
/// detail: a paged implementation walks its pages internally and still
/// returns the complete list, so the worker never learns which generation
/// it talks to.
abstract class ExternalContactsRepository {
  Future<List<ExternalContact>> fetchContacts();
}

/// The full-list v1 implementation (`GET /user/contacts`).
class ExternalContactsRepositoryV1Impl with ExternalContactApiMapper implements ExternalContactsRepository {
  ExternalContactsRepositoryV1Impl({required WebtritApiClient webtritApiClient, required String token})
    : _webtritApiClient = webtritApiClient,
      _token = token;

  final WebtritApiClient _webtritApiClient;
  final String _token;

  @override
  Future<List<ExternalContact>> fetchContacts() async {
    final contacts = await _webtritApiClient.getUserContactList(_token);
    return contacts.map(externalContactFromApi).toList();
  }
}
