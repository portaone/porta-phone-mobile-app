/// Where the offer time of an incoming call report comes from.
///
/// [core] is Core's `offered_at` (the incoming_call event, the push, the handshake's call log): the
/// moment Core learned of the offer from Janus, taken once per offer to this app. The platform tells
/// a new attempt of a reused call id from a late copy of an ended one by its equality, never by
/// comparing it with a clock.
///
/// TEMPORARY(old Core without offered_at): [fcm] (the push's sentTime) and [device] (when this
/// phone got the offer) exist only while the app supports a Core that does not send `offered_at`.
enum CallkeepOfferTimeSource { core, fcm, device }

/// How an incoming call report reached the app. A socket delivers in order: an offer on it after
/// the call's hangup is a new attempt of the call id.
enum CallkeepOfferVia { socket, push, handshake, other }
