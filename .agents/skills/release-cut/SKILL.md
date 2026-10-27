---
name: release-cut
description: Prepare an app release X.Y.Z+0 or a patch build X.Y.Z+N - the callkeep version bump, the app_version bump, the release/X.Y.Z branch and the annotated tag - and show the push commands for the release owner. Load when a request says cut a release, release branch, release/X.Y.Z, tag a version, patch build, hotfix, +N, app_version or bump callkeep.
---

# Release cut

When: a new version is cut from `master`, or a fix goes into a version already cut as `X.Y.Z+N`.
The process is [release.md](../../../phone/docs/guides/release.md) and
[hotfix_builds.md](../../../phone/docs/guides/hotfix_builds.md); the push form is
[gerrit_push.md](../../../docs/gerrit_push.md). One release ticket (`WT-1234` below) covers every
commit and the topic.

Pushing a branch or a tag is the release owner's step and cannot be undone. Prepare the commits
and print the exact commands; run a push only when explicitly asked to run that push.

## Steps: a new release X.Y.Z+0

1. Branch off `origin/master`: `git fetch origin && git switch -c WT-1234-release-X.Y.Z origin/master`.
2. Find the previous release tag on the server (`git ls-remote --tags origin`, not `git tag`),
   fetch it (`git fetch origin tag <prev>`) and check callkeep:
   `git diff --stat <prev> origin/master -- callkeep`.
3. If `callkeep/` changed, commit `WT-1234 Bump callkeep to A.B.C`: `version:` in
   `callkeep/webtrit_callkeep/pubspec.yaml` and the `version:` of the `webtrit_callkeep` entry
   in `phone/pubspec.lock` (`grep -n -A6 '^  webtrit_callkeep:' phone/pubspec.lock`).
4. Commit `WT-1234 Release X.Y.Z`: `app_version: X.Y.Z+0` in `phone/pubspec.yaml`. Leave
   `version: 0.0.0+0` as it is.
5. Confirm callkeep is still a path dependency:
   `grep -A4 '^  webtrit_callkeep:' phone/pubspec.yaml` shows `path:` and no `git:`.
6. Show the push: `scripts/gerrit-push.sh --dry-run`. Run it without `--dry-run` only when asked.
7. After both are merged, find the merge commit on `origin/master` and check it:
   `git fetch origin && git show <commit>:phone/pubspec.yaml | grep '^app_version:'` prints
   `app_version: X.Y.Z+0`.
8. Print, for the release owner, the branch, tag and checks:

   ```sh
   git push --no-verify origin <commit>:refs/heads/release/vX.Y.Z
   git tag -a X.Y.Z+0 <commit> -m 'Release X.Y.Z'
   git push --no-verify origin refs/tags/X.Y.Z+0
   git ls-remote --tags origin | grep -F 'X.Y.Z+0'
   git ls-remote --tags https://github.com/portaone/porta-phone-mobile-app.git | grep -F 'X.Y.Z+0'
   ```

## Steps: a patch build X.Y.Z+N

1. The fix is merged on `master` first; take that merged commit.
2. Check the branch can be verified:
   `git ls-tree --name-only origin/release/X.Y.Z | grep -E '^(Dockerfile|\.jenkins)$'` prints both.
3. Branch off `origin/release/X.Y.Z`, `git cherry-pick -x <master commit>`, and raise
   `app_version` in `phone/pubspec.yaml` to `X.Y.Z+N` (only `+N` moves).
4. Show the push: `scripts/gerrit-push.sh --dry-run --target release/X.Y.Z`; push only when asked.
5. After the merge, check `app_version` on the merged commit as above, then print for the
   release owner the annotated tag `X.Y.Z+N` on it, its `--no-verify` push and the `ls-remote` check.
6. Pinning `X.Y.Z+N` in the configurator follows [hotfix_builds.md](../../../phone/docs/guides/hotfix_builds.md).

## Before handing over

- `app_version` on the commit to be tagged equals the tag name exactly, `+N` included.
- `master` carries the bumps of a new release, not only the release branch.
- The commits, target branch and topic in the dry-run output are the ones intended.
- Every printed push of a tag or branch has `--no-verify` and is followed by `ls-remote`.

## Traps

- A pushed tag or branch cannot be moved or deleted: a wrong tag costs a new `+N` - [release.md](../../../phone/docs/guides/release.md).
- Pushing a tag under lefthook runs the gate and may not create the tag: push with `--no-verify`, check `ls-remote` - [gerrit_push.md](../../../docs/gerrit_push.md).
- Bumps made on the release branch only leave `master` behind: bump on `master`, then branch - [release.md](../../../phone/docs/guides/release.md).
- A tag on a commit whose `app_version` differs reports the wrong version to the version gate - [release.md](../../../phone/docs/guides/release.md).
- A patch is never the first place a fix lands, and nothing tags it for you - [hotfix_builds.md](../../../phone/docs/guides/hotfix_builds.md).
- A release branch cut before `.jenkins/` and `Dockerfile` gets -1 from every check - [gerrit_checks.md](../../../docs/gerrit_checks.md).
- callkeep is not tagged and is never a git ref, on `master` or a release branch - [callkeep_dependency.md](../../../phone/docs/reference/callkeep_dependency.md).
- Local tags include GitHub-era tags the server lacks, and `git tag --contains` is wrong for old releases - [release.md](../../../phone/docs/guides/release.md).
- On a branch off a release branch the gate may scope itself against a stale local `master` and pass in a second - [gerrit_push.md](../../../docs/gerrit_push.md).
- Pushing again with `%wip` puts WIP back on a change already in review; `gerrit-push.sh` refuses by default - [gerrit_push.md](../../../docs/gerrit_push.md).
- `+` in a tag name is a regex character: use `grep -F` - [gerrit_push.md](../../../docs/gerrit_push.md).
