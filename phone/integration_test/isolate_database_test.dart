import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:path/path.dart' as p;

import 'package:webtrit_phone/common/db/isolate_database.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/call_logs/call_logs_repository.dart';

import 'components/components.dart';
import 'models/models.dart';

var _databases = 0;
const _number = 'ISOLATE-NUMBER';

/// Opens the database in an isolate of its own, as a background task does, and
/// adds one call to the log.
Future<void> _addCallInAnotherIsolate((String, String) where) async {
  final (dbPath, dbName) = where;
  final db = IsolateDatabase.open(directoryPath: dbPath, tempDirectoryPath: dbPath, dbName: dbName);
  try {
    await CallLogsRepository(appDatabase: db).add(CallLogsFixtureFactory.createCall(0, _number));
  } finally {
    await db.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeAppPath fakeAppPath;
  late String dbPath;
  late String dbName;

  AppDatabase open() => IsolateDatabase.open(directoryPath: dbPath, tempDirectoryPath: dbPath, dbName: dbName);

  setUp(() async {
    fakeAppPath = FakeAppPath();
    dbPath = fakeAppPath.applicationDocumentsPath;
    // The server is found by the database's name, so every test has its own.
    dbName = 'test_isolate_db_${_databases++}.sqlite';
    await DatabaseFileHelper.deleteDatabaseFiles(directoryPath: dbPath, dbName: dbName);
  });

  tearDown(() async {
    await DatabaseFileHelper.deleteDatabaseFiles(directoryPath: dbPath, dbName: dbName);
    fakeAppPath.cleanup();
  });

  testWidgets('the database is the file in the directory it was opened in', (tester) async {
    final db = open();
    try {
      expect(await CallLogsRepository(appDatabase: db).watchHistoryByNumber('any').first, isEmpty);
    } finally {
      await db.close();
    }

    expect(File(p.join(dbPath, dbName)).existsSync(), isTrue);
  });

  testWidgets('a call added in another isolate reaches the app watching the log', (tester) async {
    final db = open();
    try {
      final history = CallLogsRepository(appDatabase: db).watchHistoryByNumber(_number);
      final added = history.firstWhere((logs) => logs.isNotEmpty);

      await compute(_addCallInAnotherIsolate, (dbPath, dbName));

      expect(await added.timeout(const Duration(seconds: 5)), hasLength(1));
    } finally {
      await db.close();
    }
  });
}
