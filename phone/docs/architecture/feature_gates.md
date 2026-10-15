# Feature Gates

How to hide a feature behind two questions at once: what the deployment offers, and who this
user is. The two are answered at different moments, and that difference decides where the
feature can be shown at all.
Last reviewed: 2026-10-15.

Build-time switches (a permission or manifest component that must not ship) are a different
mechanism - see [optional features](../reference/optional_features.md). How runtime
configuration reaches the app is in [feature access](../features/feature_access.md). The call
center is the worked example of this page - see [call center](../features/call_center.md).

## Two gates, two moments

| Gate | Answered by | Known |
|---|---|---|
| The deployment offers the feature | a flag in `system-info` -> `adapter.supported`, read through `CoreSupport` into `FeatureAccess` | before `MainShell` mounts |
| This user is an agent, owner, member of it | a non-empty answer to an authorised request | only after a request made inside the session |

The first gate arrives with `system-info`, before sign-in. The second needs a token and a
round trip to the backend.

## The second gate outside `FeatureAccess`

`MainShell` pins the `FeatureAccess` value it mounts with for the whole session (see
[feature access](../features/feature_access.md)). The answer to the second gate comes after
that object is pinned, so it can never reach it.

- What you do: add "is this user an agent" as a field computed into `FeatureAccess` from a
  request.
- What happens: the session never sees the answer; it shows up one start late at best.
- Why: the snapshot is taken before any authorised request can be made, on purpose - a
  provider tree that changes shape mid-session closes blocs that live screens still talk to.
- Instead: answer it by placement, as below.

## Placement and the second gate

**A screen in the stack** (a settings row, a button on a screen) asks live. A cubit above the
route reads the answer and the row is drawn or not. The shape of the provider tree does not
change, only what is painted, so the pin is not broken. The call center settings row works
this way: `CallQueuesCubit` in `lib/features/settings/view/settings_router_page.dart`.

**A bottom-menu tab** cannot wait: the tab set is built before the session can ask. The
choices are to hold the first screen on a network request, to show the tab to everyone and
let it say "you are not an agent", or to draw from what the backend answered last time. The
app takes the last one:

- the repository reports the answer after every read (`onAgentKnown` in
  `lib/app/router/main_shell_repositories.dart`);
- `AppPreferences.setCallCenterAgent(userId, ...)` stores it;
- `FeatureAccessStreamFactory` reads it back at the next session start and passes it to
  `FeatureAccess.create(..., callCenterAgent: ...)`, where `BottomMenuMapper` drops the tab
  unless both gates say yes.

The price is one session of lag in both directions: someone made an agent gets the tab at the
next start (the settings row is there meanwhile), and someone who stopped being one keeps it
for one more session.

## Traps

**A global cache key.** What you do: store the remembered answer under one key. What happens:
on a device two people sign into in turn, one gets the other's tab. Why: the answer is about
the account, not the device. Instead: key it by user id, as `call-center-agent:<userId>` in
`lib/data/app_preferences.dart`.

**A "yes" default.** What you do: treat an account with nothing stored as allowed. What
happens: the tab appears and leads to an empty screen, which reads as broken. Why: nothing
has been asked yet. Instead: default to "no" (`getCallCenterAgent(userId) ?? false`).

**A writer that never runs.** What you do: put the repository whose first read writes the
cache in a lazy provider. What happens: the read waits until someone opens a screen that
reads the repository - for a tab, the very screen the tab leads to - so the flag is never
written and the tab never appears. Why: a `RepositoryProvider` is lazy by default and builds
on first `read`. Widget tests do not catch it because they create the provider themselves.
Instead: build it with the session (`lazy: false`) and start the read on creation
(`..prime()`), as the `CallQueuesRepository` provider does.

## Checklist

- The second gate is not in `FeatureAccess`.
- Screens in the stack ask live; a tab reads the stored answer.
- The stored answer is keyed by user id, defaults to "no", and is written by a non-lazy
  provider.
- Previews and screenshots assert the gate explicitly.
- Checked on a device both ways: nothing stored -> no tab; after one session -> tab; access
  withdrawn -> tab gone after the next restart.
- `test/models/feature_access/call_center_tab_test.dart` pins the tab rule; a new gate of this
  kind gets a test of the same shape.
