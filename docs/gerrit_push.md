# Pushing to Gerrit

The workflow itself - one commit per change, `Change-Id`, `--amend` for a correction, the
`git wip` / `git review` / `git ready` aliases - is in [AGENTS.md](../AGENTS.md). This page is the
push form that has proved reliable and the traps around it. Reworking a chain of several commits
is in [Reworking a Gerrit chain](gerrit_chain_rework.md); what Jenkins runs after the push is in
[Gerrit checks](gerrit_checks.md).

## The form

`scripts/gerrit-push.sh` does all of this: it checks that each commit has one `Change-Id`,
runs the gate, pushes with the ticket topic only if the gate passed, and compares what the
server holds with the local commits. `--dry-run` prints the commits, the target and the topic
and pushes nothing. By hand:

Run the gate on its own, push without hooks only if it passed, then ask the server what landed:

```sh
lefthook run pre-push > /tmp/pre-push.log 2>&1; gate=$?
[ "$gate" -eq 0 ] && git push --no-verify origin HEAD:refs/for/master%wip,topic=WT-1234
```

- `%wip` keeps the change a draft; `topic=` holds the changes of one ticket together. For a
  release branch the target is `refs/for/release/X.Y.Z`.
- `--no-verify` here only avoids running the gate twice. If anything changed after the gate
  (reword, amend, rebase), run the gate again.
- Keep the gate output whole in the file and filter the file. Truncating it with `tail` cuts off
  the reason for a failure.

Then check the server, not the push output:

```sh
ssh -p 29418 git.portaone.com gerrit query --format=JSON --current-patch-set change:<Change-Id>
```

`rowCount: 0` means nothing arrived. Otherwise the `revision` of the current patchset must equal
`git rev-parse HEAD`.

## The push

**A push with hooks can end with nothing on the server.** `git push` runs the pre-push gate, all
commands go green, lefthook prints its summary, and then `git push` exits with 141 (SIGPIPE) and
prints nothing from the remote. There are no `remote: SUCCESS` and `To ssh://...` lines, which is
easy to miss after thousands of lines of test output. The cause is not known; it happened with
output to a file and to a pipe alike. Use the form above.

**The exit code of a pipeline is that of its last command.** `lefthook run pre-push | grep ... |
tail && git push ...` pushes even when the gate failed, because `tail` succeeded. The same holds
for `( ...; tail )` in a subshell and for `set -e` inside a pipe. Put the gate's code in a
variable, as above, and keep file edits and `git commit` in separate commands.

**In a worktree, `git push` gives its hooks a `GIT_DIR` of the worktree.** A Flutter step inside a
hook that calls `git describe` then reads the wrong repository and the build version comes out as
`0.0.0-unknown`. `env -u GIT_DIR git push` does not help, because `git push` sets the variable
itself. Run the gate separately as `env -u GIT_DIR lefthook run pre-push`, then push with
`--no-verify`.

**Pushing a tag under lefthook can run the gate and not create the tag.** The full pre-push gate
runs (a tag carries no new code, so it checks nothing) and the tag does not appear on the server.
Push tags with `--no-verify` and check:

```sh
git push --no-verify origin refs/tags/1.18.0+2
git ls-remote --tags origin | grep -F '1.18.0+2'    # -F: the + in the name
```

**`Connection refused` on port 29418 is the server, not your keys.** The host answers and the
port is closed; it passes within minutes. Wait rather than switch to HTTPS:
`nc -z -G 5 git.portaone.com 29418 && echo reachable`. In a `cmd && cmd` chain the failed `git
fetch` stops the rest silently, so a check after it may never have run.

**`origin/master` moves without your `fetch`.** Worktrees share one `.git`, so a fetch from any
of them moves `origin/master` for all. `git diff origin/master..HEAD` suddenly shows other
people's files as deleted. Your commit is intact (`git show --stat HEAD`); rebase on the new
`origin/master` and run the gate again.

## The commit message

**`git commit --amend -F <file>` with a file that has no `Change-Id` creates a new change.** The
`commit-msg` hook finds no trailer and writes a new one, so the next push opens a second change
instead of a new patchset, and the old one stays open with stale content. Start the file from the
current message, which carries the trailer, and check before pushing:

```sh
git log -1 --format=%B > /tmp/msg.txt    # edit, keeping the Change-Id line
git commit --amend -F /tmp/msg.txt
git log -1 --format=%B | grep -c '^Change-Id:'    # must print 1, the same id as before
```

If it already happened, abandon the extra change with a message that names the one that
supersedes it: `ssh -p 29418 git.portaone.com gerrit review --abandon --message '"..."'
<change>,<patchset>`.

**`git commit --no-verify` also skips Gerrit's `commit-msg`.** The commit gets no `Change-Id` and
the push fails on `commit-subjects`. Amend it without `--no-verify` and the hook adds one.

**The subject check reports at the end of the gate.** `commit-subjects` runs first, but lefthook
runs every command even after one fails, so a 51-character subject surfaces only after the full
test suite. `scripts/commit-subject-check.sh` checks the subject (50 characters including the
ticket id) and every body line that contains a space (72); lines without a space and
`Key: value` trailers are exempt. Run it alone before the gate:

```sh
bash scripts/commit-subject-check.sh
```

**A ticket id anywhere in the message links the commit to that ticket.** The tracker integration
reads the whole message, not only the subject, so a commit that mentions another ticket in its
body shows up under that ticket after the merge. Describe the other work in words. Check before
pushing:

```sh
git log --format=%B origin/master..HEAD | grep -oE '[A-Z]+-[0-9]+' | sort | uniq -c
```

While the change is WIP the body can still be rewritten in a new patchset; after the merge it
cannot.

## The gate

**A red gate is not permission to push past it**, also when the failure is already on `master`.
Fix that failure first as a separate change, so the gate is green, then push your own.

**Reproduce a gate step with the command the gate runs.** `phone-analyze` is `flutter analyze`,
which fails on infos; `dart analyze` does not, so a clean `dart analyze` says nothing about the
gate.

**The gate decides what to run from the files of the push.** Each scoped command runs only when
its `glob` matches. A topic branch has no push destination, so `lefthook run pre-push` picks the
files itself, and with a stale or missing branch to compare against it scopes the gate wrongly -
on a branch cut from a release branch it has finished in under a second with a green summary.
Hand it the files of the commits instead; `scripts/gerrit-push.sh` does this:

```sh
git diff --name-only origin/master...HEAD | env -u GIT_DIR lefthook run pre-push --files-from-stdin
```

**Two commands pass without checking anything:**

- `phone-semantics` (`tool/scripts/semantics-gate.sh`) compares against `origin/develop`, which
  this repository does not have. It prints `no merge-base with origin/develop; skipping` and exits
  0. A change that adds controls needs a `*_semantics_test.dart` instead.
- `callkeep-android-test` prints `skipped: ...` and exits 0 when
  `callkeep/webtrit_callkeep_android/android/local.properties` is missing. Write it
  (`flutter.sdk=<path>`) before the first gate and look for `BUILD SUCCESSFUL` in that command's
  output.

**The hooks use the `flutter` on `PATH`, not `fvm`.** `phone/.fvmrc` pins the SDK for `fvm`, and
when the two differ they break each other's native-assets cache in `phone/.dart_tool/hooks_runner`:
whichever SDK ran first owns it, and the other fails within seconds with `Can't load Kernel
binary: Invalid SDK hash` / `Building assets for package:objective_c failed`. `phone-test` then
goes red with no relation to the code. Delete `phone/.dart_tool/hooks_runner` (it is rebuilt) and
let the gate run the tests first; do the `fvm` builds and checks before that, not during the gate.

**New l10n keys need two generators.** `flutter gen-l10n` writes `app_localizations*.g.dart`, but
`phone-l10n` (`tool/check_l10n.dart`) also checks `lib/l10n/app_localizations.g.mapper.dart`,
which `dart run build_runner build --delete-conflicting-outputs` writes. Without it the gate
reports `key ... is not covered by lookupKey`; analyze and the tests do not notice. Revert the
unrelated `.g.dart` files build_runner reformats on the way.

**A single failing test on a loaded machine may be load, not the change.** Under heavy load the
phone suite has failed once in `test/repository/log_records_repository_test.dart` and
`test/features/call/conference/conference_flow_test.dart`, and passed when the file ran alone and
on the next full run. Check the load (`uptime`) and run the file alone before looking for a cause
in the change.

## Gerrit

**A topic does not change by pushing the same commit again.** Gerrit answers `no new changes`.
Set it directly, without a new patchset:

```sh
ssh -p 29418 git.portaone.com gerrit set-topic <change> --topic WT-1234
```

**Pushing again with `%wip` puts WIP back.** If a reviewer has already lifted WIP (START REVIEW),
a new push to `refs/for/master%wip` marks the changes WIP again, and START REVIEW has to be pressed
a second time. Check the `wip` field first (`gerrit query --format=JSON topic:<T> status:open`)
and push without `%wip` when it is already lifted.

**What is merged is the patchset on the server, not your local amend.** An amend that was not
pushed before Submit is not in `master`, and it cannot be pushed afterwards: its `Change-Id`
belongs to a closed change. Before Submit, compare `gerrit query --current-patch-set` with
`git rev-parse HEAD`. A missed amend becomes a new commit on the new `master`, with a new
`Change-Id`.

**"Conflicts With" is not a conflict with `master`.** The block lists open changes that touch the
same files; it is a forecast, and a pessimistic one. Rebasing on the same `master` gives the same
commit and `no new changes`. Check the real state:

```sh
git fetch origin master refs/changes/<NN>/<change>/<patchset>
git merge-tree --write-tree origin/master FETCH_HEAD >/dev/null && echo clean || echo CONFLICT
```

Only a `CONFLICT` there calls for a rebase and a new patchset.

**An abandoned change can come back.** An abandoned change of a topic has been seen in `NEW`
again after the topic was submitted, showing a conflict. After merging a topic, query
`status:open topic:<T>`. Before abandoning it again, make sure it holds nothing unique:

```sh
git fetch origin refs/changes/<NN>/<change>/<patchset>
git diff --stat origin/master FETCH_HEAD -- <files>
```

`<NN>` is the last two digits of the change number.
