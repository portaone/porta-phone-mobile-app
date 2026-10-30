import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:async/async.dart';

import 'package:app_database/app_database.dart';

import 'package:webtrit_phone/common/db/db.dart';

ActiveMessageNotificationData _notification(String id, {int conversationId = 21}) => ActiveMessageNotificationData(
  notificationId: id,
  messageId: 1,
  conversationId: conversationId,
  title: 'Taras Melnyk',
  body: 'hi',
  time: DateTime.utc(2026, 10, 29),
);

/// Runs in an isolate of its own, as a background task does: opens the
/// database there, writes one notification and closes.
Future<void> _writeInAnotherIsolate((String, String) where) async {
  final (path, name) = where;
  final db = IsolateDatabase.open(directoryPath: path, dbName: name, tempDirectoryPath: path);
  await db.activeMessageNotificationsDao.set(_notification('n2'));
  await db.close();
}

/// A cold start from an incoming-call push, in the order the process runs it:
/// the push isolate opens the database before the app has started, then the
/// user opens the app and it opens the database too.
void main() {
  late Directory directory;
  late String dbName;
  late AppDatabase push;
  late AppDatabase app;
  var databases = 0;

  AppDatabase open() =>
      IsolateDatabase.open(directoryPath: directory.path, dbName: dbName, tempDirectoryPath: directory.path);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('isolate_database_test');
    // The server is found by the database's name, so every test has its own.
    dbName = 'test_${databases++}.sqlite';

    push = open();
    await push.activeMessageNotificationsDao.getAllByConversation(21);

    app = open();
  });

  tearDown(() async {
    await push.close();
    await app.close();
    await directory.delete(recursive: true);
  });

  test('the database is the file in the directory it was opened in', () async {
    await app.activeMessageNotificationsDao.set(_notification('n1'));

    expect(File('${directory.path}/$dbName').existsSync(), isTrue);
  });

  test('the app sees what the push isolate writes', () async {
    final seen = app
        .select(app.activeMessageNotificationsTable)
        .watch()
        .map((rows) => rows.map((row) => row.notificationId).toList());
    final queue = StreamQueue(seen);
    expect(await queue.next, isEmpty);

    await push.activeMessageNotificationsDao.set(_notification('n1'));

    expect(await queue.next.timeout(const Duration(seconds: 2)), ['n1']);
    await queue.cancel();
  });

  test('the app sees what another isolate writes', () async {
    final seen = app
        .select(app.activeMessageNotificationsTable)
        .watch()
        .map((rows) => rows.map((row) => row.notificationId).toList());
    final queue = StreamQueue(seen);
    expect(await queue.next, isEmpty);

    await compute(_writeInAnotherIsolate, (directory.path, dbName));

    expect(await queue.next.timeout(const Duration(seconds: 2)), ['n2']);
    await queue.cancel();
  });

  // Holds past the connection's busy_timeout of 5 s: two connections give up
  // with "database is locked" there, one connection queues the write.
  test('the app writes while the push isolate holds a transaction', () async {
    final release = Completer<void>();
    final pushTransaction = push.transaction(() async {
      await push.activeMessageNotificationsDao.set(_notification('n1'));
      await release.future;
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final appWrite = app.activeMessageNotificationsDao.deleteByConversation(21);
    Object? failure;
    unawaited(appWrite.then<void>((_) {}, onError: (Object e) => failure = e));

    await Future<void>.delayed(const Duration(seconds: 6));
    release.complete();
    await pushTransaction;
    await appWrite.catchError((_) => 0);

    expect(failure, isNull);
    expect(await app.activeMessageNotificationsDao.getAllByConversation(21), isEmpty);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
