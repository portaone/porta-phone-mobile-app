# Conversation mute

One user's notification mute on one conversation - a chat, a group or an SMS
thread: set it for an hour, eight hours, two days or for good, see how long is
left, and hear nothing from that conversation until it lapses.
Last reviewed: 2026-09-21.

## Where it lives

```
lib/models/messaging/
  notification_mute.dart            NotificationMute - the pair, and isActiveAt(now)
  conversation_user_settings.dart   ConversationUserSettings - what the user holds on a conversation
  */..._snapshot.dart               the conversation plus that state, as *:get returns them
lib/mappers/phoenix/messaging/notification_mute_mapper.dart   the wire, both directions
lib/features/messaging/
  cubits/conversation_user_settings/   what is muted right now, and the timer that says so
  widgets/notification_mute_sheet.dart the durations
  widgets/notification_mute_tile.dart  the row, its subtitle, the list mark
packages/data/app_database/lib/src/tables/
  chat_user_settings_table.dart, sms_conversation_user_settings_table.dart
```

## The pair, and why it is derived

The core keeps two values per user per conversation: `notifications_muted` and
`notifications_muted_until`. `false/null` is not muted, `true/null` is muted for
good, `true/<ts>` is muted until that moment.

**A timed mute expires silently.** No job clears the flag, and no event reaches
the clients - the core simply derives the state on every read. So the client
cannot show what it stored: `NotificationMute.isActiveAt(now)` answers instead,
and `ConversationUserSettingsCubit` re-derives the answer when the stored value
changes, when one timer set to the nearest expiry fires, and when the app comes
back to the foreground (a timer does not run while the app is suspended).

## Storage, and the trap it avoids

The mute lives in `chat_user_settings` / `sms_conversation_user_settings`, one
row per conversation, never as columns on `chats`.

A conversation row is written whole every time the core sends the conversation
again, and `chat_info_update` - broadcast to every member, carrying no
per-member state - goes through the same mapper and the same full-row upsert. A
mute column would therefore be cleared by any group rename. The reference web
dialer has exactly that bug; a test here renames a chat and expects the mute to
survive.

The tables are named for the category, not for the mute: anything else that
turns out to be one member's own rather than the conversation's - a pin, an
archive - is a column here and a field on `ConversationUserSettings`, not a
third table. Every column carries a default so a later writer can create the
row, and each write names its own columns instead of replacing the row.

## The wire

| Direction | Event | Topic |
|---|---|---|
| read | `chat:get`, `sms:conversation:get` | the conversation's own |
| write | `chat:mute {muted_until?}`, `chat:unmute` | the conversation's own |
| write | `sms:conversation:mute`, `sms:conversation:unmute` | the conversation's own |
| fan-out | `chat_mute_update`, `sms_conversation_mute_update` | `chat:user:<user_id>` |

Two details the core insists on. `muted_until` must carry an offset - Dart
writes one only for a UTC value, so a local `DateTime` handed to
`toIso8601String` is exactly the string that comes back as
`invalid_mute_expiration`. And "forever" is the absence of the field, not a
far-future timestamp.

The fan-out reaches the device that made the change too, so applying it is
idempotent: the DAO writes only when the value differs, so watchers of the
settings table stay quiet on the echo. Nothing goes on the repository bus for
a mute - no one there needs it, and every listener would pay for it.

A mute for a conversation this client does not hold yet is dropped rather than
written: another device can create a group and mute it before `chat:get` has
answered here, and the row the mute hangs off would not exist. The `*:get`
reply carries the mute anyway.

## The control

Offered only where the core advertises `conversationMute`
(`FeatureAccess.conversationMuteAvailable`) - absent otherwise, not shown
switched off, because there is no state behind it. The capability is read at
login, so a backend that gains it needs a re-login.

- **chat, group**: a "Notifications" row in the info sheet, with "On", "Muted"
  or "Muted until 18:00" under it. The info sheet sits on its own route, above
  where the feature access lives, so the opening screen passes the answer in.
- **SMS**: the same entry in the app-bar menu, beside the delete - a text
  conversation has no info screen.
- **list**: a crossed-bell mark next to the name of a muted conversation. It
  needs no capability check: a mute can only be stored where the core reports
  one.

The sheet offers the four durations, and "Unmute" first and only while a mute is
in force. A duration picked over an existing mute replaces it - that is what
changing the duration is, and the core treats a second mute the same way.

## Local silence

The core sends no push for a muted conversation, so the client has little left
to do:

- the unread totals on the messaging tab and on the bottom bar leave muted
  conversations out - decided once, in `UnreadCountCubit`, which follows the
  settings cubit's clock - while the row's own badge still counts, so what
  was missed stays visible where the user looks for it;
- the foreground push handler drops a push for a muted conversation, which
  covers the window in which a mute set on another device is still on its way.

## Reset

Leaving a group drops the member row the mute hangs off, so rejoining comes
back unmuted. Nothing else resets it; the app's cascade mirrors that.
