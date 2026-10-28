# webtrit_callkeep

The public-facing package of the `webtrit_callkeep` federated plugin. Add this package to your app
— it aggregates the iOS and Android implementations automatically.

For the full plugin overview, setup guide, and API reference see the
[root README](../README.md).

An end reported with `missedWhileConnecting` - the app learnt from signaling that a call it never
held is over - is kept in `Callkeep` ahead of the platform: the delegate is not handed a
`didPresentIncomingCall` for that id afterwards, and `Callkeep().wasEndedBeforePresented(callId)`
answers true until the app registers the id anew. The map is bounded (32 entries); false does not
mean the call is alive. An end reported with `declinedByUser` - the user declined the call on this
device - is kept the same way for now; the separate value lets the app tell a decline from a call
it never saw.
