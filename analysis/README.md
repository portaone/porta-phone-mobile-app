# webtrit_analysis

Lint rules for Dart and Flutter, shared as the package `webtrit_analysis`.

`tools/` takes it as a dev dependency by `path: ../analysis` and includes
`package:webtrit_analysis/analysis_options.yaml` in its `analysis_options.yaml`.

[lib/analysis_options.yaml](lib/analysis_options.yaml) only includes the current versioned
file, [lib/analysis_options.1.0.1.yaml](lib/analysis_options.1.0.1.yaml); include a
versioned file directly to pin the rules.

A rule change never edits a released file: it adds `lib/analysis_options.X.Y.Z.yaml` (and the
same `version` in `pubspec.yaml`) and switches the include in `lib/analysis_options.yaml` to it.
That changes what `dart analyze` reports in `tools/`: the `tools-analyze` hook runs only when a
push touches `tools/`, and the Jenkins tools check, which a change here triggers, runs
`dart test` only - so run `dart analyze` in `tools/` by hand.
