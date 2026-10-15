# Contributing to WebTrit Phone

## Branch Naming

Under Gerrit a local branch never reaches the server - a push goes to `refs/for/master` - so the
name is yours alone. Name it after the ticket, so the work is findable in a list of forty:

```
WT-1234-drop-the-web-firebase-options
```

## Commit Messages

The form is the department's, and it is the same in every PortaOne repository:
[commit message rules](https://wiki.portaone.com/pages/viewpage.action?pageId=302270444).

```
WT-1234 Capitalised summary, 50 characters or fewer

Why the change was needed: how things worked before and what was wrong with
that, how they work now, and why it was solved this way. Wrapped at 72
characters.

Change-Id: I9f2c1a...
```

- The ticket id comes first, then a capitalised summary. No conventional-commits type.
- The test for a subject: after removing the ticket id and lowering the first letter,
  "If applied, this commit will *<subject>*" has to read as English.
- 50 characters or fewer, and no full stop at the end.
- The body explains **why**, not how - the code says how. Wrapped at 72.
- `Change-Id` is written by Gerrit's own `commit-msg` hook, installed by `setup-devel-tools.sh`.
  A commit without one is refused on push.
- No Cyrillic anywhere in the message, and no AI attribution.
- One change is one commit. Corrections go in with `git commit --amend`, which Gerrit records as a
  new patchset of the same change rather than as a second commit.

## Git Hooks

Hooks are managed with [Lefthook](https://github.com/evilmartians/lefthook), configured once at the
root of the repository.

```bash
brew install lefthook
lefthook install
```

- **pre-commit** - `dart format` on staged Dart files, `ktlint` and `markdownlint` on callkeep's
- **pre-push** - the commit subjects above, plus analyze, tests, l10n and the semantics gate for
  whichever packages the push touches

`commit-msg` is **not** ours: it belongs to Gerrit. `lefthook install` moves aside any hook it
claims without calling it, so a lefthook `commit-msg` section would silently stop `Change-Id` being
written and every push would be refused. That is why the subject is checked at pre-push.

For installation details, manual execution, and troubleshooting see [docs/guides/development.md](docs/guides/development.md).

## Accessibility

Any UI change ships accessibility coverage: every interactive control gets a spoken name and,
where automation has to reach it, a stable identifier, plus a semantics test for the screen.
See [docs/guides/accessibility.md](docs/guides/accessibility.md) for what to attach, how to verify it, and the
traps that a passing widget test does not catch.
