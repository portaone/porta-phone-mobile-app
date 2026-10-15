# pjsua_companion

A test tool, not app code: an HTTP server (`bin/server.dart`, port 7788 by default) that drives
the `pjsua` CLI to place, auto-answer, hold and hang up SIP calls, and `PjsuaCompanionClient`
(`lib/src/client.dart`) that `patrol_test/` uses to call it. `tool/scripts/patrol_e2e_run_local_android.sh`
starts the server. Install, Docker, the HTTP API and the client: [README.md](README.md). The host,
port and SIP variables the tests read: [integration_test_variables.md](../../docs/reference/integration_test_variables.md).

- A route changed in `bin/server.dart` changes `lib/src/client.dart` and the README's API section
  in the same change.
- Known gaps: `play_video` passes `media/vid.avi`, but only `bin/media/vid.mp4` exists (the README
  names `vid.avi` too); `/transfer` throws `UnimplementedError` out of the request loop, which ends
  the server; the client exposes no `play_music` / `play_video`.

No tests of its own; it is exercised by the `patrol_test/` call tests on a device.
