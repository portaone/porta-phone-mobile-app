import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_callkeep_ios/src/common/converters.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

CallkeepIOSOptions _options({bool? holdActiveBeforeThirdIncoming}) => holdActiveBeforeThirdIncoming == null
    ? const CallkeepIOSOptions(
        localizedName: 'app',
        maximumCallGroups: 13,
        maximumCallsPerCallGroup: 13,
        supportedHandleTypes: {CallkeepHandleType.number},
      )
    : CallkeepIOSOptions(
        localizedName: 'app',
        maximumCallGroups: 13,
        maximumCallsPerCallGroup: 13,
        supportedHandleTypes: const {CallkeepHandleType.number},
        holdActiveBeforeThirdIncoming: holdActiveBeforeThirdIncoming,
      );

void main() {
  test('the hold before a third call is off unless the app asks for it', () {
    expect(_options().holdActiveBeforeThirdIncoming, isFalse);
    expect(_options().toPigeon().holdActiveBeforeThirdIncoming, isFalse);
  });

  test('the hold before a third call reaches the plugin when the app asks for it', () {
    expect(_options(holdActiveBeforeThirdIncoming: true).toPigeon().holdActiveBeforeThirdIncoming, isTrue);
    expect(
      _options(holdActiveBeforeThirdIncoming: true),
      isNot(_options(holdActiveBeforeThirdIncoming: false)),
      reason: 'the option is part of the options equality, so a change of it re-runs setUp',
    );
  });
}
