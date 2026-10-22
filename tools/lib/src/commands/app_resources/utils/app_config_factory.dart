import '../constants/constants.dart';
import '../models/build_bundle.dart';

class AppConfigFactory {
  static Map<String, dynamic> createBuildCacheConfig(BundleApplication application, String? keystorePath) {
    if (application.androidVersion?.buildName == null ||
        application.androidVersion?.buildNumber == null ||
        application.iosVersion?.buildName == null ||
        application.iosVersion?.buildNumber == null) {
      throw Exception('Android or iOS version build info is missing.');
    }

    return {
      bundleIdAndroidField: application.androidPlatformId,
      buildNameAndroidField: application.androidVersion?.buildName,
      buildNumberAndroidField: application.androidVersion?.buildNumber,
      bundleIdIosField: application.iosPlatformId,
      buildNameIOSField: application.iosVersion?.buildName,
      buildNumberIOSField: application.iosVersion?.buildNumber,
      if (keystorePath != null) keystorePathField: keystorePath,
    };
  }

  /// The brand's build environment as `dart_define.json`, without the keys it holds no value for.
  ///
  /// A key set to null - or to the word `null`, which a stored environment can hold as text - is
  /// left out rather than written. Written, it reaches every reader as the string `null`: the iOS
  /// build took `WEBTRIT_APP_LINK_DOMAIN=null` for a domain, kept the Associated Domains
  /// entitlement and could not be signed with a profile that has no such capability. Left out, each
  /// reader falls back to its own default, as for a key the brand never set.
  static Map<String, dynamic> createDartDefineEnv(BundleApplication application, String? keystorePath) {
    final env = <String, dynamic>{
      for (final entry in application.environment.entries)
        if (!_holdsNoValue(entry.value)) entry.key: entry.value,
    };
    if (keystorePath != null) {
      env['WEBTRIT_ANDROID_RELEASE_UPLOAD_KEYSTORE_PATH'] = keystorePath;
    }
    return env;
  }

  static bool _holdsNoValue(Object? value) =>
      value == null || (value is String && value.trim().toLowerCase() == 'null');
}
