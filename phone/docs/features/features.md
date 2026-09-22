# Feature docs

Index of the per-feature docs under `docs/features/`. How to author and split these
docs (the file pattern and conventions) is in [`../../AGENTS.md`](../../AGENTS.md)
under "Documentation".

## Index

| Feature                            | Docs                                            | Status                                           |
|------------------------------------|-------------------------------------------------|--------------------------------------------------|
| App update / version compatibility | [Overview](app-update.md)                       | Active - force-update (app side) and iOS pending |
| Call                               | [UX](call_ux.md) / [Architecture](call_arch.md) | Active - UI redesign in progress                 |
| Call history                       | [Overview](call_history.md)                     | Active - reached by walking back in date slices  |
| Call center                        | [Overview](call_center.md)                      | Active - queues behind a capability and an agent check |
| Conference                         | [Overview](call_conference.md)                  | Active - the room, its legs and their mute       |
| Conversation mute                  | [Overview](conversation_mute.md)                | Active - per capability, expiry derived locally  |
| Feature access / runtime config    | [Overview](feature_access.md)                   | Active - session pin semantics                   |
| Presence                           | [Overview](presence.md)                         | Active - badge redesign under discussion         |
| Session tracking                   | [Overview](session_tracking.md)                 | Active - requires core >=0.35.0                  |
| System notifications               | [Overview](system_notifications.md)             | Active - both directions on the polling service  |
| Voicemail                          | [Overview](voicemail.md)                        | Active - save, trash and forward per capability  |
