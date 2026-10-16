import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../helpers/feature_access_factories.dart';
import '../mocks/feature_access_mocks.dart';

// A start with no system info stored builds a configuration as if the backend
// supported nothing. Its capability checks match those of a backend that
// really supports nothing, so the configuration has to say which it is.
void main() {
  FeatureAccess withoutSystemInfo() {
    final snapshot = MockRemoteConfigSnapshot();
    when(() => snapshot.getBool(any())).thenReturn(null);
    return FeatureAccess.create(
      createMockAppConfig(),
      [createMockTermsResource()],
      CoreSupportFactory.create(null),
      null,
      FeatureOverridesFactory.create(snapshot),
    );
  }

  test('a configuration built with no system info says so', () {
    expect(withoutSystemInfo().hasSystemInfo, isFalse);
  });

  test('a configuration built from system info says so', () {
    expect(featureAccessFor(systemInfoWithSupported(const [])).hasSystemInfo, isTrue);
  });

  test('a backend that supports nothing is told apart from no answer at all', () {
    final answered = featureAccessFor(systemInfoWithSupported(const []));
    final unanswered = withoutSystemInfo();

    expect(answered.coreSupport, unanswered.coreSupport);
    expect(answered, isNot(unanswered));
  });
}
