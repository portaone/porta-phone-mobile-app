# Patching a released version

How a fix reaches a version that is already cut, without becoming a new version.

Last reviewed: 2026-09-06

For the build itself see [Build](build.md).

---

## The shape of a patch

A patch keeps the release's name and raises its build number. `pubspec.yaml` carries two
version fields and only one of them moves:

| Field | Value | Moves on a patch |
|---|---|---|
| `version:` | `0.0.0+0` by convention, never edited | no |
| `app_version:` | the release version, `X.Y.Z+N` | yes, `+N` only |

So `1.16.5+0` becomes `1.16.5+1`. The release is still 1.16.5; the store and the phone version
registry tell the two builds apart by the build number.

---

## The steps

On `release/X.Y.Z`:

1. Cherry-pick the fix from `master`. Take the commit that is already merged there - a patch is
   never the first place a fix lands, because then it would be missing from the next release.
2. Raise `app_version` to `X.Y.Z+N`.
3. Push the change for review to `release/X.Y.Z` and submit it.
4. **Tag the merged commit `X.Y.Z+N` by hand**, annotated, and push the tag.
5. Pin `X.Y.Z+N` in the configurator and leave the `X.Y.Z` registration as it is (the
   configurator backend's `docs/reference/api/phone-versions.md`, "Pinning a patch build").

Step 4 is the one that is easy to skip and the one that everything downstream needs. See below.

---

## The tag nobody creates

Nothing creates it: no Jenkins job tags a commit. A patch therefore never produces a tag on its
own.

The configurator offers phone refs from tags and nothing else, and both the build (including the
one testers are given) and the scan that pins a phone version point at a ref from that list. A
patch commit without its own tag cannot be built, tested or pinned.

---

## Never move a published tag

Re-pointing `X.Y.Z` at the patch would leave one entry in the picker, which is tempting, and it is
still wrong: the build already shipped under that tag stops being reachable by name, and anyone who
fetched it keeps a different commit under the same name. Tags here are immutable. A patch gets its
own.
