# signaling_service_ios

The iOS platform of `signaling_service`. iOS has no equivalent of the Android foreground
service, so the socket lives in the isolate that connects.

`WebtritSignalingServiceIos` (`lib/src/plugin.dart`) is a thin subclass of
`WebtritSignalingServiceDirect` from `signaling_service_platform_interface`: it holds the
singleton, `registerWith()` and a `forTesting()` constructor, nothing else. The module factory,
the events stream, the session buffer and the connection lifecycle are the base class's, and
their behaviour is described in
[signaling_service_platform_interface/AGENTS.md](../signaling_service_platform_interface/AGENTS.md).
A change in behaviour goes there, not here, and it affects iOS, web and Android `pushBound` at
once.

Incoming calls on iOS do not come through this package: they arrive as VoIP pushes through
PushKit in the callkeep plugin (`callkeep/webtrit_callkeep_ios`), and `setCallEventHandler` is a
no-op. `lib/` does not import `signaling`; the package lists it for the tests' fakes.

## Commands

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test      # test/plugin_test.dart; not in the pre-push gate
```
