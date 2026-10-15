# Material UI packages

The app is built on `material_ui` and `cupertino_ui`, the packages Flutter is moving Material and
Cupertino into. The SDK pinned in `.fvmrc` still ships its own `package:flutter/material.dart`,
so two copies exist side by side, and some dependencies still use the old one. This page says how
the two are kept apart and what breaks when they meet.
Last reviewed: 2026-10-15.

## Two Material libraries

The code of the two libraries is nearly the same, but to Dart they are different libraries:
`Theme`, `MaterialLocalizations`, `Scaffold`, `Tooltip`, `TabController` of one are not those of
the other. A widget from a package on `flutter/material` finds no theme and no localizations
under a `material_ui` app, and the reverse. `MaterialLocalizations.of` then fails with
`No MaterialLocalizations found` in debug and `Null check operator used on a null value` in
release.

Already on `material_ui`: `auto_route` and `google_fonts`. Still on `flutter/material`:
`emoji_picker_flutter`, `country_code_picker`, `mobile_scanner`, `webview_flutter`.

## App wiring

- Imports: `package:material_ui/material_ui.dart` and `package:cupertino_ui/cupertino_ui.dart`
  everywhere. `package:flutter/material.dart` appears only as a prefixed `legacy` import (below).
  The pinned SDK has no `dart fix` for this rename; it was done by text replacement.
- Localizations: register `appLocalizationsDelegates` from `lib/l10n/l10n.dart`, never the
  generated `AppLocalizations.localizationsDelegates`. gen-l10n still emits the
  `flutter_localizations` delegates, which register the framework's `MaterialLocalizations`, a
  type `material_ui` widgets never look up. The same constant goes into every test harness.
- Legacy packages: `LegacyMaterialBridge` (`lib/widgets/legacy_material_bridge.dart`) wraps
  `MaterialUiCompatibilityBridge`, which gives the widgets below it a `flutter/material` theme and
  localizations mapped from the `material_ui` ones above. It works in that direction only, and
  `material_ui` marks it `@Deprecated` as a temporary migration aid.
- Placement: the bridge sits in `MaterialApp.router(builder: ...)` in `lib/app/view/app.dart`, at
  the root. Dialogs and bottom sheets open as new routes under the `Navigator`, so a bridge next
  to the widget would not cover them.
- A legacy object handed out: when a legacy package gives you one of its own objects (the emoji
  picker takes a `flutter/material` `TabController`), the widget around it must be legacy too.
  `status_icon_picker_sheet.dart` does it with
  `import 'package:flutter/material.dart' as legacy show TabAlignment, TabBar;`.

## Behaviour and test traps

- `PopupMenuButton` with a `child`: what you do is wrap it in `Semantics` with a label. What
  happens is the label lands on a separate node above the one that takes the tap, because
  `material_ui` adds its own `Semantics(button, enabled, expanded)` around the child. Put a
  `MergeSemantics` around that `Semantics` (`contacts_source_picker.dart`).
- `find.byTooltip`: it matches the shared `RawTooltip` by its semantics tooltip, but for a
  `Tooltip(excludeFromSemantics: true)` (or one with no message) it checks `widget is Tooltip`
  against `flutter/material`'s class only, and finds nothing. Use
  `find.byWidgetPredicate((w) => w is Tooltip && w.message == ...)`, as
  `test/features/call/view/call_active_scaffold_test.dart` does.
- `find.byType` for widgets of a legacy package needs the legacy type:
  `import 'package:flutter/material.dart' as legacy show Dialog;`, then
  `find.byType(legacy.Dialog)` (`test/features/settings/features/caller_id/caller_id_semantics_test.dart`).
- A test that renders a legacy widget (country picker, emoji picker) needs
  `LegacyMaterialBridge` in its harness builder, or it fails with
  `No MaterialLocalizations found`
  (`test/features/settings/features/presence/presence_settings_harness.dart`).

Accessibility rules for the controls themselves: [accessibility.md](accessibility.md).
