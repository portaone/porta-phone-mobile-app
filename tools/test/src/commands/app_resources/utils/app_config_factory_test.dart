import 'package:test/test.dart';

import 'package:webtrit_phone_tools/src/commands/app_resources/models/models.dart';
import 'package:webtrit_phone_tools/src/commands/app_resources/utils/app_config_factory.dart';

/// What a build is given as `dart_define.json`.
///
/// A key the brand holds no value for is left out, so that every reader - the iOS entitlement
/// script, the Android Gradle switches, the app - falls back to its own default instead of reading
/// the word `null` as a value.
void main() {
  Map<String, dynamic> envOf(Map<String, dynamic> environment, {String? keystorePath}) =>
      AppConfigFactory.createDartDefineEnv(BundleApplication(environment: environment), keystorePath);

  test('writes the values the brand set', () {
    final env = envOf({
      'WEBTRIT_APP_LINK_DOMAIN': 'links.brand.example',
      'WEBTRIT_APP_PERIODIC_POLLING': true,
      'WEBTRIT_APP_DEBUG_LEVEL': 'ALL',
    });

    expect(env, {
      'WEBTRIT_APP_LINK_DOMAIN': 'links.brand.example',
      'WEBTRIT_APP_PERIODIC_POLLING': true,
      'WEBTRIT_APP_DEBUG_LEVEL': 'ALL',
    });
  });

  test('leaves out a key set to null, as a value or as the word', () {
    final env = envOf({
      'WEBTRIT_APP_LINK_DOMAIN': 'null',
      'WEBTRIT_APP_GREETING': null,
      'WEBTRIT_APP_SALES_EMAIL': ' NULL ',
      'WEBTRIT_APP_NAME': 'Brand',
    });

    expect(env, {'WEBTRIT_APP_NAME': 'Brand'});
  });

  test('keeps an empty value, which the readers already take as unset', () {
    expect(envOf({'WEBTRIT_APP_LINK_DOMAIN': ''}), {'WEBTRIT_APP_LINK_DOMAIN': ''});
  });

  test('keeps a value that only contains the word', () {
    expect(envOf({'WEBTRIT_APP_GREETING': 'null and void'}), {'WEBTRIT_APP_GREETING': 'null and void'});
  });

  test('adds the keystore path when there is one', () {
    expect(
      envOf({}, keystorePath: '/keys/brand'),
      {'WEBTRIT_ANDROID_RELEASE_UPLOAD_KEYSTORE_PATH': '/keys/brand'},
    );
  });
}
