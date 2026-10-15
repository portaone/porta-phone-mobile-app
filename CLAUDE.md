# PortaPhone mobile app — Claude Code

@AGENTS.md

## Gotchas

- **The repository root is here**, not in `phone/`. Anything that resolves paths
  from the git root - hooks, lefthook, the scripts under `scripts/` - is configured
  at this level, and a copy inside a package is read by nothing.
- **Each package still owns its own rules.** `phone/CLAUDE.md`,
  `callkeep/CLAUDE.md` and `tools/CLAUDE.md` load when you work in those
  directories; nothing here replaces them.
- **GitHub is a read-only mirror of Gerrit**, so the `.github/` workflows left
  in the packages run nowhere. Checks for a change are the Jenkins jobs in
  `.jenkins/`, which vote Verified on every patchset.
- **Commits**: a correction is `git commit --amend`, a new patchset of the same
  change; a merged one is never amended.
