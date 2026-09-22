import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';
import 'package:webtrit_phone/utils/core_support.dart';

final _logger = Logger('FeatureAccessStreamFactory');

class FeatureAccessStreamFactory {
  final AppThemes appThemes;
  final SystemInfoRepository systemInfoRepository;
  final RemoteConfigService remoteConfigService;
  final AppPreferences appPreferences;
  final SessionRepository sessionRepository;

  FeatureAccessStreamFactory({
    required this.appThemes,
    required this.systemInfoRepository,
    required this.remoteConfigService,
    required this.appPreferences,
    required this.sessionRepository,
  }) {
    _startupOverrides = FeatureOverridesFactory.create(remoteConfigService.startupSnapshot);
    _startupAnonymizationEnabled = LoggingMapper.map(appThemes.appConfig, _startupOverrides).anonymizationEnabled;
  }

  late final FeatureOverrides _startupOverrides;
  late final bool _startupAnonymizationEnabled;

  Future<FeatureAccess> getInitialSnapshot() async {
    final systemInfo = await systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheOnly);
    return _build(systemInfo, remoteConfigService.snapshot);
  }

  Stream<FeatureAccess> create() async* {
    final initialSystemInfo = await systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheOnly);
    final initialConfig = remoteConfigService.snapshot;

    yield* CombineLatestStream.combine2<WebtritSystemInfo?, RemoteConfigSnapshot, FeatureAccess>(
      systemInfoRepository.infoStream.cast<WebtritSystemInfo?>().startWith(initialSystemInfo),
      remoteConfigService.onConfigUpdated.startWith(initialConfig),
      (systemInfo, remoteConfig) {
        _logger.info('Updating FeatureAccess from reactive stream');
        return _build(systemInfo, remoteConfig);
      },
    );
  }

  FeatureAccess _build(WebtritSystemInfo? systemInfo, RemoteConfigSnapshot remoteConfig) {
    final coreSupport = CoreSupportFactory.create(systemInfo);
    final overrides = _applySessionPrivacyPolicy(FeatureOverridesFactory.create(remoteConfig));

    return FeatureAccess.create(
      appThemes.appConfig,
      appThemes.embeddedResources,
      coreSupport,
      systemInfo,
      overrides,
      callCenterAgent: _callCenterAgent(),
    );
  }

  /// What the backend last answered about this account being an agent.
  ///
  /// False for an account it has never answered for: a section that turns out
  /// to lead nowhere is worse than one that appears at the next start.
  bool _callCenterAgent() {
    final userId = sessionRepository.getCurrent().userId;
    if (userId.isEmpty) return false;

    return appPreferences.getCallCenterAgent(userId) ?? false;
  }

  FeatureOverrides _applySessionPrivacyPolicy(FeatureOverrides current) {
    final remoteLoggingEnabled = _startupOverrides.remoteLoggingEnabled == true
        ? current.remoteLoggingEnabled ?? false
        : false;
    final isLogAnonymizationEnabled = _startupAnonymizationEnabled && current.isLogAnonymizationEnabled == false
        ? true
        : current.isLogAnonymizationEnabled;

    return current.copyWith(
      remoteLoggingEnabled: remoteLoggingEnabled,
      isLogAnonymizationEnabled: isLogAnonymizationEnabled,
    );
  }
}
