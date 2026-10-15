# The callkeep dependency

`webtrit_callkeep` is always declared as `path: ../callkeep/webtrit_callkeep`, never as a git ref,
on `master` and on every `release/*` branch alike. callkeep lives in `callkeep/` of this repository
and is not tagged, so a phone commit carries the callkeep it builds with and the build fetches
nothing separately.

Nothing enforces it: no Jenkins job checks the dependency. Check by hand with `grep -A4 '^  webtrit_callkeep:' pubspec.yaml`: it must show `path:`
and no `git:`.
