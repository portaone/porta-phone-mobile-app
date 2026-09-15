import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// ignore: depend_on_referenced_packages
import 'package:drift/backends.dart';

import 'package:api/api.dart' as api;
import 'package:app_database/app_database.dart';

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/repositories/voicemail/voicemail_repository.dart';

/// Real API mapping, repository and SQLite, with controlled HTTP and optional
/// failure/gating hooks before DAO operations. Does not simulate an OS disk fault.
class VoicemailRepositoryIntegrationHarness {
  VoicemailRepositoryIntegrationHarness(QueryExecutor executor) : _database = _Database(executor) {
    client = api.WebtritApiClient.inner(Uri.parse('https://refresh.test'), '', httpClient: MockClient(_respond));
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'integration-token',
      appDatabase: database,
      trashSupported: true,
      sessionGuard: sessionGuard,
    );
  }

  static const cached = VoicemailData(
    id: 'message-1',
    date: '2026-09-10T10:00:00Z',
    duration: 5,
    sender: '1000',
    receiver: '2000',
    seen: false,
    size: 100,
    type: 'audio',
    attachmentPath: null,
  );
  static const item = <String, Object>{
    'id': 'message-1',
    'date': '2026-09-10T10:00:00Z',
    'duration': 10,
    'seen': true,
    'size': 200,
    'type': 'audio',
  };
  static http.Response listResponse({bool empty = false}) => _json({
    'has_new_messages': false,
    'items': empty ? [] : [item],
  });
  static http.Response detailsResponse() => _json({...item, 'sender': '1001', 'receiver': '2000', 'attachments': []});
  static http.Response _json(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  final _Database _database;
  AppDatabase get database => _database;
  final sessionGuard = _RecordingSessionGuard();
  final requests = <http.Request>[];
  late final api.WebtritApiClient client;
  late final VoicemailRepositoryImpl repository;
  ControlledVoicemailDao get dao => _database.voicemailDao;

  Future<http.Response> Function(http.Request) respond = (_) async => listResponse(empty: true);

  Future<http.Response> _respond(http.Request request) {
    // Requests may arrive from timers while Patrol is pumping a frame.
    expectSync(request.method.toUpperCase(), 'GET');
    expectSync(request.url.path, startsWith('/api/v1/user/voicemails'));
    expectSync(request.headers['authorization'], 'Bearer integration-token');
    requests.add(request);
    return respond(request);
  }

  Future<void> initialize() async {
    await repository.refresh(); // Join and drain the constructor's eager fetch.
    await dao.insertOrUpdateVoicemail(cached);
    requests.clear();
  }

  Future<void> dispose() async {
    client.close();
    await database.close();
  }
}

class _Database extends AppDatabase {
  _Database(super.executor);

  late final _dao = ControlledVoicemailDao(this);

  @override
  ControlledVoicemailDao get voicemailDao => _dao;
}

class ControlledVoicemailDao extends VoicemailDao {
  ControlledVoicemailDao(super.database);

  Future<void> Function()? beforeRead;
  Future<void> Function()? beforeWrite;

  @override
  Future<List<VoicemailWithContact>> getVoicemailsWithContacts() async {
    await beforeRead?.call();
    return super.getVoicemailsWithContacts();
  }

  @override
  Future<void> insertOrUpdateVoicemail(VoicemailData voicemail) async {
    await beforeWrite?.call();
    await super.insertOrUpdateVoicemail(voicemail);
  }
}

class _RecordingSessionGuard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
