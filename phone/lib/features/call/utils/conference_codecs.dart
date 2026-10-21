import 'package:webtrit_phone/models/rtp_codec_profile.dart';

/// The audio codecs the server's conference mixer speaks.
///
/// The room is a mixer on the server, and a call joins it with whatever codec
/// its own offer and answer settled on. A call on any other codec is left out
/// of the room, and a room left with fewer than two calls is closed - the
/// client is told only that the conference ended, with no reason. So a call
/// placed to join a room offers these alone: a callee that can speak none of
/// them turns the call down before answering, which is an ordinary failed
/// call, rather than answering into a room that then falls apart.
///
/// A list rather than a rule about one codec, so that a mixer that learns or
/// drops a codec is followed by changing it here.
const kConferenceAudioCodecs = {RTPCodec.opus, RTPCodec.pcma, RTPCodec.pcmu};
