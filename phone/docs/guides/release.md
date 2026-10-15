# Release

How a new version of the app is cut: version bumps on `master`, a release branch, and a tag. A fix
to a version already cut is in [Patching a released version](hotfix_builds.md); the build and the
store uploads are in [Build](build.md); how callkeep is declared on `master` and on release
branches is in [The callkeep dependency](../reference/callkeep_dependency.md). The push form used
below is in [Pushing to Gerrit](../../../docs/gerrit_push.md).
Last reviewed: 2026-10-15.

## The steps

One release ticket covers the whole release: every release commit and its topic carry its id.

1. **Bump on `master`.** In a branch off `origin/master`:
   - if `callkeep/` changed since the previous release tag, `WT-1234 Bump callkeep to A.B.C`:
     `version:` in `callkeep/webtrit_callkeep/pubspec.yaml` and the `version:` of the
     `webtrit_callkeep` entry in `phone/pubspec.lock`;
   - then `WT-1234 Release X.Y.Z`: `app_version: X.Y.Z+0` in `phone/pubspec.yaml`.

   Push both for review to `refs/for/master`, and get them merged.
2. **Cut the branch** at the merge commit of those bumps on `master`:

   ```sh
   git push --no-verify origin <merge commit>:refs/heads/release/X.Y.Z
   ```

3. **Tag the same commit**, annotated:

   ```sh
   git tag -a X.Y.Z+0 <merge commit> -m 'Release X.Y.Z'
   git push --no-verify origin refs/tags/X.Y.Z+0
   git ls-remote --tags origin | grep -F 'X.Y.Z+0'
   ```

   `master`, the branch and the tag now agree. `master` keeps `app_version: X.Y.Z+0` until the
   next release; patch rounds raise `+N` on the branch only.

Bump on `master` first, then branch. When the bumps went onto the release branch only, `master`
missed them and needed them cherry-picked afterwards.

To see whether `callkeep/` changed since the previous release:
`git diff --stat <previous tag> origin/master -- callkeep`.

The tag reaches the GitHub mirror `github.com/portaone/porta-phone-mobile-app` within a minute,
and the configurator offers phone refs from tags; pinning the version there is the same as for a
patch ([Patching a released version](hotfix_builds.md)). Check the mirror with:

```sh
git ls-remote --tags https://github.com/portaone/porta-phone-mobile-app.git | grep -F 'X.Y.Z+0'
```

## Rules

**`app_version` equals the tag exactly, `+N` included.** Every release and patch tag so far
carries the `app_version` of its own name: `1.18.0+2` is a commit with `app_version: 1.18.0+2`.
A tag on a commit whose version was not bumped produces a build that reports a version its tag
does not carry, and the app's version gate (`lib/features/version_gate/`) compares against that
reported version.

**A published tag cannot be corrected.** Besides the policy in
[Patching a released version](hotfix_builds.md), the server refuses it for a normal user:

```
git push origin :refs/tags/X                -> prohibited by Gerrit: not permitted: delete
git push --force origin <sha>:refs/tags/X   -> prohibited by Gerrit: not permitted: force update
```

So there is no re-cutting the same version. A tag on the wrong commit is superseded by the next
build number: bump `app_version` to `+1` in a change of its own, and tag its merge commit. The
wrong tag stays as a version that was never built, which is cheaper than one name meaning two
commits. `1.16.6+0` is such a tag.

## Tags in a local clone

**Local tags are not what the server has.** A clone that predates the move to Gerrit holds over a
thousand tags from the GitHub era (`v1.15.*`, `*_apk_*`, `shorebird-*` and others) that no remote
carries, because git never prunes tags on its own. Ask the server:

```sh
git ls-remote --tags origin
```

**`git tag --contains` is wrong for old releases.** The migration rewrote history, so the old
tags point at commits that are not ancestors of `master`. Find which release first carried a
change by content instead:

```sh
git show "$(git rev-parse '1.16.5^{commit}'):lib/app/router/app_router.dart" | grep -c '<marker>'
```

**Old tags have the old layout.** Before the monorepo the app sat at the root (`lib/...`); now it
is `phone/lib/...`. A script that walks tags has to try both paths.

**In zsh, brace the variable in a ref expression.** In `"$c:lib/..."` zsh reads `:l` as a
modifier (lowercase) and the path arrives mangled; write `"${c}:lib/..."`.
