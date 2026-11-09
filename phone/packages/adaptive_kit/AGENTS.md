# adaptive_kit

One app across a watch, a phone and later a larger screen: which device class a window is, one
decision point between a screen's arrangements, and the screen shapes and parts a watch face
needs. Depends on `material_ui` and `provider` only, so a part here knows no feature, theme
model or plugin of the app. How screens use it: [adaptive_layout.md](../../docs/architecture/adaptive_layout.md).

## Public API

`package:adaptive_kit/adaptive_kit.dart` exports everything; the sources sit in `lib/src`.

- Device class: `FormFactor`, `FormFactorBreakpoints`, `AdaptiveLayout`, `AdaptiveMetrics`.
- Face shape: `ScreenShape`, the value the app provides to the tree, and the `BuildContext`
  extension that answers `isRoundScreen`. Without a value, a square window of watch size counts
  as round.
- Screen shapes: `WatchActionLayout`, `WatchEdgeLayout`, `WatchScrollList`, `WatchIconGrid`,
  `WatchStatePage`.
- Parts: `WatchEdgeButton`, `WatchRoundButton`, `WatchKeyGrid`, `WatchListTile`, `WatchListNote`, `WatchPill`, `WatchPillButton`,
  `WatchTitle`, `WatchLink`, `WatchToggleChip`, `WatchSpinner`, `WatchSeparator`, `WatchFadeMask`,
  `WatchStadiumFields`.
- `SemanticAction`: one semantics node for an action, used across the app too.

What stays in the app, because it needs the app: `queryScreenShape()` (asks `device_profile`),
`WatchLogo` (the theme's images), `watchDialKeys` (the app's keypad model).

## Tests

`flutter test` here. They run on the watch faces in `test/helpers/screen_presets.dart`, the only
copy of the presets; the app's tests reach the same file through their `test/helpers`.
