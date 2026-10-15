---
name: gerrit-push
description: Pushes a change, a chain, a new patchset or a release tag to Gerrit through scripts/gerrit-push.sh - message checks, dry run, confirmation, gate, push, server check. Load it whenever a request says push, upload, send for review, new patchset, refs/for, wip, topic, tag or release branch.
---

# Pushing to Gerrit

**When:** commits above the target branch should reach Gerrit - a new change, a chain, a new
patchset after an amend, a push to `release/X.Y.Z`, or a release tag.

## Steps

1. Commit everything (the script refuses uncommitted tracked changes) and check the messages
   before the gate, which reports them only at its end:

   ```sh
   bash scripts/commit-subject-check.sh
   git log --format=%B origin/master..HEAD | grep -c '^Change-Id:'    # one per commit
   git log --format=%B origin/master..HEAD | grep -oE '[A-Z]+-[0-9]+' | sort | uniq -c
   ```

   Only the ticket of the task in hand may appear. On a release branch pass the range
   `origin/release/X.Y.Z..HEAD` to all three.
2. Dry run - it pushes nothing:

   ```sh
   bash scripts/gerrit-push.sh --dry-run [--target release/X.Y.Z] [--topic WT-1234]
   ```

3. Show the person who asked the commit list, `Target:` and `Topic:` (the topic defaults to the
   branch's ticket id) and wait for an explicit yes. Every time, also after "push it".
4. Push with the mark chosen below (same `--target` / `--topic` as the dry run):

   ```sh
   bash scripts/gerrit-push.sh [--wip | --ready | --no-mark] [--target ...] [--topic ...]
   ```

5. Read the `On the server:` block: one line per commit with the change number and `wip=`.
   A `MISMATCH` line or a non-zero exit means the server does not hold your commits; a failed
   gate pushed nothing and names its log.

## The mark

- **New chain:** no flag - the default is `--wip`.
- **A change already in review** (WIP lifted): `--no-mark`; the script refuses to guess there.
- **`--wip`** on such a change puts WIP back - only when asked to take it out of review.
- **`--ready`** lifts WIP - only when asked to start the review, and only together with a new
  patchset: on a chain already on the server unchanged the push is `no new changes` and the mark
  stays; then WIP is lifted with START REVIEW in Gerrit.
- `no new changes` is not an error: the script goes on to the server check.

## Tags and release branches

- Release branch: `--target release/X.Y.Z`. First check the
  branch has the CI: `git ls-tree --name-only origin/release/X.Y.Z | grep -E '^(Dockerfile|\.jenkins)$'`.
- Branch cut and tag: the commands are in [Release](../../../phone/docs/guides/release.md#the-steps)
  and [Patching a released version](../../../phone/docs/guides/hotfix_builds.md#the-steps).
  A tag goes with `git push --no-verify origin refs/tags/X.Y.Z+N`, then
  `git ls-remote --tags origin | grep -F 'X.Y.Z+N'`. The script is not for tags.

## Before handing over

- Every commit is on the server with `revision` equal to the local commit (step 5).
- `ssh -p 29418 git.portaone.com gerrit query --format=TEXT status:open topic:WT-1234` lists
  exactly the changes you meant - no second change opened by a lost `Change-Id`.
- The Jenkins votes, once in: [Reading the result](../../../docs/gerrit_checks.md#reading-the-result).

## Traps

- A push with hooks exits 141 with nothing on the server - use the script, not `git push`: [The push](../../../docs/gerrit_push.md#the-push).
- `gate | tail && git push` pushes past a failed gate - keep the exit code in a variable: [The push](../../../docs/gerrit_push.md#the-push).
- In a worktree the hooks read the wrong `GIT_DIR` (`0.0.0-unknown`) - run the gate as `env -u GIT_DIR`: [The push](../../../docs/gerrit_push.md#the-push).
- A tag pushed under lefthook runs the gate and is not created - `--no-verify` and `ls-remote`: [The push](../../../docs/gerrit_push.md#the-push).
- `Connection refused` on 29418 is the server - wait, do not switch to HTTPS: [The push](../../../docs/gerrit_push.md#the-push).
- `origin/master` moved under you and others' files look deleted - rebase, gate again: [The push](../../../docs/gerrit_push.md#the-push).
- `--amend -F` with a file lacking `Change-Id` opens a second change: [The commit message](../../../docs/gerrit_push.md#the-commit-message).
- `git commit --no-verify` skips the `Change-Id` hook too: [The commit message](../../../docs/gerrit_push.md#the-commit-message).
- Another ticket id in the body links the commit to that ticket: [The commit message](../../../docs/gerrit_push.md#the-commit-message).
- A red gate, even one already red on `master`, is fixed first in its own change: [The gate](../../../docs/gerrit_push.md#the-gate).
- A gate that finished in seconds scoped itself by a stale local `master` - name the commands: [The gate](../../../docs/gerrit_push.md#the-gate).
- `phone-semantics` and `callkeep-android-test` can pass without checking anything: [The gate](../../../docs/gerrit_push.md#the-gate).
- `git wip` / `git review` send no topic - the script adds it: [Git](../../../AGENTS.md#git).
- A wrong topic is not fixed by pushing again - `gerrit set-topic`: [Gerrit](../../../docs/gerrit_push.md#gerrit).
- What gets merged is the server's patchset, not an unpushed amend: [Gerrit](../../../docs/gerrit_push.md#gerrit).
- "Conflicts With" is a forecast - test with `git merge-tree` before rebasing: [Gerrit](../../../docs/gerrit_push.md#gerrit).
- `recheck` does nothing; a rerun needs a new patchset: [Scope](../../../docs/gerrit_checks.md#scope).
- -1 from every job at once, or on an old release branch, is the CI: [Fails for reasons outside the change](../../../docs/gerrit_checks.md#fails-for-reasons-outside-the-change).
- A published tag cannot be moved or deleted - the fix is the next `+N`: [Rules](../../../phone/docs/guides/release.md#rules).
