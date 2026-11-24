import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/room_video_codecs.dart';

/// A publication offers the room Baseline H.264 only: an iPhone's High profile, first in its offer,
/// is what Janus would send every subscriber, and an Android phone refuses that line.
void main() {
  // The video section of an iPhone's screen publication, as the stand logged it.
  const iphone =
      'v=0\r\n'
      'm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'
      'a=rtpmap:111 opus/48000/2\r\n'
      'm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101\r\n'
      'a=rtpmap:96 H264/90000\r\n'
      'a=rtcp-fb:96 nack\r\n'
      'a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c34\r\n'
      'a=rtpmap:97 rtx/90000\r\n'
      'a=fmtp:97 apt=96\r\n'
      'a=rtpmap:98 H264/90000\r\n'
      'a=rtcp-fb:98 nack\r\n'
      'a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e034\r\n'
      'a=rtpmap:99 rtx/90000\r\n'
      'a=fmtp:99 apt=98\r\n'
      'a=rtpmap:100 VP8/90000\r\n'
      'a=rtpmap:101 rtx/90000\r\n'
      'a=fmtp:101 apt=100\r\n';

  test('the High profile and its retransmission leave the offer; Baseline and the rest stay', () {
    final sdp = withBaselineH264Only(iphone);

    expect(sdp, contains('m=video 9 UDP/TLS/RTP/SAVPF 98 99 100 101\r\n'));
    expect(sdp, isNot(contains('640c34')));
    expect(sdp, isNot(contains('a=rtpmap:96 ')));
    expect(sdp, isNot(contains('a=rtcp-fb:96 ')));
    expect(sdp, isNot(contains('apt=96')));
    expect(sdp, contains('profile-level-id=42e034'));
    expect(sdp, contains('a=rtpmap:100 VP8/90000'));
    expect(sdp, contains('m=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'), reason: 'the audio as it was');
  });

  test('an offer with no Baseline H.264 is left as it is', () {
    const highOnly =
        'v=0\r\n'
        'm=video 9 UDP/TLS/RTP/SAVPF 96 100\r\n'
        'a=rtpmap:96 H264/90000\r\n'
        'a=fmtp:96 packetization-mode=1;profile-level-id=640c34\r\n'
        'a=rtpmap:100 VP8/90000\r\n';

    expect(withBaselineH264Only(highOnly), highOnly);
  });
}
