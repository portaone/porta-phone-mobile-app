# Changing the Drift schema

How to change the schema: the order that compiles, how to reshape a table that already exists,
and the traps around the schema version. The package's rules are in [AGENTS.md](../AGENTS.md).
Paths are relative to `app_database/`; run the commands from there with the pinned SDK
(`fvm dart ...`).
Last reviewed: 2026-10-15.

## The order that compiles

A migration builds the schema of its own version, so `migration_vN.dart` imports
`lib/src/migrations/generated/schema_vN.dart`. That file does not exist until
`bin/create_new_schema_dump_and_test_migration.dart` has run, and the script imports `AppDatabase`, which needs the migration to compile. Break the loop with a stub:

```bash
# 1. Edit the table, the DAO, the barrel files and app_database.dart.
# 2. Write MigrationVN with an empty execute() and no schema_vN import,
#    and register it in lib/src/migrations/migrations.dart.
fvm dart run build_runner build --delete-conflicting-outputs
# 3. The script builds a reference database at the new version, dumps it to
#    lib/src/drift_schemas/drift_schema_vN.json and regenerates generated/.
fvm dart run bin/create_new_schema_dump_and_test_migration.dart
# 4. Write the real execute() against vN.SomeTable(db).
# 5. Add the migrations_test.dart group and run the package tests by hand:
#    the pre-push gate does not run them (see AGENTS.md).
```

The schema version is not a constant you edit: it is `migrations.schemaVersion`, the length of
the list in `migrations.dart` plus one. Registering the migration is what moves it.

The script runs its two `drift_dev` steps with the `dart` it finds on `PATH`, not the one `fvm`
picked for the script itself. If those steps fail while the first one succeeds, check which
`dart` is on `PATH`.

## Reshaping an existing table

A change of shape is `m.alterTable(TableMigration(...))`, not `createTable`. It creates the new
table, copies the rows through `columnTransformer`, drops the old table and renames the new one.
A dropped column needs nothing. A new column needs an entry in `columnTransformer` and in
`newColumns`. `MigrationV27` is the reference:

```dart
final cursors = v27.CdrSyncCursors(db);
// ignore: experimental_member_use
await m.alterTable(
  TableMigration(
    cursors,
    columnTransformer: {cursors.kind: Constant(CdrCursorKindEnum.sync.name)},
    newColumns: [cursors.kind],
  ),
);
```

`TableMigration` is marked experimental in drift, hence the `ignore`.

## Trap: a migration built from `db.someTable`

Why a migration must use `vN.SomeTable(db)` and never `db.someTable` is in
[AGENTS.md](../AGENTS.md). One exception is still in the code: `MigrationV28` creates
`chatUserSettingsTable` and `smsConversationUserSettingsTable` from `db`. That is harmless while
both tables keep their shape; switch it to `v28.` in the change that first reshapes either.

## Trap: two branches take the same version

- What you do: start `MigrationV<N>` while another unmerged change also adds `V<N>`.
- What happens: whoever lands second has to renumber. Exactly the files both sides created
  conflict:

  | File | Resolution |
  |---|---|
  | `lib/src/migrations/migration_vN.dart` | keep theirs, move yours to `migration_v<N+1>.dart` |
  | `lib/src/drift_schemas/drift_schema_vN.json` | keep theirs; yours is regenerated |
  | `lib/src/migrations/generated/schema_vN.dart` | keep theirs; yours is regenerated |
  | `test/migrations_test.dart` | merge by hand: theirs stays, yours becomes `migration v<N+1> data integrity` and starts from `schemaAt(N)` |

- The real trap is the two files that do not conflict: `migrations.dart` and
  `generated/schema.dart`. Both sides added the same line (`MigrationVN(),`, the same `case`), so
  git merges them cleanly and your entry disappears without a trace.
- Instead: check `migrations.dart` on the target branch before taking a number. When it does
  happen, add `MigrationV<N+1>()` and its import by hand, then run `build_runner` and the dump
  script again.

## Designing a table

- A watermark is a row, not a table. Cursors of the same shape share one table keyed by an enum
  column: `cdr_sync_cursors` holds one row per `CdrCursorKindEnum`, `chat_message_sync_cursors`
  one per chat and `MessageSyncCursorTypeEnum`. A new watermark then costs a row instead of a
  table, a migration and a schema dump of several thousand lines.
- Reshape before the table ships. Changing an unmerged table means rewriting its migration;
  changing a shipped one means moving data on live databases.
- Enum columns use `textEnum`; see the table conventions in [AGENTS.md](../AGENTS.md).

Back to the workflow: [AGENTS.md](../AGENTS.md).
