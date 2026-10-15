# Reworking a Gerrit chain

Gerrit reviews a chain commit by commit, and each commit gets its own Verified vote. This page is
about changing commits that are not on top - one patchset to a lower commit, or rebuilding a whole
chain into commits that describe the final state - without losing the `Change-Id`s or re-checking
what did not change. The Gerrit basics are in [AGENTS.md](../AGENTS.md); the push itself is in
[Pushing to Gerrit](gerrit_push.md).

## A new patchset on a lower commit

Review touched the first of two commits. Without an interactive rebase, rebuild the chain by hand.
Every message keeps its `Change-Id`, so the push updates both changes:

```sh
git log -1 --format=%B <first>  > /tmp/msg1.txt
git log -1 --format=%B <second> > /tmp/msg2.txt
git checkout --detach <first>
git add <fixes>; git commit --amend -F /tmp/msg1.txt
git cherry-pick <second>
git commit --amend -F /tmp/msg2.txt                 # only if the second needs edits too
git branch -f <branch> HEAD && git checkout <branch>
git log -2 --format=%B | grep '^Change-Id:'         # both ids, unchanged
```

Renaming commits of a chain is the same walk with only the messages changed; then
`git diff --stat <old tip> HEAD` is empty. The push updates both changes, and a new patchset of
the lower change drops its previous Code-Review +2, so it needs approving again.

## Rebuilding a chain into final-state commits

A chain grown over days has commits that add what a later one removes, and the reviewer reads code
the branch does not end with. Squashing is the wrong answer when the layers are separately
reviewable; what is wrong is only that some describe an intermediate design.

Precondition: rebuilding throws away votes and comment threads. Do it only on a chain that is
still WIP, or that only you have touched.

Decide the target shape first: which changes survive, which `Change-Id` each keeps, which are
abandoned. Then build each commit from the final state of the paths it owns, not by replaying
diffs:

```sh
git branch -f WT-1234-final HEAD        # the tree to end with, kept on a branch
git checkout -B WT-1234-rebuilt <base>  # the merge-base with master

git cherry-pick <c1>                          # an unchanged layer
git cherry-pick <c2>
git checkout WT-1234-final -- <paths c2 owns> # pull in their final state
git commit --amend -F msg2.txt                # carries c2's Change-Id

git checkout WT-1234-final -- <paths c3 owns> # a layer rebuilt from scratch
git commit -F msg3.txt                        # Change-Id pasted from the old change

git checkout WT-1234-final -- phone/          # the last layer takes what is left
git checkout HEAD -- phone/docs/              # minus what a later layer owns
git commit -F msg4.txt
```

Then prove that only history changed:

```sh
git diff --stat WT-1234-final HEAD      # must be empty
```

Delete the `-final` branch once that is empty. Abandon the emptied changes with a message saying
where their content went, or the next reader takes an abandoned change for a rejected idea.

## Re-running the gate

Run the gate on every commit, not only the tip: Jenkins votes on each change, and an intermediate
commit that does not build is a real defect.

```sh
for c in $(git rev-list --reverse <base>..<branch>); do
  git checkout -q "$c" && lefthook run pre-push --all-files || echo "FAILED: $c"
done
```

`--all-files` because a detached commit has no push destination, and lefthook would otherwise
scope the run by a diff against the local `master` (see
[Pushing to Gerrit](gerrit_push.md#the-gate)).

Two shortcuts are sound, one is not:

- **Only messages changed.** Compare `git rev-parse <c>^{tree}` of every commit with the version
  that already passed. All identical: only the subject check can fail, and one run on the tip is
  enough.
- **The same file added identically to every commit** (a doc, say): the tip passing proves the
  rest, because their code trees already passed.
- **Not sound:** "the tip passes, so the chain passes". An intermediate commit can fail to
  compile on its own, and the tip never shows it.

## Traps

**A dirty working tree blocks the rebase** with "Please commit or stash your changes", without
naming the file. Run `git status --porcelain` first and stash local edits (a `dart_define.json`
pointed at your own server, say).

**A final tree kept in a shell variable is lost with the shell.** `F=$(git commit-tree ...)`
leaves an unreachable commit, and finding it again takes `git fsck --unreachable` over the whole
repository. Keep it on a branch, as above.

**A message drifts from its code** when code moves between commits. Grep each message for what
the commit no longer contains.

**A scripted message rewrite loses paragraph breaks.** Check before committing:
`git log -1 --format=%B <c> | awk 'length > 72 {print NR": "length}'`.

**A refactor goes before the change of behaviour, not after it.** In the order "behaviour, then
extract a class from it", every later fix to the behaviour is written twice: once in the old
names for the middle commit and once in the new ones for the top. With the class extracted from
`master`'s code first and the behaviour on top, each fix is written once, and the refactor commit
really changes no behaviour.
