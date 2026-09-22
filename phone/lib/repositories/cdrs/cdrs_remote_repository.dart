import 'package:api/api.dart' show WebtritApiClient, UnauthorizedException;

import 'package:webtrit_phone/app/session/session.dart';
import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

abstract class CdrsRemoteRepository {
  /// Fetches the history of Call Detail Records (CDRs).
  ///
  /// [timeFrom] and [timeTo] are the bounds of the range to report on, and
  /// carry the wire's names deliberately: the server fills in whichever bound
  /// is omitted, and how it fills it in is the adapter's business, not
  /// something a caller can assume. [page] walks pages INSIDE that range.
  ///
  /// [page] - Optional one-based page number.
  /// [limit] - Optional parameter to limit the number of records returned.
  ///
  /// The page carries what the server said about the range it came from, which
  /// is how a caller learns that a range holds more than it asked for.
  Future<CdrHistoryPage> getHistory({DateTime? timeFrom, DateTime? timeTo, int? page, int? limit});
}

class CdrsRemoteRepositoryApiImpl with CdrApiMapper implements CdrsRemoteRepository {
  CdrsRemoteRepositoryApiImpl(this._webtritApiClient, this._token, this._sessionGuard);

  final WebtritApiClient _webtritApiClient;
  final String _token;
  final SessionGuard _sessionGuard;

  @override
  Future<CdrHistoryPage> getHistory({DateTime? timeFrom, DateTime? timeTo, int? page, int? limit}) async {
    try {
      final response = await _webtritApiClient.getCdrHistory(
        _token,
        timeFrom: timeFrom,
        timeTo: timeTo,
        page: page,
        limit: limit,
      );
      return CdrHistoryPage(
        records: response.items.map(cdrFromApi).toList(),
        itemsTotal: response.pagination?.itemsTotal,
      );
    } on UnauthorizedException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    }
  }
}
