# Incoming-call background scenarios

How an incoming call is delivered and handled depending on the app state and the configured mode.
The single decision that selects the owner of the background work lives in callkeep
(`IncomingCallHandler.maybeInitBackgroundHandling`); see the callkeep doc
`webtrit_callkeep_android/docs/incoming-call-handling.md`. This page shows the app-level scenarios.

GitHub renders the `mermaid` blocks below.

Colour legend:

- blue — `webtrit_callkeep`
- green — `signaling_service`
- orange — `webtrit_phone` (app code, incl. app callbacks running on a callkeep / FGS engine)
- grey — external (FCM, signaling server / WebSocket, Android Telecom / system UI)

## All scenarios (combined)

```mermaid
flowchart TB
  classDef ck fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef sig fill:#d5e8d4,stroke:#82b366,color:#000
  classDef app fill:#ffe6cc,stroke:#d79b00,color:#000
  classDef ext fill:#f5f5f5,stroke:#999999,color:#000

  subgraph A["CASE A - PUSH-BOUND (FCM): app Firebase isolate reports, callkeep runs the ongoing isolate"]
    direction TB
    A_FCM["FCM high-priority push"]:::ext
    A_FMISO["firebase_messaging background isolate (APP)<br/>_firebaseMessagingBackgroundHandler -> reportNewIncomingCall<br/>(no WebSocket here)"]:::app
    A_BOOT["reportNewIncomingCall (bootstrap API)"]:::ck
    A_CKC["CallkeepCore.registerIncomingCall"]:::ck
    A_PCS["PhoneConnectionService<br/>:callkeep_core, Telecom"]:::ck
    A_TEL["System call UI + ring"]:::ext
    A_ICS["IncomingCallService (callkeep)<br/>spawns its OWN FlutterEngine (autoRegister = true)"]:::ck
    A_PISO["push isolate (app callback on callkeep engine)<br/>background_isolate_callbacks.dart : onPushNotificationSyncCallback<br/>-> PushNotificationIsolateManager.run (opens its own WebSocket)"]:::app
    A_WS["Signaling server (WebSocket)"]:::ext
    A_ACT["Activity / main UI engine<br/>adopts the call after answer"]:::app
    A_FGS["ForegroundService (callkeep)<br/>bound to Activity, PHostApi + events"]:::ck

    A_FCM --> A_FMISO --> A_BOOT --> A_CKC --> A_PCS --> A_TEL
    A_PCS -. "onShowIncomingCallUi -> start" .-> A_ICS
    A_ICS --> A_PISO
    A_PISO <--> A_WS
    A_PCS -. "on answer: adopts" .-> A_ACT
    A_ACT -. "binds" .-> A_FGS
    A_FGS <--> A_CKC
  end

  subgraph B["CASE B - PERSISTENT / SOCKET (signaling OWNS the engine)"]
    direction TB
    B_WApp["WebtritApplication.onCreate<br/>wires onFgsEngineReady / onFgsEngineDestroyed"]:::app
    B_ATT["WebtritCallkeep.attachToEngine / detach<br/>callkeep channels on FGS engine (no own isolate)"]:::ck
    B_SFGS["SignalingForegroundService (signaling)<br/>OWNS FGS engine (autoRegister = false)<br/>persistent WebSocket"]:::sig
    B_SISO["push isolate (app code on the FGS engine)<br/>background_isolate_callbacks.dart : onSignalingBackgroundCallEvent"]:::app
    B_WS["Signaling server (WebSocket)"]:::ext
    B_BOOT["reportNewIncomingCall (bootstrap API)"]:::ck
    B_CKC["CallkeepCore.registerIncomingCall"]:::ck
    B_PCS["PhoneConnectionService<br/>:callkeep_core, Telecom"]:::ck
    B_TEL["System call UI + ring"]:::ext
    B_ACT["Activity / main UI engine<br/>adopts the call after answer"]:::app
    B_FGS["ForegroundService (callkeep)<br/>bound to Activity, PHostApi + events"]:::ck

    B_WApp -. "wires" .-> B_ATT
    B_ATT -. "hosted on" .-> B_SFGS
    B_SFGS <--> B_WS
    B_SFGS --> B_SISO --> B_BOOT --> B_CKC --> B_PCS --> B_TEL
    B_PCS -. "on answer: adopts" .-> B_ACT
    B_ACT -. "binds" .-> B_FGS
    B_FGS <--> B_CKC
  end

  subgraph C["CASE C - APP FOREGROUND (app OWNS the WebSocket)"]
    direction TB
    C_ACT["Activity / main UI engine (foreground)<br/>WebtritCallkeepPlugin attached"]:::app
    C_SMOD["App signaling + CallBloc<br/>owns the WebSocket while foreground"]:::app
    C_WS["Signaling server (WebSocket)"]:::ext
    C_FGS["ForegroundService (callkeep)<br/>bound to Activity, PHostApi + events"]:::ck
    C_CKC["CallkeepCore.registerIncomingCall"]:::ck
    C_PCS["PhoneConnectionService<br/>:callkeep_core, Telecom"]:::ck
    C_ICS["IncomingCallService (notification UI)<br/>call reported by the app -> no isolate, nothing presented back"]:::ck
    C_TEL["System call UI + ring (in-app)"]:::ext

    C_ACT --- C_SMOD
    C_SMOD <--> C_WS
    C_ACT -. "binds" .-> C_FGS
    C_SMOD -. "call_bloc.dart reportNewIncomingCall (PHostApi)" .-> C_FGS
    C_FGS <--> C_CKC
    C_CKC --> C_PCS --> C_TEL
    C_PCS -. "shows UI via" .-> C_ICS
  end
```

## Case A — push-bound (FCM)

The call goes to the main app when its callkeep delegate is ready, and to a push isolate
otherwise - the Activity lifecycle does not decide. callkeep gives the app the call
(`didPresentIncomingCall`) rather than only skipping the isolate: the app may have closed its
socket when the previous call ended in the background, and holding the call is what makes
`CallBloc.onChange` reconnect - the handshake then delivers the offer or ends a call the server no
longer has.

```mermaid
flowchart TB
  classDef ck fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef app fill:#ffe6cc,stroke:#d79b00,color:#000
  classDef ext fill:#f5f5f5,stroke:#999999,color:#000

  TITLE["CASE A - PUSH-BOUND (FCM)<br/>no delegate ready -> isolated push isolate, app delegate ready -> main app handles (no isolate)"]:::ext
  FCM["FCM high-priority push"]:::ext
  FMISO["firebase_messaging background isolate (APP)<br/>bootstrap.dart : _firebaseMessagingBackgroundHandler<br/>reports the call (no WebSocket here)"]:::app
  BOOT["reportNewIncomingCall (callkeep bootstrap API)"]:::ck
  CKC["CallkeepCore.registerIncomingCall"]:::ck
  PCS["PhoneConnectionService<br/>:callkeep_core, Android Telecom"]:::ck
  TEL["System call UI + ring"]:::ext
  ICS["IncomingCallService (callkeep)<br/>starts FGS + shows the ringing UI"]:::ck
  MIBH["IncomingCallHandler.maybeInitBackgroundHandling<br/>checks the app's callkeep delegate is ready"]:::ck
  PISO["[no delegate ready] push isolate on callkeep engine (autoRegister = true)<br/>background_isolate_callbacks.dart : onPushNotificationSyncCallback<br/>-> PushNotificationIsolateManager.run, opens its own WebSocket"]:::app
  ALIVE["[app ALIVE, delegate ready] main app already running<br/>callkeep gives it the call (didPresentIncomingCall) - NO new isolate;<br/>CallBloc reconnects if its socket is closed"]:::app
  WS["Signaling server (WebSocket)"]:::ext
  ACT["Activity / main UI engine"]:::app
  FGS["ForegroundService (callkeep), bound to Activity<br/>PHostApi control + ConnectionEventListener events"]:::ck

  TITLE -.-> FCM
  FCM --> FMISO
  FMISO -- "reportNewIncomingCall" --> BOOT
  BOOT --> CKC --> PCS --> TEL
  PCS -. "onShowIncomingCallUi -> start" .-> ICS
  ICS --> MIBH
  MIBH -- "no delegate ready (app dead, not built yet, cleared)" --> PISO
  MIBH -- "delegate ready" --> ALIVE
  PISO <--> WS
  ALIVE <--> WS
  PISO -. "on answer: handoff -> Activity adopts (Activity sends 200 OK)" .-> ACT
  PISO -. "on decline: performEndCall -> DeclineRequest" .-> WS
  ALIVE --> ACT
  ACT -. "binds" .-> FGS
  FGS <--> CKC
```

## Case B — persistent / socket

Signaling owns the engine; the app is the seam (`WebtritCallkeep.attachToEngine`).

```mermaid
flowchart TB
  classDef ck fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef sig fill:#d5e8d4,stroke:#82b366,color:#000
  classDef app fill:#ffe6cc,stroke:#d79b00,color:#000
  classDef ext fill:#f5f5f5,stroke:#999999,color:#000

  TITLE["CASE B - PERSISTENT / SOCKET: signaling OWNS the engine, app is the seam"]:::ext
  WApp["WebtritApplication.onCreate<br/>onFgsEngineReady = WebtritCallkeep.attachToEngine<br/>onFgsEngineDestroyed = WebtritCallkeep.detachFromEngine"]:::app
  SFGS["SignalingForegroundService (signaling)<br/>OWNS the FGS FlutterEngine<br/>automaticallyRegisterPlugins = false<br/>persistent WebSocket"]:::sig
  ATT["WebtritCallkeep.attachToEngine<br/>registers callkeep channels on the FGS engine<br/>callkeep does NOT spawn its own isolate"]:::ck
  SISO["push isolate (APP code on the FGS engine)<br/>background_isolate_callbacks.dart : onSignalingBackgroundCallEvent<br/>IncomingCallEvent -> reportNewIncomingCall, HangupEvent -> releaseCall"]:::app
  WS["Signaling server (WebSocket)"]:::ext
  BOOT["reportNewIncomingCall<br/>callkeep bootstrap API"]:::ck
  CKC["CallkeepCore.registerIncomingCall"]:::ck
  PCS["PhoneConnectionService<br/>process :callkeep_core, Android Telecom"]:::ck
  TEL["System call UI + ring"]:::ext
  ACT["Activity / main UI engine<br/>adopts the live call after answer"]:::app
  FGSVC["ForegroundService (callkeep, main process)<br/>bound to the Activity (onAttachedToActivity)<br/>PHostApi: call-control from Dart<br/>ConnectionEventListener: CallkeepCore events -> Flutter"]:::ck

  TITLE -.-> WApp
  WApp -. "wires (app is the seam)" .-> ATT
  ATT -. "hosted on" .-> SFGS
  SFGS <--> WS
  SFGS --> SISO --> BOOT --> CKC --> PCS --> TEL
  PCS -. "on answer: Activity adopts" .-> ACT
  ACT -. "binds" .-> FGSVC
  FGSVC <--> CKC
  FGSVC -. "events (PDelegateFlutterApi)" .-> ACT
```

## Case C — app foreground

The app owns the WebSocket; `ForegroundService` bridges the call.

```mermaid
flowchart TB
  classDef ck fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef app fill:#ffe6cc,stroke:#d79b00,color:#000
  classDef ext fill:#f5f5f5,stroke:#999999,color:#000

  TITLE["CASE C - APP FOREGROUND: the app OWNS the WebSocket, ForegroundService bridges the call"]:::ext
  ACT["Activity / main UI engine (foreground)<br/>WebtritCallkeepPlugin attached (onAttachedToEngine)"]:::app
  SMOD["App signaling + CallBloc<br/>owns the WebSocket while the app is active"]:::app
  WS["Signaling server (WebSocket)"]:::ext
  FGSVC["ForegroundService (callkeep, main process)<br/>bound to the Activity (onAttachedToActivity)<br/>PHostApi: call-control from Dart<br/>ConnectionEventListener: CallkeepCore events -> Flutter"]:::ck
  CKC["CallkeepCore.registerIncomingCall"]:::ck
  PCS["PhoneConnectionService<br/>process :callkeep_core, Android Telecom"]:::ck
  ICS["IncomingCallService (notification UI)<br/>maybeInitBackgroundHandling:<br/>call reported by the app -> no isolate, nothing presented back"]:::ck
  TEL["System call UI + ring (in-app)"]:::ext

  TITLE -.-> ACT
  ACT --- SMOD
  SMOD <--> WS
  ACT -. "binds" .-> FGSVC
  SMOD -. "call_bloc.dart: reportNewIncomingCall (PHostApi)" .-> FGSVC
  FGSVC <--> CKC
  FGSVC -. "events (PDelegateFlutterApi)" .-> ACT
  CKC --> PCS --> TEL
  PCS -. "shows UI via" .-> ICS
```

## A second call while one rings (Android)

Telecom lets one incoming call ring at a time and refuses the next one. What happens to a call
reported while another incoming call rings is set by
`CallkeepAndroidOptions.incomingCallWhileRinging`; the app passes nothing, so the default,
`queue`, applies. Callkeep side:
`webtrit_callkeep_android/docs/call-flows.md` and `callkeep-core.md` (Waiting calls).

With `queue` the second call (B) waits in callkeep's queue instead of reaching Telecom. The app
is not told: `reportNewIncomingCall` succeeds, and CallBloc holds B as an ordinary incoming
call - with the app open it is listed next to the ringing call (A) with its own answer and
decline. Outside the app B has a silent "Call waiting" notification with two actions.

| What happens | Callkeep | What the user sees |
|---|---|---|
| B is reported while A rings | B waits, silent notification posted | both calls in the app; "Call waiting" in the shade |
| A ends (caller hung up, declined) | B is registered with Telecom | B rings like any incoming call |
| A is answered | B is registered beside A at once | B rings as call waiting on top of A |
| Answer on B (notification or app) | A is declined, B goes through and is answered | the call screen on B |
| Decline current (notification) | A is declined, the oldest waiting call goes through | B rings |
| B's caller hangs up while it waits | B leaves the queue, Telecom never sees it | a missed call |
| The app declines B while it waits | B leaves the queue, `performEndCall(B)` | B is declined on the server |

With `reject` nothing waits: Telecom refuses B, `reportNewIncomingCall` returns
`callRejectedBySystem`, and CallBloc declines B on the server (the caller hears 603 Decline).

## Sequence — Case A (push-bound): answer / decline / missed

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant WS as Signaling server (WS)
    participant FCM as FCM
    participant FMISO as Firebase isolate (app)
    participant CORE as CallkeepCore
    participant PCS as PhoneConnectionService (Telecom)
    participant SYS as Android System UI
    participant ICS as IncomingCallService (callkeep)
    participant PISO as push isolate (app callback)
    participant ACT as Activity + ForegroundService

    WS->>FCM: high-priority push (incoming call)
    FCM->>FMISO: deliver push
    Note over FMISO: bootstrap.dart : _firebaseMessagingBackgroundHandler<br/>reports the call (no WebSocket here)
    FMISO->>CORE: reportNewIncomingCall (bootstrap API)
    CORE->>PCS: registerIncomingCall (Telecom addNewIncomingCall)
    PCS->>SYS: onShowIncomingCallUi -> ring + notification
    PCS->>ICS: start IncomingCallService (FGS)
    Note over ICS: spawns its OWN FlutterEngine (autoRegister = true)
    ICS->>PISO: executeDartCallback (app entrypoint)
    Note over PISO: background_isolate_callbacks.dart : onPushNotificationSyncCallback<br/>-> PushNotificationIsolateManager.run
    PISO->>WS: open its OWN WebSocket (ongoing call)
    SYS-->>User: ringing

    alt User answers
        User->>SYS: Answer
        SYS->>PCS: onAnswer
        PCS->>PISO: performAnswerCall (records _answeredCallId, no WS send)
        Note over ACT: Activity launches, binds ForegroundService, adopts the connection
        CORE->>PISO: performHandoff (the app's delegate holds the call)
        Note over PISO: session completes
        PISO-->>ICS: run() future resolves -> stop service, keep connection
        ACT->>WS: answer over the app WebSocket (SIP 200 OK)
        ACT->>CORE: PHostApi: mute / hold / DTMF / end
        CORE-->>ACT: ConnectionEventListener events (PDelegateFlutterApi)
        User->>ACT: Hang up -> SIP BYE
    else User declines
        User->>SYS: Decline
        SYS->>PCS: onReject -> terminateWithCause(REJECTED)
        PCS->>ICS: onDisconnect -> release(IC_RELEASE_ENDED)
        ICS->>PISO: handleRelease(IC_RELEASE_ENDED) -> performEndCall
        PISO->>WS: DeclineRequest (the push isolate sends the decline)
        Note over ICS: stop service, dismiss UI
    else Missed (caller cancels)
        WS-->>PISO: HangupEvent
        PISO->>CORE: reportEndCall -> terminate connection, service stays up
        PCS->>SYS: dismiss incoming UI
        Note over PISO: record the missed call, show its notification
        PISO-->>ICS: run() future resolves once the record is done -> stop service
    end
```

The push session belongs to the call it was opened for (the one `IncomingCallService` shows).
Its WebSocket sees every line of the account, so it can also hear about other calls - a second
incoming call that Telecom refused while this one rings. A `HangupEvent` for such a call ends
that call natively - and records it as a missed call, under its own caller, only if the session
saw that call's `IncomingCallEvent` - but does not end the session: ending it there handed the
session's own call off while it still rang, which took its notification away and left its
connection ringing with nobody to hear its hangup. The handshake is read for every incoming line
for the same reason - the session's own call is not necessarily on line 0. If the handshake no
longer lists the session's own call, that call ended before the session opened: the session
ends it and closes instead of waiting for a hangup that will not come.

The session's end is the completion of `onPushNotificationSyncCallback`'s future, and the plugin
stops `IncomingCallService` on it - the session never stops the service itself. The future is
draining, not stopping: every missed-call record the session started (its own call's or another
call's) finishes before it resolves, whatever ended the session, so the record is written while
the service still holds its rights. `releaseCall` stays only for a call the session never saw.

What ends the session is its own call ending here, or callkeep's `performHandoff`: the app's
delegate has taken the call (or another handler ended it). The Activity's WebSocket displacing
the session's (4441 `controllerForceAttachClose`) is not a handoff - it only moves the server's
events to the Activity, which reports a hangup of its own accord - and the session keeps the
service up through it. On a Samsung M32 cold start that gap between the Activity's socket and
its delegate was 8.8 s; a caller hanging up inside it used to come back as a ghost call.

The last stretch of that gap is covered on the Dart side, in callkeep: a hangup `CallBloc` hears
for a call it does not hold is reported as `missedWhileConnecting`, and `Callkeep` records that
id before the report crosses to the platform (on the M32 the replay got through the main looper
3 s before it). The delegate callkeep hands the platform drops `didPresentIncomingCall` for a
recorded id, and the bloc asks `Callkeep.wasEndedBeforePresented` after its contact lookup
before it shows a presentation it received earlier. The bloc keeps no list of its own.

## Sequence — Case B (persistent / socket)

> Caveat: the answer branch (Activity takeover, 200 OK, 4441 eviction) is the *intended* path,
> reconstructed from the documented 4441 / handoff mechanism. `onSignalingBackgroundCallEvent`
> itself only handles `IncomingCallEvent` (report) and `HangupEvent` (release); the persistent
> answer is the WT-1538 area.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant WS as Signaling server (WS)
    participant APP as WebtritApplication (app glue)
    participant SFGS as SignalingForegroundService (FGS engine)
    participant CORE as CallkeepCore
    participant PCS as PhoneConnectionService (Telecom)
    participant SYS as Android System UI
    participant ACT as Activity + ForegroundService

    Note over APP: onCreate: onFgsEngineReady = WebtritCallkeep.attachToEngine<br/>onFgsEngineDestroyed = WebtritCallkeep.detachFromEngine
    APP->>SFGS: start FGS (persistent / socket mode)
    Note over SFGS: creates its OWN FGS FlutterEngine<br/>automaticallyRegisterPlugins = false
    SFGS->>CORE: wireUpPigeon -> onFgsEngineReady -> attachToEngine<br/>(init ContextHolder + AssetCacheManager, register callkeep channels)
    SFGS->>WS: open persistent WebSocket + register

    WS-->>SFGS: incoming_call event
    Note over SFGS: background_isolate_callbacks.dart : onSignalingBackgroundCallEvent (IncomingCallEvent)<br/>runs on the FGS engine (app code)
    SFGS->>CORE: reportNewIncomingCall (bootstrap channel, hosted)
    Note over CORE: callkeep does NOT spawn its own isolate<br/>(hosted on external engine)
    CORE->>PCS: registerIncomingCall (Telecom addNewIncomingCall)
    PCS->>SYS: onShowIncomingCallUi -> ring + full-screen / notification
    SYS-->>User: ringing

    alt User answers
        User->>SYS: Answer
        SYS->>PCS: onAnswer
        PCS->>CORE: markAnswered
        Note over ACT: Activity launches, binds ForegroundService,<br/>adopts the live PhoneConnection
        ACT->>WS: main app takes over the session, SIP 200 OK
        WS-->>SFGS: 4441 controllerForceAttachClose (evict FGS connection)
        ACT->>CORE: PHostApi: mute / hold / DTMF / end
        CORE-->>ACT: ConnectionEventListener events (PDelegateFlutterApi)
    else Missed / hung up before answer
        WS-->>SFGS: HangupEvent
        SFGS->>CORE: releaseCall -> terminate connection
        PCS->>SYS: dismiss incoming UI
    end

    Note over SFGS: on FGS stop: onDestroy -> onFgsEngineDestroyed<br/>-> WebtritCallkeep.detachFromEngine
```
