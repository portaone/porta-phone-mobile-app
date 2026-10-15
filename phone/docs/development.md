# Development

## Git Hooks

We use [Lefthook](https://github.com/evilmartians/lefthook) to manage Git hooks.

The config lives at the **root of the repository**, one level above this package. Lefthook reads
only that one - the per-package configs this repository used to carry stopped being read when the
packages became subtrees, and the rules in them went unenforced until they were removed.

### What the hooks do

| Hook         | Purpose                                                                                     |
|--------------|---------------------------------------------------------------------------------------------|
| `pre-commit` | `dart format` on staged Dart files (generated files excluded); `ktlint` and `markdownlint` for callkeep |
| `pre-push`   | Commit subjects, then `flutter analyze`, `flutter test`, `check_l10n.dart` and the semantics gate for whichever packages the push touches |

Each command is scoped to its package, so a push that only touches `phone/` does not run callkeep's
Gradle tests.

### commit-msg belongs to Gerrit

There is no lefthook `commit-msg` section, and adding one would break pushing. `lefthook install`
moves aside any hook it claims - as `<hook>.old` - and never calls it. In this repository that hook
is Gerrit's, the one that writes the `Change-Id` trailer, and a commit without `Change-Id` is
refused on push. The commit subject is therefore checked at `pre-push`, where the whole series is
visible and a bad subject can still be amended.

### Installation

```bash
brew install lefthook
lefthook install          # from the repository root
```

If `.git/hooks/commit-msg` is missing or is not Gerrit's, restore it with `setup-devel-tools.sh`
as described in [Code Review](https://wiki.portaone.com/pages/viewpage.action?pageId=3867971).

### Skipping Hooks

To bypass hooks temporarily (not recommended):

```bash
git commit --no-verify
git push --no-verify
```

### Manual Execution

```bash
lefthook run pre-commit
lefthook run pre-push
```

The subject check also runs on its own, over any range:

```bash
bash scripts/commit-subject-check.sh              # what this push would publish
bash scripts/commit-subject-check.sh origin/master..HEAD
```

### Example Output

```
9b5f4eaa7 fix: route external contacts through the shared polling task (WT-1760)
  - the ticket id has to come first, as in 'WT-1234 Add the thing'
  - the subject is 78 characters; 50 is the limit
  - conventional-commits types are not used here; lead with the ticket id
  - no Change-Id trailer - install Gerrit's commit-msg hook, then amend

Fix with 'git commit --amend' (or 'git rebase -i' for an earlier commit).
```

## Claude Code Settings

We use [Claude Code](https://docs.anthropic.com/en/docs/claude-code) settings to enforce consistent AI-assisted development rules across the team.

### Settings Levels

Claude Code supports multiple settings levels with different scopes:

| Level | File | Scope | Committed to repo |
|-------|------|-------|--------------------|
| **Team** | `.claude/settings.json` | Shared across all team members | Yes |
| **Local** | `.claude/settings.local.json` | Personal per-developer overrides | No (gitignored) |
| **User** | `~/.claude/settings.json` | Global per-machine settings | N/A |

Settings are merged at runtime: **User < Team < Local** (local overrides team, team overrides user).

### Team Settings (`.claude/settings.json`)

The team settings file (`.claude/settings.json` at the repository root) defines shared `deny` rules that prevent Claude Code from accessing sensitive files:

- **Keystores** — `.jks`, `.keystore`, `.p12` files
- **Signing keys** — `.pem`, `.key`, `.p8` files
- **Environment files** — `.env*` files

These rules ensure that no team member accidentally exposes secrets or signing credentials through AI-assisted workflows.

### Local Settings (`.claude/settings.local.json`)

This file is gitignored and used for personal `allow` rules (e.g., auto-approving `flutter test`, `dart format`). Each developer can configure their own convenience permissions without affecting the team.
