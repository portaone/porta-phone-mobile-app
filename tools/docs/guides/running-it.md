# Running it

## From a checkout

```sh
dart pub global activate --source=path .
webtrit_phone_tools --help
```

What a build runs, and in what order, is [the commands](../reference/commands.md).

## The checks a change runs

Lefthook from the repository root, and in Gerrit the Jenkins job
`gerrit_check_tools`, which votes on every patchset and runs `dart test` only
when the patchset touches `tools/`, `analysis/`, `phone/packages/theme_schema/`,
the root `Dockerfile` or `.dockerignore`, or the job's own Groovy file.

```sh
dart format --output=none --set-exit-if-changed <staged files>   # lefthook, on commit
dart analyze                                                     # lefthook, on push
dart test                                                        # lefthook on push, and Jenkins
```

No hook or job runs a spell check or the `version-verify` test
(`test/ensure_build_test.dart`), which is skipped unless `--run-skipped` is given. Nor
`dart run tool/docs_gate.dart`, which checks that every link in these docs resolves and every
page is reachable from `README.md`; run it by hand after editing them.

Two path dependencies, both in this repository: `theme_schema`
(`../phone/packages/theme_schema`), declared but imported by nothing under
`lib/`, and the lint rules, `webtrit_analysis` (`../analysis`).
