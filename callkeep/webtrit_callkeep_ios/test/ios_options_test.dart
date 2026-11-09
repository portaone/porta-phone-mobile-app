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

const _plain = CallkeepIOSOptions(
  localizedName: 'app',
  maximumCallGroups: 13,
  maximumCallsPerCallGroup: 13,
  supportedHandleTypes: {CallkeepHandleType.number},
);

const _keeping = CallkeepIOSOptions(
  localizedName: 'app',
  maximumCallGroups: 13,
  maximumCallsPerCallGroup: 13,
  supportedHandleTypes: {CallkeepHandleType.number},
  keepIncomingInAppInFront: true,
);

void main() {
  test('an incoming call is kept in the app in front only when the app asks for it', () {
    expect(_plain.keepIncomingInAppInFront, isFalse);
    expect(_plain.toPigeon().keepIncomingInAppInFront, isFalse);
    expect(_keeping.toPigeon().keepIncomingInAppInFront, isTrue);
    expect(
      _keeping,
      isNot(_plain),
      reason: 'the option is part of the options equality, so a change of it re-runs setUp',
    );
  });

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
