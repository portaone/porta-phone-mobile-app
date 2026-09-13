# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See **[AGENTS.md](AGENTS.md)** for commands, architecture detail, Pigeon workflow, and iOS-specific rules.

## Role of this package

`webtrit_callkeep_ios` is the **iOS platform implementation** of the callkeep plugin. It contains two layers:

- **Dart layer** (`lib/src/`) — `WebtritCallkeepIOS` registers itself as the platform instance and proxies calls via Pigeon.
- **Objective-C layer** (`ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/`) — CallKit + PushKit integration, in
  `WebtritCallkeepPlugin.m` with `Converters.m` and the Pigeon-generated `Generated.m`.

## Commands

```bash
# From this directory
flutter pub get
flutter analyze lib test
dart format --line-length 80 --set-exit-if-changed lib test

# Pigeon regeneration (after editing pigeons/callkeep.messages.dart)
../tool/pigeon.sh   # runs pigeon and strips the trailing whitespace its Kotlin and Objective-C generators leave
```

## Critical rules

- Never edit `lib/src/common/callkeep.pigeon.dart` manually — regenerate via Pigeon.
- No persistent background services on iOS — all background handling goes through CallKit/PushKit.
- `PushRegistryDelegate` must be set before the app enters background if VoIP pushes are expected.
- iOS minimum deployment target: **iOS 13.0** (`webtrit_callkeep_ios.podspec`, `Package.swift`).

## Related packages

| Package            | Path                                     |
|--------------------|------------------------------------------|
| Platform interface | `../webtrit_callkeep_platform_interface` |
| Aggregator         | `../webtrit_callkeep`                    |
