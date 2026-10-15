# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See **[AGENTS.md](AGENTS.md)** for API contract details, model conventions, and delegate rules.

## Role of this package

`webtrit_callkeep_platform_interface` defines the **shared abstract contract** that all platform implementations must satisfy. Its `lib/` is pure Dart — no Flutter import, no platform-specific code. The pubspec depends on the Flutter SDK.

## Commands

```bash
# From this directory
flutter pub get
flutter analyze
dart format --line-length 120 --set-exit-if-changed lib
```

## Critical rules

- No `dart:io`, `dart:html`, or Flutter-specific imports — must stay pure Dart.
- All models use `Equatable` — do not override `==`/`hashCode` manually.
- Adding a method to `WebtritCallkeepPlatform` requires updating **all** platform implementations and the aggregator.
- Do not put Pigeon types here — they live in platform packages.

## Related packages

| Package | Path |
| --- | --- |
| Aggregator | `../webtrit_callkeep` |
| Android impl | `../webtrit_callkeep_android` |
| iOS impl | `../webtrit_callkeep_ios` |
