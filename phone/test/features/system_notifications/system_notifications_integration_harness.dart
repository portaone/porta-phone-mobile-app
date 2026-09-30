import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/data/data.dart' show AppDatabase;
import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/push_notification/app_local_push.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import '../../mocks/fake_connectivity_service.dart';

/// Real API mapping, polling owner, file-backed SQLite and push policy.
/// Only HTTP, connectivity eligibility and the native push boundary are faked.
class SystemNotificationsIntegrationHarness {
  SystemNotificationsIntegrationHarness._(this.directory, {required bool producePush}) {
    database = AppDatabase(NativeDatabase(File('${directory.path}/notifications.sqlite')));
    local = SystemNotificationsLocalRepositoryDriftImpl(database);
    client = api.WebtritApiClient.inner(Uri.parse('https://refresh.test'), '', httpClient: MockClient(_respond));
    client.sessionRejections.listen((rejection) => fail('Unexpected session rejection: $rejection'));
    final remote = SystemNotificationsRemoteRepositoryApiImpl(client, 'integration-token');
    worker = SystemNotificationsSyncWorker(local, remote, pageSize: 2);
    polling = PollingService(connectivityService: connectivity, options: const PollingOptions(jitterRatio: 0));
    owner = SystemNotificationsSync(worker: worker, pollingService: polling, interval: const Duration(hours: 1));
    registerFallbackValue(AppLocalPush(0, '', ''));
    final localPush = _LocalPush();
    final remotePush = _RemotePush();
    when(() => localPush.systemNotificationsActions).thenAnswer((_) => const Stream.empty());
    when(() => remotePush.systemNotificationsOpenedPushs).thenAnswer((_) => const Stream.empty());
    when(() => remotePush.systemNotificationsForegroundPushs).thenAnswer((_) => const Stream.empty());
    when(() => localPush.displayPush(any())).thenAnswer((invocation) async {
      pushes.add(invocation.positionalArguments.single as AppLocalPush);
    });
    pushService = SystemNotificationsPushService(
      remotePush,
      localPush,
      local,
      openNotifications: () {},
      producePush: producePush,
    )..init();
  }

  static Future<SystemNotificationsIntegrationHarness> create({bool producePush = true}) async {
    final directory = await Directory.systemTemp.createTemp('system-notifications-sync-');
    final harness = SystemNotificationsIntegrationHarness._(directory, producePush: producePush);
    addTearDown(harness.dispose);
    return harness;
  }

  final Directory directory;
  final connectivity = FakeConnectivityService(initialConnected: false);
  final requests = <http.Request>[];
  final pushes = <AppLocalPush>[];
  late final AppDatabase database;
  late final SystemNotificationsLocalRepositoryDriftImpl local;
  late final api.WebtritApiClient client;
  late final SystemNotificationsSyncWorker worker;
  late final PollingService polling;
  late final SystemNotificationsSync owner;
  late final SystemNotificationsPushService pushService;
  Future<http.Response> Function(http.Request) respond = (_) async => response([]);

  Future<http.Response> _respond(http.Request request) {
    requests.add(request);
    return respond(request);
  }

  static SystemNotification notification(int id) => SystemNotification(
    id: id,
    title: 'Integration notification $id',
    content: 'Integration content $id',
    seen: false,
    type: SystemNotificationType.system,
    createdAt: DateTime.utc(2026, 9, id).toLocal(),
    updatedAt: DateTime.utc(2026, 9, id).toLocal(),
  );

  static http.Response response(List<SystemNotification> items) => http.Response(
    jsonEncode({
      'items': items
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'content': n.content,
              'seen': n.seen,
              'type': n.type.name,
              'created_at': n.createdAt.toUtc().toIso8601String(),
              'updated_at': n.updatedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  void expectRequest(int index, {DateTime? since}) {
    final request = requests[index];
    expect(request.method.toUpperCase(), 'GET');
    expect(request.headers['authorization'], 'Bearer integration-token');
    expect(request.url.path, '/api/v1/user/notifications${since == null ? '' : '/updates'}');
    expect(request.url.queryParameters, {
      'limit': '2',
      if (since != null) 'updated_after': since.toUtc().toIso8601String(),
    });
  }

  Future<void> dispose() async {
    await owner.dispose();
    await polling.dispose();
    pushService.dispose();
    client.close();
    await connectivity.dispose();
    await database.close();
    await directory.delete(recursive: true);
  }
}

class _LocalPush extends Mock implements LocalPushRepository {}

class _RemotePush extends Mock implements RemotePushRepository {}
