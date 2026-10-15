# AGENTS.md - data

The app's local database: one package, `app_database/`, built on Drift (SQLite). Paths below
are relative to `app_database/`, and every command runs from there. A schema change has its own
procedure - the skill `drift-schema-change`
([SKILL.md](../../../.agents/skills/drift-schema-change/SKILL.md)) and
[docs/schema_changes.md](docs/schema_changes.md); this page holds the layout, the conventions and
where to read before a change.

## Layout

```
app_database/
  lib/src/app_database.dart     AppDatabase: the table and DAO lists, triggers, deleteEverything
  lib/src/tables/               one file per table, barrel tables.dart
  lib/src/daos/                 one DAO per area, barrel daos.dart; contact_search.dart,
                                contact_source_priority.dart
  lib/src/migrations/           migration_vN.dart per version, registered in migrations.dart
  lib/src/migrations/generated/ schema_vN.dart snapshots (generated, do not edit)
  lib/src/drift_schemas/        drift_schema_vN.json dumps (generated, do not edit)
  lib/src/connection/           native.dart (NativeDatabase), web.dart (WasmDatabase)
  bin/create_new_schema_dump_and_test_migration.dart
  test/                         DAO tests, migrations_test.dart
  docs/                         contact lookup by number, contact search
docs/                           schema changes, query traps
```

## Access goes through DAOs

New code reads and writes through a DAO: a repository takes `AppDatabase` and calls
`appDatabase.<area>Dao`, and Drift classes stay in the repository layer. Calls on `AppDatabase`
itself exist in three places and are the exceptions, not the pattern:
`DatabaseCacheSection` (`databaseSizeBytes`, `deleteEverything`, `vacuum`),
`RepositoryUserSessionCleanupResolver` (`deleteEverything`) and `ContactsLocalDataSourceImpl`
(`transaction`). A query you need goes into a DAO method.

## Before a change

| You are about to | Read first | Skill |
|---|---|---|
| add or change a table, column or index | [docs/schema_changes.md](docs/schema_changes.md) | `drift-schema-change` |
| write or change a query | [docs/query_traps.md](docs/query_traps.md) | |
| look a contact up by number | [contact_lookup_by_number.md](app_database/docs/contact_lookup_by_number.md) | |
| change contact search | [contact_search.md](app_database/docs/contact_search.md) | |

A migration builds the schema of its own version, never the current one:
`m.createTable(vN.SomeTable(db))` from `generated/schema_vN.dart`, not
`m.createTable(db.someTable)`. The second reads the same while a table keeps its shape and is
wrong once it changes: an install arriving from the version before gets the table created
already reshaped, and the later migration reshapes it again. Every migration pins its version
except `MigrationV28`, which still creates two tables from the live schema; see
[docs/schema_changes.md](docs/schema_changes.md).

## Table conventions

- Enum columns: `textEnum<T>()`, which stores the name, so an enum can gain or reorder values
  without rewriting rows. `intEnum` survives in three old columns (`contacts.source_type`,
  `contacts.kind`, `call_logs.direction`); do not add a fourth.
- Foreign keys: `integer().references(SomeTable, #id, onDelete: KeyAction.cascade)()`. Three
  older tables (`contact_phones`, `contact_emails`, `favorites`) still spell it as
  `customConstraint('NOT NULL REFERENCES ... ON DELETE CASCADE')`.
- `inserted_at` / `updated_at` columns are filled by the triggers `AppDatabase` creates for every
  table that has them; never set them by hand.
- Upserts: `insertOnConflictUpdate`, or `insertReturning(..., onConflict: DoUpdate(...))` when
  the written row is needed back.
- A watermark is a row in a cursor table, not a table of its own
  ([schema_changes.md](docs/schema_changes.md#designing-a-table)).

## DAO conventions

- `@DriftAccessor(tables: [...])` on a class extending `DatabaseAccessor<AppDatabase>`; a new DAO
  is also listed in `daos:` of `app_database.dart` and exported from `daos.dart`.
- Return domain-level compound objects joining related tables (`FullContactData`).
- `watch...()` methods for what the UI shows live.
- A query that resolves a number to one contact orders by `contactsTable.sourcePriorityOrder()`
  so the winner of a number shared by a device and a PBX contact is deterministic:
  [contact_lookup_by_number.md](app_database/docs/contact_lookup_by_number.md).

## Domain areas

| Domain | Tables | DAO |
|---|---|---|
| Contacts | contacts, contact_phones, contact_emails | ContactsDao, ContactPhonesDao, ContactEmailsDao |
| Call history | call_logs | CallLogsDao, RecentsDao |
| Chats | chats, chat_members, chat_messages, chat_user_settings, chat outbox (4), cursors (2) | ChatsDao |
| SMS | sms_conversations, sms_conversation_user_settings, sms_messages, user_sms_numbers, sms outbox (3), cursors (2) | SmsDao |
| Voicemail | voicemails | VoicemailDao |
| Notifications | active_messaging_notifications, system_notifications, system_notifications_outbox | ActiveMessageNotificationsDao, SystemNotificationsDao |
| Presence | presence_info | PresenceInfoDao |
| Favorites | favorites, favorites_outbox, favorites_v2 | FavoritesDao, FavoritesV2Dao |
| CDR | cdrs, cdr_sync_cursors (one row per watermark kind) | CdrsDao |
| SIP subscriptions | sip_subscriptions, sip_subscriptions_outbox | SipSubscriptionsDao |
| Dialog info | dialog_info | DialogInfoDao |

Outboxes hold writes made offline until they are sent. Chats and SMS keep one table per action:
`chat_outbox_messages`, `chat_outbox_message_edits`, `chat_outbox_message_deletes`,
`chat_outbox_read_cursors`, and `sms_outbox_messages`, `sms_outbox_message_deletes`,
`sms_outbox_read_cursors`. `favorites_outbox`, `sip_subscriptions_outbox`
and `system_notifications_outbox` are one table each with an action column (`action`, or
`actionType` for notifications) in the primary key.

## Commands

From `phone/packages/data/app_database/`:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run bin/create_new_schema_dump_and_test_migration.dart   # only inside the schema procedure
fvm flutter test
fvm flutter test test/migrations_test.dart
```

The lefthook pre-push gate does not run these tests; the Jenkins `phone-test` target does, on
patchsets that touch `phone/`. After any change here run `fvm flutter test` in this package
yourself.

## Further reading

- [docs/schema_changes.md](docs/schema_changes.md) - the order that compiles, reshaping a table,
  two branches on one version, designing a table
- [docs/query_traps.md](docs/query_traps.md) - queries that return the right rows and are still
  wrong
- [app_database/docs/contact_lookup_by_number.md](app_database/docs/contact_lookup_by_number.md),
  [app_database/docs/contact_search.md](app_database/docs/contact_search.md)
