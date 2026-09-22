## Variables

This file describes environment variables and Dart define variables used in the WebTrit application
configuration.

Last reviewed: 2026-09-11.

### Naming Convention

To ensure clarity and consistency across configuration parameters, the following naming conventions
are used:

| Prefix       | Purpose                                                                  |
|--------------|--------------------------------------------------------------------------|
| `WEBTRIT_`   | Public and required or commonly configurable variables.                  |
| `_WEBTRIT_`  | Optional or platform-specific variables. Inactive unless explicitly set. |
| `__WEBTRIT_` | Internal meta fields used only for documentation (e.g., descriptions).   |

#### Example:

```json
{
  "WEBTRIT_APP_NAME": "WebTrit",
  "_WEBTRIT_APP_FCM_VAPID_KEY": "",
  "__WEBTRIT_APP_FCM_VAPID_KEY_DESCRIPTION": "Used only for Web Push via FCM. Optional."
}
```

This convention ensures clear separation between active, optional, and descriptive keys, improving
maintainability and enabling tools to parse configuration reliably.

---

### Dart define

- `WEBTRIT_APP_NAME` – The application name (_default: **WebTrit**_).
- `WEBTRIT_APP_LINK_DOMAIN` – Used to configure Android App Links and iOS Universal Links.
- `WEBTRIT_APP_DEMO_CORE_URL` – Demo core URL (_default: **http://localhost:4000**_).
- `WEBTRIT_APP_DATABASE_LOG_STATEMENTS` – Enables logging of database queries (
  _default: **false**_).
- `_WEBTRIT_APP_CORE_URL` – Custom core URL (optional override).
- `_WEBTRIT_APP_CORE_VERSION_CONSTRAINT` – Core compatibility range.
- `_WEBTRIT_APP_ABOUT_URL` – URL for "About" screen content.
- `WEBTRIT_APP_SALES_EMAIL` – Email address shown for sales inquiries.
- `_WEBTRIT_APP_FCM_VAPID_KEY` – VAPID key for Web Push notifications (used on web only).
- `_WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_URL` – Logz.io remote logging endpoint (optional).
- `_WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_TOKEN` – Logz.io auth token.
- `_WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_BUFFER_SIZE` – Logz.io log buffer size.
- `WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS` - Application polling retry cap in
  positive whole seconds (default: **900**). A longer task interval remains the
  minimum delay. Invalid values fall back safely; the shell reads this value
  when creating the polling service, not on each tick. See
  [polling cap configuration](polling.md#application-cap-configuration).
- `WEBTRIT_APP_POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS` - Leading refresh
  freshness cap in non-negative whole seconds (default: **30**; **0 disables**).
  Each task uses the smaller of its interval and this cap. Invalid/negative
  runtime values use the validated build value; invalid/negative build values
  use 30. The shell snapshots it when creating the polling service. See
  [leading refresh freshness](polling.md#leading-refresh-freshness).
- `WEBTRIT_APP_USER_REPOSITORY_POLLING_INTERVAL_SECONDS` - User record poll
  interval in positive whole seconds (default: **900**). The record (balance,
  numbers, SIP credentials) changes on events the app already sees, so the
  timer is only a safety net: foreground, reconnect, the Settings pull and a
  finished call refresh it on their own. See
  [data refresh](data_refresh.md).
- `WEBTRIT_APP_CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS` - Call history poll
  interval in positive whole seconds (default: **300**). New records appear
  after calls, and a finished call already refreshes the list (see
  `WEBTRIT_APP_POST_CALL_REFRESH_DELAY_SECONDS`), so the timer only catches
  calls made elsewhere. Paused in the background like every polled task.
- `WEBTRIT_APP_CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS` - Call queue
  counters poll interval in positive whole seconds (default: **10**). Unlike
  every other task here it runs only while the call center screen is open: each
  read reaches the PBX and the adapter re-reads the customer's whole hunt group
  list on it, and there is no push channel to replace it with.
- `WEBTRIT_APP_EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS` - Contacts
  poll interval in positive whole seconds when hybrid presence is off (default:
  **300**). Here the fetch is the presence source, so it stays fairly fresh.
- `WEBTRIT_APP_EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS` -
  Contacts poll interval in positive whole seconds when hybrid presence is on
  (default: **1800**). Presence rides the SIP channel, so this fetch only
  refreshes the directory and can run far less often. The shell picks between the
  two at registration from the deployment's presence mode. Invalid values fall
  back safely. See [contacts presence interval](polling.md#contacts-presence-interval).
- `WEBTRIT_APP_POLLING_REACHABILITY_TTL_SECONDS` - How long a reachability probe
  result is reused before the polling service probes the check URL again, in
  positive whole seconds (default: **30**). Together with the task intervals this
  sets the observed health-check rate. Invalid values fall back safely.
- `WEBTRIT_APP_POLLING_JITTER_PERCENT` - Maximum random delay added to every
  computed polling delay, as a whole percent of that delay (default: **10**;
  **0 disables**; 0..100). Out-of-range values fall back safely.
- `WEBTRIT_APP_POST_CALL_REFRESH_DELAY_SECONDS` - Delay between a call ending and
  the refresh of the call history and the user record, in positive whole seconds
  (default: **1**), so the backend has published the CDR and charged the call.
- `WEBTRIT_APP_SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS` - System
  notifications sync interval in positive whole seconds (default: **10**). The
  sync is a polling task like the others, so it pauses in the background and
  backs off on failure.
- `WEBTRIT_APP_SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS` - How
  often the queue of read receipts is sent, in positive whole seconds
  (default: **300**). This is only a safety net for what a previous session
  left behind: marking a notification as read asks for a send right away.

### Environment

- `_WEBTRIT_ANDROID_RELEASE_UPLOAD_KEYSTORE_PATH` – Path for keystore directory used in Android
  release signing.
- `WEBTRIT_HTTP_ALLOWED_DOMAINS` – List of HTTP domains allowed for cleartext traffic.
- `WEBTRIT_CALL_TRIGGER_MECHANISM_SMS` – Enables fallback call triggering via SMS (
  _default: **false**_).
- `WEBTRIT_CALL_TRIGGER_MECHANISM_SMS_PREFIX` – Prefix for SMS-based call triggers.
- `WEBTRIT_CALL_TRIGGER_MECHANISM_SMS_REGEX_PATTERN` – Regex pattern to extract call data from SMS
  content.

> Default build variables are located in [`dart_define.json`](../dart_define.json) and can be
> applied
> via:
> ```bash
> flutter run --dart-define-from-file=dart_define.json
> flutter build apk --dart-define-from-file=dart_define.json
> ```
