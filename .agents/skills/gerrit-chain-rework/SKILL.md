---
name: gerrit-chain-rework
description: Corrects, splits or rebuilds a chain of Gerrit changes already in review while keeping every Change-Id - a patchset on a lower commit, fixups folded in with autosquash, final-state rebuilds, the gate on every commit. Load it when a request says fix the first/lower commit, rework, split, reorder, rename a commit, fixup, squash, autosquash or rebuild the chain.
---

# Reworking a Gerrit chain

**When:** a commit that is not on top needs changing - a review answer, a new subject, a fix
folded into the commit it belongs to, one commit split into several, or a chain rebuilt so
each commit describes the final state.

## Steps

1. Commit any fixes on top first (as `--fixup` commits for that walk), then keep the tip on a
   branch, not in a shell variable:

   ```sh
   git status --porcelain                    # must be empty
   git merge-base origin/master HEAD         # <base> in the commands below
   git branch -f WT-1234-final HEAD
   ```

2. Pick the walk:
   - **One lower commit:** detach, amend with its own message, cherry-pick the rest, move the
     branch - [A new patchset on a lower commit](../../../docs/gerrit_chain_rework.md#a-new-patchset-on-a-lower-commit).
   - **Fixes for several commits:** commit each as `git commit --fixup=<target>`, then fold
     them in place: `git rebase --autosquash <base>` (git 2.44 or later folds them without an editor).
     The target keeps its message and `Change-Id`.
   - **Final-state rebuild:** decide which changes survive first; build each commit from
     `git checkout WT-1234-final -- <paths>` - [Rebuilding a chain](../../../docs/gerrit_chain_rework.md#rebuilding-a-chain-into-final-state-commits).
   - **Split:** follow the rules below, then the rebuild walk.
3. Check every commit carries one `Change-Id`, the one its change already has:

   ```sh
   git log --reverse --format='%h %(trailers:key=Change-Id,valueonly) %s' <base>..HEAD
   ```

4. Prove what changed: `git diff --stat WT-1234-final HEAD` is empty when only history moved
   (rename, autosquash, rebuild, split), and shows only the review fix otherwise.
5. Run the gate on every commit, not only the tip (`env -u GIT_DIR` in a worktree), plus
   `bash scripts/commit-subject-check.sh` - [Re-running the gate](../../../docs/gerrit_chain_rework.md#re-running-the-gate).
6. Delete `WT-1234-final` and push with the [gerrit-push](../gerrit-push/SKILL.md) skill -
   `--no-mark` for changes already in review.
7. A change left empty is abandoned with a message saying where its content went; abandoning
   is visible to reviewers, so confirm it with the person who asked first.

## Splitting rules

Each commit builds and passes its tests alone - the smallest self-contained change, not the
smallest diff. Always separate:

- a pure `git mv` from edits to the moved file (otherwise git loses the rename);
- formatting from content;
- removal of dead code from a change in behaviour;
- a protocol or contract change from renames;
- a fix that makes the CI or the gate green, as its own change at the bottom.

A refactor goes before the change of behaviour; an `and` in the subject usually means two
changes. A `-1` at the bottom holds everything above it, so 2-5 commits per ticket, and
independent parts go on separate branches off `origin/master` under one topic.

## Before handing over

- The step 4 diff is as expected and every message still describes its own commit's code.
- The gate passed on each commit, and `On the server:` lists every change with its new revision.

## Traps

- A dirty tree blocks the rebase without naming the file - stash first: [Traps](../../../docs/gerrit_chain_rework.md#traps).
- A final tree kept in a shell variable is lost with the shell - keep it on a branch: [Traps](../../../docs/gerrit_chain_rework.md#traps).
- `--amend -F` from a file without the old `Change-Id` opens a new change: [The commit message](../../../docs/gerrit_push.md#the-commit-message).
- A `fixup!` commit gets no `Change-Id`, so the push script refuses it - autosquash before pushing: [gerrit-push.sh](../../../scripts/gerrit-push.sh).
- A conflict on a middle commit during autosquash can drop part of a fix - the step 4 diff shows it: [Rebuilding a chain](../../../docs/gerrit_chain_rework.md#rebuilding-a-chain-into-final-state-commits).
- A message drifts from its code when code moves between commits - grep each message: [Traps](../../../docs/gerrit_chain_rework.md#traps).
- A scripted message rewrite loses paragraph breaks and wraps past 72: [Traps](../../../docs/gerrit_chain_rework.md#traps).
- Refactor after behaviour means every later fix is written twice: [Traps](../../../docs/gerrit_chain_rework.md#traps).
- "The tip passes" does not prove a middle commit builds: [Re-running the gate](../../../docs/gerrit_chain_rework.md#re-running-the-gate).
- A detached commit has no push destination - the gate needs `--all-files`: [The gate](../../../docs/gerrit_push.md#the-gate).
- Jenkins checks each commit at its own tree and paths only: [Scope](../../../docs/gerrit_checks.md#scope).
- Static state can leak between test files only in Jenkins' one process: [Passes locally, fails in Jenkins](../../../docs/gerrit_checks.md#passes-locally-fails-in-jenkins).
- A new patchset of a lower change drops its Code-Review +2: [A new patchset on a lower commit](../../../docs/gerrit_chain_rework.md#a-new-patchset-on-a-lower-commit).
- A rebuild throws away votes and comment threads - only on a WIP chain or one only you touched: [Rebuilding a chain](../../../docs/gerrit_chain_rework.md#rebuilding-a-chain-into-final-state-commits).
- A merged commit is never amended; a missed amend becomes a new commit: [Gerrit](../../../docs/gerrit_push.md#gerrit).
