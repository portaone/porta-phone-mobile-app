# Release Process

How a `webtrit_callkeep` release is versioned. It is not tagged: the app depends on it by path
(`phone/pubspec.yaml`, `path: ../callkeep/webtrit_callkeep`), so it ships inside every app release.

## Versioning model

This is a federated plugin monorepo. The consumer-facing package is the umbrella
**`webtrit_callkeep`** - its `version:` is the release version of the whole plugin.

The platform packages (`webtrit_callkeep_android`, `webtrit_callkeep_ios`,
`webtrit_callkeep_platform_interface`, `..._macos`, `..._linux`, `..._web`, `..._windows`) are internal,
wired together by relative paths, and are **not** independently versioned: android, ios,
platform_interface and web stay at `0.0.0+0`, the linux/macos/windows stubs at `0.1.0+1`.
Only the umbrella carries the meaningful version.

Versions follow `X.Y.Z+N` (semantic version `X.Y.Z` plus an optional build number `N`).

## Cutting a release

1. At an app release cut, bump the umbrella version in `webtrit_callkeep/pubspec.yaml` to
   `X.Y.Z+N` in a commit of its own, `<TICKET-ID> Bump callkeep to X.Y.Z`. It changes that
   `version:` line and the `webtrit_callkeep` entry of `phone/pubspec.lock`. (Platform package
   versions are left as they are.)
2. No tag is created.
