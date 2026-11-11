# phone_link

Flutter plugin that opens a link on the phone a Wear OS watch is paired with
(`androidx.wear:wear-remote-interactions`, `RemoteActivityHelper.startRemoteActivity`). The app uses it on a watch
for the pages it cannot show there - a watch has no web view - through the open-on-phone page
([adaptive_layout.md](../../docs/architecture/adaptive_layout.md)).

## Public API

- `static Future<bool> PhoneLink.open(Uri uri)` - asks the paired phone to open `uri` (an `ACTION_VIEW`,
  `CATEGORY_BROWSABLE` intent). `true` once the phone has taken it; `false` when it could not be delivered (no phone
  paired or in reach), on any channel error, and off Android, where nothing is asked.
