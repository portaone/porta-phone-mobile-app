# Fonts

How the app gets the typeface a theme names, from the build that fetches it to the text that is
drawn with it.
Last reviewed: 2026-10-07.

## Path of a typeface

```
theme: fonts.fontFamily
   |
   |  white-label build (tools: FontAssetProcessor)
   v
assets/fonts/<Family>-<Weight>.ttf        one file per weight, straight in the directory
   |
   |  startup (AppThemes.init -> AppFonts.load)
   v
one family named <Family>, every weight in it
   |
   |  theme (TextThemeDataFactory -> AppFonts.textTheme, ThemeProvider -> AppFonts.typography)
   v
every text style names <Family> and asks for regular or bold; the engine picks the face
```

## Theme setting

`fonts.fontFamily` in the widget configuration (`assets/themes/original.widget.<appearance>.config.json`)
names one family from [Google Fonts](https://fonts.google.com/). The name is trimmed on both
sides of the path. A build carries the family of the light appearance; a dark appearance naming
another one is drawn in the platform typeface.

A style inside the theme may name a family of its own (`textStyle.fontFamily`). Only the one
family is bundled, so any other name falls back to it.

## Build step

[`tools/lib/src/commands/app_resources/processors/font_asset_processor.dart`](../../tools/lib/src/commands/app_resources/processors/font_asset_processor.dart)
runs as the `font` step of `configurator-resources`:

- It fetches the weights 400, 500, 600 and 700 - the ones the app draws whatever the theme says -
  plus every other weight the theme names. A weight the family does not have is skipped; the app
  draws it with the nearest one.
- The files go straight into `assets/fonts/`, the directory `pubspec.yaml` declares. An asset
  directory is not recursive: a file in a folder below it never reaches the bundle.
- The directory holds exactly this build's typeface. Faces and the licence of an earlier build are
  removed first, also when this build fetches nothing; nothing is written until every face has
  been fetched; a request the network or the service fails is made up to three times.
- A step that fails leaves the directory without faces and the build goes on: the app is then
  drawn in the platform typeface.

A development checkout has no faces in `assets/fonts/` and is drawn in the platform typeface.

## AppFonts

[`lib/theme/app_fonts.dart`](../lib/theme/app_fonts.dart) holds everything the app knows about
its typeface and is the only place that uses the `google_fonts` package.

- `AppFonts.load(families)` runs once in bootstrap, inside the `app-themes` stage. It turns
  runtime fetching off and registers the bundled faces of the families the theme names as ONE
  family each, under the theme's name. The family is the file name up to its last hyphen; the
  weight is read from the face itself. Nothing here stops the start: a manifest or a face that
  cannot be read leaves the platform typeface.
- `AppFonts.textTheme(family, base)` builds the text theme:
  - the family is loaded: every style names it, and the weight of each text is matched by the
    engine when it is drawn - for a style of the theme, for a `copyWith(fontWeight: ...)` on one
    and for a style a theme document spells out;
  - the family is not loaded and the app may not fetch: the platform typeface, and `google_fonts`
    is not asked at all;
  - the family is not loaded and fetching is allowed: `google_fonts` fetches it. This is the route
    of a host that draws the app without its bundle, the configurator's preview. It binds every
    style to the regular face, so weights in that preview are not the app's.

Where a typeface comes from is the business of `AppFonts` alone: callers pass family names and
get a text theme back, so the source can change without touching them.

Measured cost of `AppFonts.load` with four faces of 180 KB each, Samsung M32, profile build, cold
start: the `app-themes` stage takes 40 ms instead of 24 ms, and the Dart startup total 470-485 ms
instead of 463-464 ms. See [startup_performance.md](startup_performance.md) for how to measure.

## Type scale

Text may be in a script the theme's typeface has no letters for - a name, a note, a translation.
The platform then draws it with a typeface of its own, at the weight asked, and for most scripts
it has a regular and a bold face with nothing between: a name asked at 500 came out bold beside a
Latin name in a medium face.

Regular and bold exist for every script and in any typeface a brand picks, so the type scale of
the app asks for nothing else. `AppFonts.typography` takes the Material type scale and moves every
weight of it to the nearer of the two - below 600 to 400, from 600 up to 700 - and
`ThemeProvider` builds the theme with that scale. This is the one place the rule lives: a widget
takes a style of the theme (`titleMedium`, `labelLarge`) as before and needs to know nothing of it.

A widget that sets a weight of its own between the two (`FontWeight.w600`) is outside the rule:
the theme's typeface draws it semi-bold, a platform face without that weight draws it bold.

The scripts still do not look identical: a platform face has a design of its own and may be
darker than the theme's at the same weight.

## Verification

- Unit tests: `test/theme/app_fonts_test.dart`, `test/theme/app_fonts_text_theme_test.dart`,
  `test/theme/app_fonts_typography_test.dart`; the build step in `tools/test/src/commands/app_resources/processors/font_asset_processor_test.dart`.
- A built APK carries the faces as `assets/flutter_assets/assets/fonts/<Family>-<Weight>.ttf`.
