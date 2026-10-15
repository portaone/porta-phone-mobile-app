# Pinning the Callkeep Version

This document describes how WebTrit Phone pins its
[`webtrit_callkeep`](../../callkeep/webtrit_callkeep) dependency, so that
`git checkout release/A.B.C` plus `flutter pub get` always reproduces the same build.

> Scope: the phone side only - how a phone branch *consumes* callkeep. callkeep lives in
> `callkeep/` of this repository and is not tagged: a phone commit carries the callkeep it builds
> with.
>
> For the Flutter SDK version see [build.md](build.md).

---

## Why this exists

A given phone release is compatible with exactly **one** callkeep version. Historically that
mapping lived only in people's heads, and CI let the operator pick the callkeep branch by hand at
build time - so a release could silently be built against the wrong callkeep. This removes the
manual choice: callkeep is part of the same commit as the phone, and the build trusts it.

---

## How the dependency is declared

### Release branches - local path

On every `release/*` branch the umbrella dependency is the same relative path as on `master`
(below). A checkout of the release branch carries callkeep at the same commit, so the build is
fully deterministic and needs nothing fetched.

### master - local path

On `master` the dependency stays a relative path, because callkeep is co-developed alongside the
phone in this repository:

```yaml
dependencies:
  webtrit_callkeep:
    # master tracks the working copy of callkeep in this repository for co-development.
    # Release branches use the same path; callkeep is not tagged (see docs/release_versioning.md).
    # On master this is always a path (no check enforces it).
    path: ../callkeep/webtrit_callkeep
```

**Back-merge rule:** on `master` this dependency is **always** `path:`.

---

## Cutting a phone release

On the phone `release/A.B.C` branch set the phone version (`A.B.C`); the callkeep dependency
stays as it is.

`master` is left untouched (still `path:`).

---

## CI / build behaviour

The `porta-phone-mobile-app-cicd` build trusts `pubspec.yaml`:

- **Release builds** - `pubspec.yaml` carries `path:`, and the build checks out this repository at
  one ref, so callkeep is already where the path points. There is no manual callkeep branch
  selection.
- **master builds** - the same: nothing checks callkeep out separately.

---

## Enforcement

Nothing enforces it: no Jenkins job checks the callkeep dependency, and the
`callkeep-path-guard` and `callkeep-pin-guard` workflows under `.github/` do not run - GitHub is
only a read-only mirror of Gerrit. Check by hand with
`grep -A4 '^  webtrit_callkeep:' pubspec.yaml`: it must show `path:` and no `git:`.

---

## Quick reference

| Branch type | callkeep in `pubspec.yaml` | Resolves to |
|-------------|----------------------------|-------------|
| `master`    | `path: ../callkeep/webtrit_callkeep` | `callkeep/` of the same checkout |
| `release/*` | `path: ../callkeep/webtrit_callkeep` | `callkeep/` of the same checkout |
