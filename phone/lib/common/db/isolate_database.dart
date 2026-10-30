import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' show join;
import 'package:sqlite3/common.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';

final _logger = Logger('IsolateDatabase');

/// Opens [AppDatabase] in any isolate of the process.
///
/// Every isolate - the app, the push-notification isolate, the background
/// tasks - shares one connection to the database file. Whichever opens the
/// database first spawns drift's server isolate and registers it in the
/// process-wide `IsolateNameServer`; the others connect to that server, and it
/// shuts down once the last of them has disconnected. Two connections to one
/// file would answer each other's writes with `database is locked`, so nothing
/// opens the file directly.
abstract final class IsolateDatabase {
  /// The database file, in [AppPath.applicationDocumentsPath] on native
  /// platforms and the database name on the web.
  static const dbName = 'db.sqlite';

  /// Opens a client connection to the shared database.
  ///
  /// [directoryPath] holds the file and [tempDirectoryPath] SQLite's temporary
  /// files - [AppPath.applicationDocumentsPath] and [AppPath.temporaryPath].
  /// Both are passed rather than looked up: an isolate started with
  /// `Isolate.spawn` or `compute` has no platform channels to ask. Both are
  /// ignored on the web.
  ///
  /// The server is found by [dbName] alone: once one runs for a name, every
  /// later open of that name reaches its file, whatever [directoryPath] says.
  static AppDatabase open({required String directoryPath, required String tempDirectoryPath, String dbName = dbName}) {
    assert(kIsWeb || directoryPath.isNotEmpty, 'directoryPath must not be empty');
    final connection = driftDatabase(
      name: dbName,
      native: DriftNativeOptions(
        shareAcrossIsolates: true,
        databasePath: () async => join(directoryPath, dbName),
        tempDirectoryPath: () async => tempDirectoryPath,
        setup: _setUp,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: _logWebStorage,
      ),
    );
    return AppDatabase(
      EnvironmentConfig.DATABASE_LOG_STATEMENTS ? connection.interceptWith(_StatementLog()) : connection,
    );
  }

  /// Runs once, in the server isolate, on the one connection it holds.
  static void _setUp(CommonDatabase database) {
    // The server isolate has none of the app's log handlers, so this goes to
    // the console: a second such line in one process is a second server.
    // ignore: avoid_print
    print('IsolateDatabase - the database server opened the database');
    // In the default DELETE journal readers block writers and writers block
    // readers; with WAL they do not.
    database.execute('PRAGMA journal_mode=WAL;');
    database.execute('PRAGMA busy_timeout=5000;');
  }

  /// drift downgrades the web storage by itself (OPFS -> IndexedDB -> memory).
  /// The in-memory one (a private window, a browser with neither) loses all
  /// local data on reload, so it is said rather than left silent.
  static void _logWebStorage(WasmDatabaseResult result) {
    if (result.chosenImplementation == WasmStorageImplementation.inMemory) {
      _logger.warning(
        'Web database has no persistent storage (in-memory fallback) - local data '
        'will be lost on reload. missingFeatures: ${result.missingFeatures}',
      );
    } else {
      _logger.info(
        'Web database storage: ${result.chosenImplementation}'
        '${result.missingFeatures.isEmpty ? '' : ' (missing: ${result.missingFeatures})'}',
      );
    }
  }
}

/// Prints every statement a client sends, with its arguments
/// (`WEBTRIT_APP_DATABASE_LOG_STATEMENTS`) - to the console, as drift's own
/// `logStatements` does, never to the app's log and the remote logging behind it.
class _StatementLog extends QueryInterceptor {
  // ignore: avoid_print
  void _log(String statement, List<Object?> args) => print('Drift: Sent $statement with args $args');

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor executor, String statement, List<Object?> args) {
    _log(statement, args);
    return executor.runSelect(statement, args);
  }

  @override
  Future<int> runInsert(QueryExecutor executor, String statement, List<Object?> args) {
    _log(statement, args);
    return executor.runInsert(statement, args);
  }

  @override
  Future<int> runUpdate(QueryExecutor executor, String statement, List<Object?> args) {
    _log(statement, args);
    return executor.runUpdate(statement, args);
  }

  @override
  Future<int> runDelete(QueryExecutor executor, String statement, List<Object?> args) {
    _log(statement, args);
    return executor.runDelete(statement, args);
  }

  @override
  Future<void> runCustom(QueryExecutor executor, String statement, List<Object?> args) {
    _log(statement, args);
    return executor.runCustom(statement, args);
  }

  @override
  Future<void> runBatched(QueryExecutor executor, BatchedStatements statements) {
    _log(statements.statements.join('; '), statements.arguments);
    return executor.runBatched(statements);
  }
}
