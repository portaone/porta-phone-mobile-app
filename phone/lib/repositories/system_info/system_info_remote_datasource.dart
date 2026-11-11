import 'dart:async';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';

final _logger = Logger('SystemInfoRepository');

/// Called with every system info the core returns and the tenant URL it was
/// asked at.
typedef SystemInfoFetchedCallback = void Function(WebtritSystemInfo info, Uri tenantUrl);

/// Responsible for fetching [WebtritSystemInfo] from the remote API.
///
/// This datasource acts as a low-level abstraction over the HTTP client,
/// handling the raw request and mapping the response to the domain model
/// via [SystemInfoApiMapper].
class SystemInfoRemoteDatasource with SystemInfoApiMapper implements Disposable {
  SystemInfoRemoteDatasource(this.webtritApiClient, {this.onFetched});

  final WebtritApiClientFactory webtritApiClient;

  /// Told of every successful fetch, the stateless ones of the login flow
  /// included. Remote logging takes its settings from here: it needs them
  /// before the user is signed in, and it needs the address of the core that
  /// sent them, which the cached system info does not keep.
  final SystemInfoFetchedCallback? onFetched;

  /// Retrieves the system information from the backend.
  ///
  /// By default, this utilizes the current configuration of [webtritApiClient].
  ///
  /// Optional parameters [overrideCoreUrl] and [overrideTenantId] can be provided
  /// to force the request to a specific server or tenant. This is typically used
  /// during server discovery or login flows (stateless checks) where the
  /// application session has not yet been established or updated.
  ///
  /// Throws an exception and logs a warning if the API call fails or mapping errors occur.
  Future<WebtritSystemInfo> getSystemInfo({Uri? overrideCoreUrl, String? overrideTenantId}) async {
    try {
      // Creates a client. If overrides are null, the factory uses the default/current configuration.
      final client = webtritApiClient.createWebtritApiClient(coreUrl: overrideCoreUrl, tenantId: overrideTenantId);

      final apiSystemInfo = await client.getSystemInfo();
      final newInfo = systemInfoFromApi(apiSystemInfo);
      _notifyFetched(newInfo, client.tenantUrl);

      return newInfo;
    } catch (e, stackTrace) {
      _logger.warning('Failed to gather system info from remote API', e, stackTrace);
      rethrow;
    }
  }

  void _notifyFetched(WebtritSystemInfo info, Uri tenantUrl) {
    try {
      onFetched?.call(info, tenantUrl);
    } catch (e, stackTrace) {
      // A listener must not turn a good answer of the core into a failure.
      _logger.warning('System info listener failed', e, stackTrace);
    }
  }

  /// Returns the default Core URL currently configured in the API client factory.
  Uri get coreUrl => webtritApiClient.createWebtritApiClient().tenantUrl;

  @override
  Future<void> dispose() async {
    return;
  }
}
