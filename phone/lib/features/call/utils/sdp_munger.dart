// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:logging/logging.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/features/call/utils/utils.dart';
import 'package:webtrit_phone/models/encoding_settings.dart';
import 'package:webtrit_phone/models/feature_access/encoding_config.dart';
import 'package:webtrit_phone/models/rtp_codec_profile.dart';
import 'package:webtrit_phone/repositories/encoding_preset/encoding_preset_repository.dart';
import 'package:webtrit_phone/repositories/encoding_settings/encoding_settings_repository.dart';

final _logger = Logger('SDPMunger');

/// Modifies the SDP of a [RTCSessionDescription] object.
/// Used to change outgoing SDP before sending it to the server to change some specific parameters of negotiation.
abstract class SDPMunger {
  void apply(RTCSessionDescription description);
}

/// A class that modifies SDP (Session Description Protocol) with encoding settings.
///
/// This class implements the [SDPMunger] interface and provides functionality
/// to alter SDP based on [EncodingSettings] stored in [AppPreferences].
///
/// can be used to set bitrate, ptime, opus stereo & bandwidth
/// and audio/video profiles reordering and exclusion by settings.
class ModifyWithEncodingSettings implements SDPMunger {
  ModifyWithEncodingSettings(this._encodingSettingsRepository, this._encodingConfig, this._encodingPresetRepository);

  final EncodingSettingsRepository _encodingSettingsRepository;
  final EncodingConfig _encodingConfig;
  final EncodingPresetRepository _encodingPresetRepository;

  EncodingSettings _makeSettings(EncodingPreset? preset) {
    final defaultPresetOverride = _encodingConfig.defaultPresetOverride;

    EncodingSettings settings = switch (preset) {
      null => EncodingSettings.defaultWithOverrides(
        audioBitrate: defaultPresetOverride.audioBitrate,
        videoBitrate: defaultPresetOverride.videoBitrate,
        ptime: defaultPresetOverride.ptime,
        maxptime: defaultPresetOverride.maxptime,
        opusSamplingRate: defaultPresetOverride.opusSamplingRate,
        opusStereo: defaultPresetOverride.opusStereo,
        opusDtx: defaultPresetOverride.opusDtx,
        removeREMBFeedback: defaultPresetOverride.removeREMBFeedback,
        removeTWCCFeedback: defaultPresetOverride.removeTWCCFeedback,
        removeExtmaps: defaultPresetOverride.removeExtmaps,
      ),
      EncodingPreset.eco => EncodingSettings.eco(),
      EncodingPreset.balance => EncodingSettings.balance(),
      EncodingPreset.quality => EncodingSettings.quality(),
      EncodingPreset.custom => _encodingSettingsRepository.getEncodingSettings(),
      EncodingPreset.bypass => EncodingSettings.blank(),
    };
    return settings;
  }

  /// The encoding settings in force now - the preset chosen, or the
  /// deployment's default when the person may not choose - or null when the
  /// deployment bypasses them altogether.
  EncodingSettings? get settings {
    if (_encodingConfig.bypassConfig) return null;
    final preset = _encodingConfig.configurationAllowed ? _encodingPresetRepository.getEncodingPreset() : null;
    return _makeSettings(preset);
  }

  @override
  void apply(RTCSessionDescription description) {
    final settings = this.settings;
    if (settings == null) return;

    final (
      audioBitrate,
      videoBitrate,
      ptime,
      maxptime,
      opusSamplingRate,
      opusBitrate,
      opusStereo,
      opusDtx,
      audioProfiles,
      videoProfiles,
      _, // conferenceAudioProfiles: only for a call in a room, see RoomCodecs.restrict
      removeStaticAudioRtpMaps,
      remapTE8payloadTo101,
      removeREMBFeedback,
      removeTWCCFeedback,
      removeExtmaps,
    ) = settings.asRecord;

    final sdp = description.sdp;
    if (sdp == null) return;

    final builder = SDPModBuilder(sdp: sdp);
    bool modified = false;

    if (audioProfiles != null) {
      final profiles = audioProfiles;
      final toRemove = profiles.where((p) => p.enabled == false).map((e) => e.option).toList();
      final toReorder = profiles.where((p) => p.enabled == true).map((e) => e.option).toList();

      toRemove.forEach((p) => builder.removeProfile(p));
      builder.reorderProfiles(toReorder, RTPCodecKind.audio);
      modified = true;
    }

    if (videoProfiles != null) {
      final profiles = videoProfiles;
      final toRemove = profiles.where((p) => p.enabled == false).map((e) => e.option).toList();
      final toReorder = profiles.where((p) => p.enabled == true).map((e) => e.option).toList();

      toRemove.forEach((p) => builder.removeProfile(p));
      builder.reorderProfiles(toReorder, RTPCodecKind.video);
      modified = true;
    }

    if (audioBitrate != null || videoBitrate != null) {
      builder.setBitrate(audioBitrate, videoBitrate);
      modified = true;
    }

    if (ptime != null || maxptime != null) {
      builder.setPtime(ptime, maxptime);
      modified = true;
    }

    if (opusSamplingRate != null || opusBitrate != null || opusStereo != null || opusDtx != null) {
      builder.setOpusParams(opusSamplingRate, opusBitrate, opusStereo, opusDtx);
      modified = true;
    }

    if (removeExtmaps.isNotEmpty) {
      for (final type in removeExtmaps) {
        builder.removeExtmapByUri(type.uri);
      }
      modified = true;
    }

    if (removeStaticAudioRtpMaps) {
      builder.removeStaticAudioRtpMaps();
      modified = true;
    }

    if (remapTE8payloadTo101) {
      builder.remapTE8payloadTo101();
      modified = true;
    }

    if (removeREMBFeedback) {
      builder.removeREMBFeedbacks();
      modified = true;
    }

    if (removeTWCCFeedback) {
      builder.removeTWCCFeedbacks();
      modified = true;
    }

    if (modified) {
      _logger.info('SDP Modified with: $settings');
      final mod = builder.sdp;
      description.sdp = mod;
    }
  }
}
