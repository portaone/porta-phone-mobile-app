# webtrit_analysis

Lint rules for Dart and Flutter, shared as the package `webtrit_analysis`.

`tools/` takes it as a dev dependency by `path: ../analysis` and includes
`package:webtrit_analysis/analysis_options.yaml` in its `analysis_options.yaml`.

[lib/analysis_options.yaml](lib/analysis_options.yaml) only includes the current versioned
file, [lib/analysis_options.1.0.1.yaml](lib/analysis_options.1.0.1.yaml); include a
versioned file directly to pin the rules.
