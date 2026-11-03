# Adaptive layout

The rules for a screen with more than one arrangement - for a watch, a tablet
or a phone lying down: which axis decides what, the watch kit, and the
structure and tests every such screen follows. The landscape rules come from
the first screen that got a second arrangement, the active call screen (see
[`features/call_ux.md`](../features/call_ux.md), section "Landscape", for the
reference implementation). The next screens follow them rather than invent
the shape again.

Last reviewed: 2026-11-03.

## The adaptation axes

A screen adapts on two axes, and each is decided in exactly one place. A
screen hands the decider its arrangements and never reads the window size or
orientation itself:

| Axis | Values | Decided by | Decides |
|---|---|---|---|
| Device class | `watch`, `handset`, `large` | `AdaptiveLayout` (`packages/adaptive_kit`) | what the screen is made of |
| Orientation | portrait, landscape | `OrientationLayoutSelector` | how a handset screen is arranged |

```dart
AdaptiveLayout(
  handset: (_) => OrientationLayoutSelector(
    portrait: MyScreenPortrait(params: params),
    landscape: MyScreenLandscape(params: params),
  ),
  watch: (_) => MyScreenWatch(params: params),
)
```

Do not scatter `MediaQuery.size` or `MediaQuery.orientation` checks through
screens or blocks.

### Device class

`FormFactor.fromSize` (`adaptive_kit`) reads the
window size, and the numbers live only in `FormFactorBreakpoints`:

- `watch` - both sides under 300: every watch the configurator previews
  (round 192 and 227, Apple Watch 162x197 and 208x248);
- `large` - shortest side 600 or more, Material's tablet threshold;
- `handset` - everything else, a phone either way up.

It is decided by size, never by platform: the same build runs on Wear OS, on
plain Android in a watch body that reports no watch feature, and in the
configurator's device preview, where the platform is the browser.

`handset` is the only required arrangement. A class without its own falls
back to it, so screens move to a watch layout one at a time and every other
screen keeps working as before. Values follow the same rule:
`context.formFactor.resolve(handset: 24, watch: 8)`; spacing comes from
`context.adaptiveMetrics` (inset, gap, tap floor), whose handset values are
the ones the app always used.

Crossing a class boundary swaps the subtree under `AdaptiveLayout`, so the
bloc, controllers and anything the user typed live above it - the same rule
as "State stays on the screen" below.

### Screens with a watch arrangement

| Screen | Watch arrangement |
|---|---|
| Login landing (`features/login/view/login_mode_select_*.dart`) | One launch button in a branded build: logo and greeting in the middle, the button filling the bottom edge (`WatchEdgeButton`). A demo build or several buttons: the brand in the middle, the buttons on the bottom of the face, the custom-core sign-in last. Nothing at the top of the face. |
| Custom-core URL (`features/login/view/login_core_url_assign_*.dart`) | Proceed as the edge button; above it a short scrolling column - the field's prompt, the field (label `URL`), the sales contact - fading out over the button. No app bar (a watch goes back with a swipe), no logo. |

The watch parts of the kit, in `packages/adaptive_kit`. A screen's watch arrangement says what
to show; how it sits on a face comes from these.

Screen shapes:

- `WatchActionLayout` - a screen with one main action: content scrolling in a short column, an
  optional secondary action at its end, the main action as the edge button, the column fading
  out above it. Descriptions and plain text take the small body size, outlined fields the
  pill shape. `title:` opens the column with a `WatchTitle`; the main action is a
  `WatchAction` (a label, a callback, the screen's style, an automation id) or, when the
  button shows more than a label (a spinner), a `primary:` builder. The sign-in forms, the
  custom-core screen and the consent screens are built on it.
- `WatchScrollList` - a screen that is only a list (a menu, a list of choices): the padding a
  face needs and a fade into the bottom edge; with `bottom`, the choices sit on the bottom of
  the face and the rest is centred above them. As a page opened over another screen it takes
  a `title`, a `spacing` between its rows, and `opaque` for the page's own background.
- `WatchEdgeLayout` - a screen whose content stays put above one main action along the bottom
  (a call, a keypad): the body gets the face less the edge button's room, an optional
  `backdrop` fills the face behind it. The scrolling counterpart is `WatchActionLayout`.
- `WatchIconGrid` - a screen of round buttons with captions under a short title, three to a
  row (fewer, and larger, when there are fewer). On a round face the grid keeps to two thirds
  of the face, centred, the title above it, so the corner captions clear the bezel. A `header`
  widget can take the title's place; a cell without `onPressed` is shown disabled. The main
  hub, the ways in and a call's More are built on it.
- `WatchDrillIn` - a menu first; a choice opens the content on the whole face, going back
  returns to the menu. The ways in and the main hub are built on it.
- `WatchEdgeButton` - a screen's one action along the bottom of the face (of a screen that
  fills the window, with nothing under it). Its builder gets the style to merge over the
  button's own (`overlay.merge(themeStyle)`): the outline - `WatchEdgeButtonBorder`, a rounded
  top cut by the face circle, on a round face, a `StadiumBorder` on a rectangular one - and the
  label padding. `compact: true` is the thinner one a keypad uses. The content above leaves
  `WatchEdgeButton.reservedHeight(context)` free.

Parts:

- `WatchPill.style` - a full-width button inside a column (a list entry, a secondary action, a
  link): a pill at the 48-point tap floor, merged over the button's own style.
- `WatchRoundButton` - a round button with a short caption under it, one node named by its
  label: filled, tonal or outlined (`WatchRoundEmphasis`), on a light page or over the call
  (`WatchRoundTone.onDark`: light, translucent, solid when on). A screen's own style, such as
  a hangup's colours, wins. The grid's cells and a call's controls are built on it.
- `WatchKeyGrid` - twelve keys in four rows sharing the height, with no gaps; a held key enters
  its alternate (0 for +) unless `alternates` is off, as for a call's tones. The app gives it
  `watchDialKeys`, its keypad as the grid's `WatchKey`s.
- `WatchTitle` - a screen's short centred title, in place of an icon or an app bar.
- `WatchListTile` - one row of a watch list (a device, a call, a way to transfer): a pill at
  the tap floor with an icon, a title of up to two lines, a one-line subtitle and a trailing
  mark; one button for assistive technology. `selected` tints it, `outlined` marks the row
  the screen acts on.
- `WatchLink` - a link inside a column (a page to read): an underlined label at the tap floor,
  not a second pill competing with the screen's action.
- `WatchToggleChip` - a consent or a setting as one full-width pill with a small switch; one
  semantics node with the label, the state and the tap.
- `WatchLogo` (in the app, it needs the theme's images) - a themed logo fitted into a height,
  without the paddings the theme gives it for a phone. Only the landing shows a logo on a watch; the screens after it give the room to
  their content.
- `WatchFadeMask`, `WatchStadiumFields` - the fade and the pill fields the layouts above apply.

Geometry:

- `context.isRoundScreen` - a round watch face. Android answers it (`Configuration.isScreenRound`,
  read once at startup through the `device_profile` plugin and shared as `ScreenShape`); where
  nothing answers - the configurator's preview, tests - a watch whose window is square counts as
  round. `roundSafeInset(diameter)` keeps content inside the square inscribed
  in the face.
- `context.isSmallWatch` - a face below `FormFactorBreakpoints.smallWatchMaxShortestSide` (200);
  every size that differs between the small and the large faces switches on it.
- `context.watchContentPadding()` - the padding of content that does not scroll (the keypad, the
  landing's brand); `context.watchListPadding(minBottom:)` - of a scrolling list.
- `watchResizesForKeyboard` - false: the watch keyboard covers the whole face, so a watch
  scaffold does not shrink for it.

A screen's watch arrangement is built from stock widgets plus these; anything that needs a
painter of its own (text along the bezel, a bezel scroll indicator) is left out.

### Does it fit

`packages/adaptive_kit/test/helpers/screen_presets.dart`, reached from the app's tests through
`test/helpers/screen_presets.dart`, holds the configurator's devices
(`watchPresets`, `handsetPresets`, `largePresets`) and
`pumpCollectingOverflows`, which returns every overflow of a pumped screen
instead of failing on the first. A fit test runs a screen on every preset
with the shipped theme (`withShippedTheme` in `test/helpers/shipped_theme.dart`:
without it the logos and type that make a screen tall are missing) and keeps the screens it
does not fit yet in a known-overflow list; a preset leaves the list in the
change that makes the screen fit. The tests so far:
`test/features/login/login_mode_select_fit_test.dart` (fits everywhere, watches included),
`test/features/keypad/keypad_fit_test.dart` (watches still on the known-overflow list).

## Step 0: rotation is a product decision

The app is portrait-locked globally (`app/view/app.dart` sends
`PreferredOrientation.portrait` at startup through `OrientationsBloc`) and
unlocked per flow: `features/call/view/call_shell.dart` switches to
`PreferredOrientation.auto` while a call is on screen and back to portrait
after. A screen without an unlock never sees landscape, so adding an
arrangement starts with deciding - and wiring - where its flow unlocks
rotation, the way the call shell does.

## Delivery shape: two stacked changes

The call screen shipped as a stack, and the split is what made both halves
reviewable. Repeat it:

1. **Preparation, behavior-preserving.** Extract the screen's building
   blocks into standalone widgets, bundle the constructor traffic into one
   params object, move the screen body into `<screen>_portrait.dart`. The
   screen renders exactly as before - the change is judged on that claim, so
   keep any legacy landscape fallback alive in this half.
2. **The arrangement, almost purely additive.** A new
   `<screen>_landscape.dart`, the `OrientationLayoutSelector` swap, the
   landscape test suites, the feature-doc update. Reviewers read one new
   file and a two-line selector.

Commit the second on top of the first: Gerrit keeps the two as one relation
chain, and the second is submitted after the first.

## Structure rules

- **Blocks are dumb, screens compose.** A shared block (an info panel, an
  action grid) renders content and fires callbacks; it never decides where
  it stands or reads the orientation. Each arrangement file places the same
  blocks differently. Knobs like `hangupRowShown`/`padded` on the call
  action area are the pattern: the layout above turns off what it places
  itself.
- **One params object.** Everything the arrangements present and dispatch
  travels as a single object built once by the screen
  (`CallControlsParams` is the reference). A new control is one new field,
  not a change in every constructor on the way.
- **State stays on the screen.** Anything both arrangements show (the call
  screen's typed DTMF digits) is owned by the screen, exposed as a
  `ValueListenable`, and merely rendered by the arrangements - so rotation
  can neither lose nor duplicate it, and updating it repaints the listeners
  instead of rebuilding the screen.
- **Rebuild trigger.** Where the screen owns layers around the selector, an
  `OrientationBuilder` around the body guarantees the rebuild on rotation;
  the selector itself subscribes only to the orientation aspect.

## Layout rules for the landscape file

Hard-won on the call screen; treat them as defaults, not suggestions.

- **Budget from constraints, not from the screen size.** Landscape sizes
  derive from `shortestSide` (the height), so on a wide-but-low window they
  can outgrow the width. Zone widths come from `constraints.maxWidth` minus
  the real chrome.
- **Floor every tap target at `kMinInteractiveDimension`.** Zones shrink;
  buttons do not. Compute the zone width at which scaled buttons hit the
  floor and stop shrinking the zone there.
- **Fold, never vanish.** When a dedicated zone no longer fits (the call
  screen's isolated hangup on a split-screen window), fold its control back
  into the main grid so one scale carries everything down together. A
  control the user needs must never be budgeted away.
- **Text yields, buttons do not.** Long names, raised font scale: text
  wraps and tall content scrolls. Never put text and critical buttons under
  one `FittedBox` - the text's growth becomes the buttons' shrink.
- **`FittedBox(scaleDown)` is a guard, not a layout tool.** It backstops
  the degenerate window nobody designed for; the floors above must make it
  a no-op on real devices.

## Test conventions

- **The default 800x600 test surface IS landscape.** A suite that pins
  portrait behavior must say so (`pinPortraitSurface()` in the call harness
  is the pattern), or it silently tests the other arrangement.
- **A landscape suite and a landscape semantics suite** beside the portrait
  ones: zone order, controls that exist only there, activation through
  semantics (`tapViaSemantics`), `expectTapTargetSemantics` and
  `meetsGuideline(labeledTapTargetGuideline)` per
  [`accessibility.md`](../guides/accessibility.md).
- **Degenerate surfaces are test cases**: a split-screen-narrow window, a
  doubled font scale, the fold threshold. Assert no overflow and the tap
  floors.
- **Measure with `getRect`, not `getSize`.** Inside a `FittedBox`,
  `getSize` reports the pre-scale layout size and passes vacuously;
  `getRect` applies the transform the user actually gets.
- **Prove every new test can fail**: break the line it pins, watch it go
  red, restore. Commit before the mutation pass - `git checkout --`
  restores the committed state, including over your uncommitted fixes.
