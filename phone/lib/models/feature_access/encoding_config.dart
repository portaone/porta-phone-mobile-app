import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/enableble.dart';
import 'package:webtrit_phone/models/encoding_settings.dart';
import 'package:webtrit_phone/models/rtp_codec_profile.dart';

class EncodingConfig extends Equatable {
  const EncodingConfig({
    required this.bypassConfig,
    required this.configurationAllowed,
    required this.defaultPresetOverride,
    this.conferenceAudioCodecs = defaultConferenceAudioCodecs,
  });

  final bool bypassConfig;
  final bool configurationAllowed;
  final DefaultPresetOverride defaultPresetOverride;

  /// The audio codecs the server's conference mixer speaks.
  ///
  /// The room is a mixer on the server, and a call joins it with whatever codec
  /// its own offer and answer settled on. A call on any other codec is left out
  /// of the room, and a room left with fewer than two calls is closed - the
  /// client is told only that the conference ended, with no reason. So a call
  /// in the room, or placed to join it, offers these alone, and a call on
  /// another codec is moved onto them before it is merged.
  ///
  /// A fact of the server, not a preference: what a person may choose is the
  /// order and a subset of these ([EncodingSettings.conferenceAudioProfiles]),
  /// never a codec outside them. Set by the build, for a mixer that learns or
  /// drops a codec.
  final Set<RTPCodec> conferenceAudioCodecs;

  /// What the mixer speaks when the build says nothing.
  static const defaultConferenceAudioCodecs = {RTPCodec.opus, RTPCodec.pcma, RTPCodec.pcmu};

  /// The list a person orders the conference codecs from: the mixer's codecs,
  /// in [EncodingSettings.defaultConferenceAudioProfilesOrder] for those it
  /// names and after them for the rest.
  List<Enableble<RTPCodecProfile>> get conferenceAudioProfilesToChoose {
    final known = EncodingSettings.defaultConferenceAudioProfilesOrder;
    return [
      for (final p in known)
        if (conferenceAudioCodecs.contains(p.option.codec)) p,
      for (final codec in conferenceAudioCodecs)
        if (!known.any((p) => p.option.codec == codec))
          for (final profile in RTPCodecProfile.values.where((p) => p.kind == RTPCodecKind.audio && p.codec == codec))
            (option: profile, enabled: true),
    ];
  }

  @override
  List<Object?> get props => [bypassConfig, configurationAllowed, defaultPresetOverride, conferenceAudioCodecs];
}

class DefaultPresetOverride extends Equatable {
  const DefaultPresetOverride({
    required this.audioBitrate,
    required this.videoBitrate,
    required this.ptime,
    required this.maxptime,
    required this.opusSamplingRate,
    required this.opusBitrate,
    required this.opusStereo,
    required this.opusDtx,
    required this.removeStaticAudioRtpMaps,
    required this.remapTE8payloadTo101,
    this.removeREMBFeedback,
    this.removeTWCCFeedback,
    this.removeExtmaps,
  });

  final int? audioBitrate;
  final int? videoBitrate;
  final int? ptime;
  final int? maxptime;
  final int? opusSamplingRate;
  final int? opusBitrate;
  final bool? opusStereo;
  final bool? opusDtx;
  final bool? removeStaticAudioRtpMaps;
  final bool? remapTE8payloadTo101;
  final bool? removeREMBFeedback;
  final bool? removeTWCCFeedback;
  final List<SdpExtmapType>? removeExtmaps;

  @override
  List<Object?> get props => [
    audioBitrate,
    videoBitrate,
    ptime,
    maxptime,
    opusSamplingRate,
    opusBitrate,
    opusStereo,
    opusDtx,
    removeStaticAudioRtpMaps,
    remapTE8payloadTo101,
    removeREMBFeedback,
    removeTWCCFeedback,
    removeExtmaps,
  ];
}
