import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:webtrit_phone/features/settings/features/diagnostic/diagnostic.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/widgets/diagnostic_network_test_item.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/utils/utils.dart';

CandidateInfo _candidate(IceType type, String address, int port) => CandidateInfo(
  mid: '0',
  type: type,
  transport: IceTransport.values.first,
  network: IceNetwork.values.first,
  address: address,
  port: port,
  generation: 0,
  usernameFragment: 'u',
  priority: '1',
  networkCost: '0',
  foundation: 'f',
  relatedAddress: '',
  relatedPort: 0,
  protocol: 'udp',
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  NetworkTestSummary summary(List<CandidateInfo> candidates) => NetworkTestSummary.of(
    NetworkTesterState(networks: const [ConnectivityResult.wifi], candidates: candidates),
    l10n,
  );

  test('a candidate that changes nothing the row shows leaves the summary equal', () {
    final first = summary([_candidate(IceType.srflx, '203.0.113.7', 5000)]);
    final more = summary([
      _candidate(IceType.srflx, '203.0.113.7', 5000),
      _candidate(IceType.host, '192.168.0.12', 5001),
      _candidate(IceType.srflx, '203.0.113.7', 5002),
    ]);
    expect(more, first);
    expect(more.hashCode, first.hashCode);
  });

  test('a candidate that changes what the row shows makes it another summary', () {
    expect(
      summary([_candidate(IceType.host, '192.168.0.12', 5001)]),
      isNot(summary([_candidate(IceType.srflx, '203.0.113.7', 5000)])),
    );
  });
}
