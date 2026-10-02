# Incoming call handling (decision + outcomes)

How callkeep decides who runs the background work for an incoming call, and the terminal outcomes
it drives. callkeep is transport-agnostic: it does not know whether a call arrives via push, a
persistent socket, or in-app signaling. The integrator reports the call; callkeep presents it via
Android Telecom and routes call control.

Related: step-by-step flows in [call-flows.md](call-flows.md); services in
[background-services.md](background-services.md) and [foreground-service.md](foreground-service.md);
hosting callkeep on an app-owned engine in
[../../docs/external-flutter-engines.md](../../docs/external-flutter-engines.md).

Color: blue = callkeep, orange = host app, grey = external (Telecom / system UI), yellow = decision.

## Who owns the background work

After a call is reported and `IncomingCallService` starts, `IncomingCallHandler.maybeInitBackgroundHandling`
decides whether callkeep spawns its own background isolate:

```mermaid
flowchart TB
  classDef ck fill:#dae8fc,stroke:#6c8ebf,color:#000
  classDef app fill:#ffe6cc,stroke:#d79b00,color:#000
  classDef ext fill:#f5f5f5,stroke:#999999,color:#000
  classDef dec fill:#fff2cc,stroke:#d6b656,color:#000

  IN["reportNewIncomingCall -> CallkeepCore.registerIncomingCall<br/>-> PhoneConnectionService (Telecom) -> IncomingCallService.start (ringing UI)"]:::ck
  GATE{"IncomingCallHandler.maybeInitBackgroundHandling"}:::dec
  IN --> GATE
  GATE -- "hosted on an external engine<br/>(WebtritCallkeep.attachToEngine)" --> HOST["the host engine owns the background work<br/>callkeep does NOT spawn an isolate"]:::app
  GATE -- "delegate ready,<br/>call reported by the app itself" --> HOLD["the app already holds the call<br/>nothing presented, no isolate"]:::app
  GATE -- "delegate ready,<br/>call reported only by the push" --> MAIN["callkeep gives the call to the app's delegate<br/>(ReplayIncomingCall present-only -> didPresentIncomingCall)<br/>no isolate"]:::app
  GATE -- "no delegate ready<br/>(app dead, call handling not built yet, or cleared)" --> OWN["callkeep spawns its OWN background isolate<br/>(IncomingCallService, automaticallyRegisterPlugins = true)"]:::ck
```

One rule, the same as on iOS, where a call PushKit registered is reported to the app: a call
the push registered goes to the app's delegate when one is ready, and to a push isolate otherwise.
The Activity lifecycle plays no part. A visible or recently backgrounded Activity says nothing
about who will take the call - the app closes its socket when a call ends in the background, and
the OS may close it too. Until this rule, a call arriving while the app lived in the background
without a socket skipped the isolate on the strength of the lifecycle alone, was owned by nobody
and rang on after the caller hung up. Given the call through the same `ReplayIncomingCall` path a
freshly attached delegate is seeded by, the app holds it and reconnects to learn whether it still
rings; a call the server no longer has is ended by the handshake.

What the gate reads:

- **Delegate ready** - `ForegroundService.isDelegateReady`, set by `onDelegateSet` and cleared by
  `onDelegateCleared` (`setDelegate(null)`) and the service's `onDestroy`. A bound service is not
  enough: the app's call handling may not be built yet, and a presentation would wait unread.
  Without a ready delegate the isolate runs and the app takes the call over through the usual
  handoff when its delegate attaches.
- **Reported by the app** - `CallkeepCore.isReportedByApp(callId)`: the foreground bridge reported
  the call itself, so the app holds it and it is not presented back. The core sets the fact when
  the bridge registers the call and clears it when the call terminates - which covers a refused
  report, the app's own end report and a transfer-back that reuses the id.
- **Present-only** - the hand-over confirms no handoff: no push session ran, and a handoff
  release would end the ringing phase of a call nobody has answered; the service's notification is
  the app's call UI while it is in the background. Answer and end still release it as before.

## Terminal outcomes

The owner that reported the call drives the outcome; callkeep mediates through Telecom and
`IncomingCallService`. The owner is the callkeep isolate, the host engine, or the main app
(see the decision above).

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant SYS as Android System UI
    participant PCS as PhoneConnectionService (Telecom)
    participant CORE as CallkeepCore
    participant ICS as IncomingCallService
    participant OWNER as Background owner (isolate / host engine / main app)
    participant ACT as Activity + ForegroundService

    SYS-->>User: ringing
    alt User answers
        User->>SYS: Answer
        SYS->>PCS: onAnswer
        PCS->>OWNER: performAnswerCall / markAnswered
        Note over ACT: Activity adopts the connection, the app completes the answer (200 OK)
    else User declines
        User->>SYS: Decline
        SYS->>PCS: onReject -> terminateWithCause(REJECTED)
        PCS->>ICS: onDisconnect -> release(IC_RELEASE_ENDED)
        ICS->>OWNER: performEndCall (the owner sends the decline)
    else Missed (caller cancels)
        OWNER->>CORE: releaseCall -> terminate connection
        PCS->>SYS: dismiss incoming UI
    end
```
