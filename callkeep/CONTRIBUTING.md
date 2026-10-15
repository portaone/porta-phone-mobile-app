# Contributing to Webtrit CallKeep

Commit form, Gerrit review and hook installation are the repository's: see the root [AGENTS.md](../AGENTS.md).

## Git Hooks

The callkeep commands of the root `lefthook.yml`:

- **pre-commit** - on staged files under `callkeep/`:
  - `dart format --line-length 120` on Dart files (generated files excluded); it reformats them
    and stages the result rather than only checking
  - `ktlint --format` on Kotlin files (`Generated.kt` excluded), staging the result
  - `markdownlint-cli2` on Markdown files
- **pre-push** - checks the commit subjects, then, when `callkeep/` changed:
  - `flutter analyze` on all key packages
  - `flutter test` in `webtrit_callkeep_android`
  - `./gradlew testDebugUnitTest` in `webtrit_callkeep_android/android`, skipped when
    `android/local.properties` is missing
