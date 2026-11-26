// What a publication of this client's video offers the room: H.264 in its Constrained Baseline
// and Baseline profiles only, for every phone in the room to take. Used by ConferenceVideoSession
// on each publisher offer, before it becomes the local description.
//
// Janus gives a publication the first codec of the offer the room allows and sends it to every
// subscriber as it is. An iPhone offers H.264 High (profile-level-id 640c..) first; an Android
// phone's factory has only Baseline, so its answer to that subscription refuses the line
// (m=video 0) and it sees nothing of that participant - the camera or the screen.

/// [sdp] with the H.264 payloads of other profiles than Baseline taken out of every video
/// section, with their retransmission payloads; a section with no Baseline H.264 is left as it is.
String withBaselineH264Only(String sdp) {
  final eol = sdp.contains('\r\n') ? '\r\n' : '\n';
  final lines = sdp.split(eol);
  final out = <String>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (!line.startsWith('m=video')) {
      out.add(line);
      i++;
      continue;
    }
    var end = i + 1;
    while (end < lines.length && !lines[end].startsWith('m=')) {
      end++;
    }
    out.addAll(_section(lines.sublist(i, end)));
    i = end;
  }
  return out.join(eol);
}

List<String> _section(List<String> section) {
  final h264 = <String>{};
  final baseline = <String>{};
  final rtxOf = <String, String>{};
  for (final line in section) {
    final rtpmap = RegExp(r'^a=rtpmap:(\d+) H264/', caseSensitive: false).firstMatch(line);
    if (rtpmap != null) h264.add(rtpmap.group(1)!);
    final apt = RegExp(r'^a=fmtp:(\d+) apt=(\d+)').firstMatch(line);
    if (apt != null) rtxOf[apt.group(1)!] = apt.group(2)!;
  }
  for (final line in section) {
    final fmtp = RegExp(r'^a=fmtp:(\d+) (.*)$').firstMatch(line);
    if (fmtp == null || !h264.contains(fmtp.group(1))) continue;
    final profile = RegExp(r'profile-level-id=([0-9a-fA-F]{2})').firstMatch(fmtp.group(2)!);
    if (profile != null && profile.group(1)!.toLowerCase() == '42') baseline.add(fmtp.group(1)!);
  }
  final dropped = h264.difference(baseline);
  if (dropped.isEmpty || baseline.isEmpty) return section;
  dropped.addAll([
    for (final entry in rtxOf.entries)
      if (dropped.contains(entry.value)) entry.key,
  ]);
  final out = <String>[];
  for (final line in section) {
    if (line.startsWith('m=video')) {
      final parts = line.split(' ');
      out.add([...parts.take(3), ...parts.skip(3).where((pt) => !dropped.contains(pt))].join(' '));
      continue;
    }
    final payload = RegExp(r'^a=(?:rtpmap|fmtp|rtcp-fb):(\d+)[ ]').firstMatch(line);
    if (payload != null && dropped.contains(payload.group(1))) continue;
    out.add(line);
  }
  return out;
}
