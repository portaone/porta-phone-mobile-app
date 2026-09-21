import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:patrol/patrol.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/extensions/main_flavor.dart';
import 'package:webtrit_phone/features/cdrs/cdrs.dart';
import 'package:webtrit_phone/features/login/view/login_mode_select_screen.dart';
import 'package:webtrit_phone/bootstrap.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import 'components/api_request_log.dart';
import 'components/integration_test_environment_config.dart';
import 'components/render_overflow_tolerance.dart';
import 'subsequences/login_by_method.dart';
import 'subsequences/logout.dart';
import 'subsequences/pump_root_and_wait_until_visible.dart';

const _historyPath = '/api/v1/user/history';
const _gapRecordCount = 3;
const _gapDays = 10;

/// Older history against a backend that volunteers only the recent past - the
/// behaviour of every PortaSwitch deployment with the default window on, and of
/// the local adapter since it was taught the same rules.
///
/// The archive here has one call today and three from ten days ago, with
/// nothing in between. Asking without a range reaches the first and can never
/// reach the rest; the app has to name the range it wants, and walking back is
/// how it finds one that holds something.
void main() {
  const userRef = IntegrationTestEnvironmentConfig.PASSWORD_USER_CREDENTIAL;
  const customCoreUrl = IntegrationTestEnvironmentConfig.CUSTOM_CORE_URL;

  patrolTest('call history older than the default window is reached by walking', ($) async {
    final coreUri = Uri.parse(customCoreUrl);
    expect(
      coreUri.hasScheme && coreUri.host.isNotEmpty && coreUri.port == 4000,
      isTrue,
      reason: 'this test must target the local Core at http://<host>:4000',
    );
    expect(userRef, isNotEmpty, reason: 'PASSWORD_USER_CREDENTIAL must be configured');

    final debugHistoryUri = coreUri.replace(port: 3000, path: '/debug/history', queryParameters: {'user': userRef});
    await _clearHistory(debugHistoryUri);
    addTearDown(() => _clearHistory(debugHistoryUri));

    await _appendRecord(debugHistoryUri, callId: 'walk-today', minutesAgo: 5);
    for (var i = 0; i < _gapRecordCount; i++) {
      await _appendRecord(debugHistoryUri, callId: 'walk-old-$i', minutesAgo: _gapDays * 24 * 60 + i * 60);
    }

    final dependencies = await bootstrap();
    final apiLog = ApiRequestLog()..start();
    addTearDown(apiLog.stop);

    await pumpRootAndWaitUntilVisible(dependencies, $);
    expect($(LoginModeSelectScreen).visible, isTrue, reason: 'the walk scenario needs a fresh local database');
    await tolerateSmallRenderOverflows(() => loginByMethod($, IntegrationTestEnvironmentConfig.DEFAULT_LOGIN_METHOD));

    final recentsNavKey = MainFlavor.recents.toNavBarKey();
    await $(recentsNavKey).waitUntilVisible();
    final shellContext = $.tester.element(find.byKey(recentsNavKey));
    final localRepository = shellContext.read<CdrsLocalRepository>();

    // The cycle that fills an empty store walks too, so today's call arrives
    // without anyone scrolling.
    await _waitForStoredRecord($, localRepository, 'walk-today');

    await $(recentsNavKey).tap();
    await $(RecentCdrsScreen).waitUntilVisible();
    await $(const Key('walk-today')).waitUntilVisible();

    // What a user does at the bottom of the list. Ten days of silence sit
    // between the two ends of this archive: before the walk this answered
    // empty once and the list was over.
    final screenContext = $.tester.element(find.byType(RecentCdrsScreen));
    final cubit = screenContext.read<FullRecentCdrsCubit>();
    await cubit.fetchHistory();
    await $.pumpAndSettle();

    expect(
      cubit.state.records.map((cdr) => cdr.callId),
      containsAll([for (var i = 0; i < _gapRecordCount; i++) 'walk-old-$i']),
      reason: 'the ten-day gap must be crossed, not read as the end of the archive',
    );
    await $(const Key('walk-old-0')).waitUntilVisible();

    final ranges = apiLog
        .requestsFor(_historyPath)
        .where((request) => request.uri.queryParameters['time_from'] != null);
    expect(ranges, isNotEmpty, reason: 'every request that reaches back must name the range it wants');
    expect(
      cubit.state.records.map((cdr) => cdr.callId).toSet(),
      hasLength(cubit.state.records.length),
      reason: 'a record on a slice boundary is listed once',
    );

    await logout($);
  });
}

Future<void> _waitForStoredRecord(PatrolIntegrationTester $, CdrsLocalRepository repository, String callId) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!(await repository.getHistory(limit: 50)).any((cdr) => cdr.callId == callId)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('the first sync did not store $callId');
    }
    await $.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _appendRecord(Uri uri, {required String callId, required int minutesAgo}) async {
  final target = uri.replace(
    path: '${uri.path}/record',
    queryParameters: {...uri.queryParameters, 'call_id': callId, 'minutes_ago': '$minutesAgo'},
  );
  final response = await http.post(target);
  expect(response.statusCode, 200, reason: 'failed to seed $callId: ${response.body}');
}

Future<void> _clearHistory(Uri uri) async {
  final response = await http.delete(uri);
  expect(response.statusCode, 200, reason: 'failed to clear seeded CDRs: ${response.body}');
}
