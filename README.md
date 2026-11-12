# PortaPhone

PortaPhone is the mobile VoIP application for Android and iOS: audio and video calls, contacts,
call history, chats and voicemail. It is a Flutter app that talks to Core over the Core API and
signaling, and each customer gets it under their own brand.

This repository holds the app, the call plugin it runs on and the CLI that brands it.

## Parts

| Part | Directory | What it is |
|---|---|---|
| Mobile App | [phone/](phone/README.md) | The Flutter app and its packages; [phone/docs/README.md](phone/docs/README.md) is the map of its docs |
| Call plugin (CallKeep) | [callkeep/](callkeep/README.md) | The native call layer: CallKit and PushKit on iOS, Telecom `ConnectionService` on Android |
| Branding CLI | [tools/](tools/README.md) | Prepares, configures and signs a branded build from the configurator |
| Lint rules | [analysis/](analysis/README.md) | The shared Dart lint rules `tools/` includes |
| CI checks | [.jenkins/](.jenkins/README.md) | The Jenkins jobs that vote Verified on every Gerrit patchset: unit tests only, run only when the patchset touches their paths; no analyze, format or l10n check - those run in the git hooks of `lefthook.yml` |

The rest of the root:

- `Dockerfile` - the stages the Jenkins checks run; its `FLUTTER_VERSION` and `FLUTTER_SHA256`
  change in the same commit as `phone/.fvmrc`.
- `docs/` - the Gerrit pages: push, chain rework, checks.
- `scripts/` - the push and commit-subject checks.
- `lefthook.yml` - the git hooks of every package.
- `.claude/`, `.agents/skills/` - agent settings, hooks and skills.

The full layout is in [AGENTS.md](AGENTS.md#layout).

## Contributing

The repository is reviewed in Gerrit, one commit per change.

- [AGENTS.md](AGENTS.md) - the layout, the commit form and the rules for every package.
- [phone/CONTRIBUTING.md](phone/CONTRIBUTING.md) - branch names, commit messages, hooks and
  accessibility.
- [callkeep/CONTRIBUTING.md](callkeep/CONTRIBUTING.md) - the git hooks of the call plugin.
- [Pushing to Gerrit](docs/gerrit_push.md) - the push form and the gate before it;
  [Reworking a Gerrit chain](docs/gerrit_chain_rework.md) for a chain of several commits.
- [Gerrit checks](docs/gerrit_checks.md) - what Jenkins runs after a push and what fails it.
