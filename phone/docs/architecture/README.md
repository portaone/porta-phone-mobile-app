# Architecture

Why the app is shaped this way: the mechanisms a feature is built on.

| Page | What it holds |
| --- | --- |
| [adaptive_layout.md](adaptive_layout.md) | Giving a screen a second arrangement (landscape) |
| [bloc_async_state.md](bloc_async_state.md) | Loading several things at once in a Cubit or Bloc: stale `state` after `await`, emit after `close()` |
| [core_error_codes.md](core_error_codes.md) | How Core translates adapter refusals, and which codes the app turns into a logout |
| [data_refresh.md](data_refresh.md) | How a user asks a list to fetch again, screen by screen |
| [dependency_ownership.md](dependency_ownership.md) | Which objects the startup path creates, which the widget tree creates, and who releases them |
| [destination_picking.md](destination_picking.md) | How a feature sends the user to the lists to pick a person |
| [feature_gates.md](feature_gates.md) | A feature behind a backend capability and a per-user answer at once |
| [fonts.md](fonts.md) | How the app gets the typeface a theme names |
| [history_paging.md](history_paging.md) | Paging a history by date: reaching records an endpoint does not volunteer |
| [ice_servers.md](ice_servers.md) | Where the STUN/TURN servers come from, how they are cached and renewed |
| [incoming_call_lifecycle.md](incoming_call_lifecycle.md) | One call id reported many times: the same call, a ghost of an ended one, a new attempt |
| [incoming_call_scenarios.md](incoming_call_scenarios.md) | How an incoming call is delivered and handled per app state and mode |
| [polling.md](polling.md) | PollingService: periodic, lifecycle and manual refreshes without overlap |
| [polling_workers.md](polling_workers.md) | The polling worker pattern: one sync cycle apart from its scheduling |
| [session_remount.md](session_remount.md) | Replacing `MainShell` for the same sign-in: calls, teardown order, dropped notifications |
| [signaling_architecture_target.md](signaling_architecture_target.md) | The three layers of the signaling stack |
| [startup.md](startup.md) | Where cold start time goes, measured |
| [startup_performance.md](startup_performance.md) | How the Dart startup path is recorded and read |

Belongs here: a mechanism several features share, or one that outlives a screen. What does not: how to do a task ([guides/](../guides/README.md)), what a configuration key means ([reference/](../reference/README.md)), one feature ([features/](../features/features.md)).
