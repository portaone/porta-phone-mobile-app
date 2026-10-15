---
name: drift-schema-change
description: Add or change a table, column or index in the app's Drift database (phone/packages/data/app_database) with its migration, schema dump and migration test. Load when a request mentions a Drift table, a new column, a schema version, a migration_vN, migrations.dart, drift_schema_vN.json or app_database.
---

# Drift schema change

When: a table, column, index or table set in `phone/packages/data/app_database` changes, so the
schema version moves. A query-only change in a DAO needs no migration; read
[query_traps.md](../../../phone/packages/data/docs/query_traps.md) instead.

The package rules are in [AGENTS.md](../../../phone/packages/data/AGENTS.md) and the order
that compiles in [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md). Paths
below are relative to `phone/packages/data/app_database/`; run commands from there.

## Steps

1. Take the version number. N is the current `migrations.schemaVersion` plus one, that is the
   length of the list in `lib/src/migrations/migrations.dart` plus two (the list starts at
   `MigrationV2`); check it on the target branch, not only locally:
   `git fetch origin master && git show origin/master:phone/packages/data/app_database/lib/src/migrations/migrations.dart | tail -4`.
   Also make sure no open change of another topic adds `MigrationV<N>`.
2. Edit the table in `lib/src/tables/` (and the barrel `tables.dart`), the DAO in `lib/src/daos/`
   (and `daos.dart`), and the `tables:` / `daos:` lists in `lib/src/app_database.dart`.
3. Write `lib/src/migrations/migration_vN.dart` as a stub: `class MigrationVN extends Migration`
   with an empty `execute()` and no `schema_vN` import. Register `MigrationVN()` in `migrations.dart`.
4. Generate code: `fvm dart run build_runner build --delete-conflicting-outputs`.
5. Dump the schema: `fvm dart run bin/create_new_schema_dump_and_test_migration.dart`. It writes
   `lib/src/drift_schemas/drift_schema_vN.json`, `lib/src/migrations/generated/schema_vN.dart`
   and updates `generated/schema.dart`.
6. Write the real `execute()` against the snapshot of its own version:
   `import 'generated/schema_vN.dart' as vN;`, then `m.createTable(vN.SomeTable(db))` for a new
   table or `m.alterTable(TableMigration(...))` for a reshape (`MigrationV27` is the reference).
   Never `db.someTable`.
7. Add a group `migration vN data integrity` to `test/migrations_test.dart`: start from
   `verifier.schemaAt(N-1)`, insert rows through `vN-1.DatabaseAtV<N-1>`, run
   `verifier.migrateAndValidate(appDatabase, N)`, read back through `vN.DatabaseAtVN`. The
   `general migration` group covers every from/to pair by itself; the data group proves the rows
   survive.
8. Update the mappers in `phone/lib/mappers/drift/` if the data class the app reads changed.
9. Run the package tests by hand: `fvm flutter test` (at least `fvm flutter test test/migrations_test.dart`).

## Before handing over

- `git status` lists, for version N: `migration_vN.dart`, `migrations.dart`,
  `drift_schemas/drift_schema_vN.json`, `generated/schema_vN.dart`, `generated/schema.dart`,
  the table, `app_database.g.dart`, and `test/migrations_test.dart`.
- `grep -n 'db\.' lib/src/migrations/migration_vN.dart` finds no `createTable(db.` or
  `TableMigration(db.`.
- `fvm flutter test` in this package is green, run by you, not assumed from the gate.
- After a rebase, `migrations.dart` still contains `MigrationVN()` and `generated/schema.dart`
  still has its `case N`.
- No `.g.dart` and nothing under `generated/` or `drift_schemas/` was edited by hand.

## Traps

- Migration built from `db.someTable`: correct until the table is reshaped later, then old installs
  get it twice; use `vN.SomeTable(db)` - [AGENTS.md](../../../phone/packages/data/AGENTS.md).
- `MigrationV28` still creates two tables from `db`: switch it to `v28.` in the change that first
  reshapes `chat_user_settings` or `sms_conversation_user_settings` - [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md).
- Migration tests are not in the pre-push gate (`phone-test` runs only in `phone/`): run them in
  the package yourself - [AGENTS.md](../../../phone/packages/data/AGENTS.md).
- Writing the real migration before the dump does not compile (`schema_vN.dart` does not exist
  yet): stub first, dump, then fill in - [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md).
- Two branches take the same N: `migrations.dart` merges cleanly and silently drops your entry;
  renumber and re-run both generators - [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md).
- A new column in a reshape needs both `columnTransformer` and `newColumns` - [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md).
- The dump script calls `dart` from `PATH`, not fvm's: if steps 2-3 of the script fail, check
  `which dart` - [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md).
- New enum column: `textEnum`, never `intEnum` - [AGENTS.md](../../../phone/packages/data/AGENTS.md).
- A new watermark is a row in an existing cursor table, not a new table - [schema_changes.md](../../../phone/packages/data/docs/schema_changes.md).
- Query returns the right rows yet is wrong (joined-row `limit`, correlated subquery, Cyrillic
  case folding) - [query_traps.md](../../../phone/packages/data/docs/query_traps.md).
