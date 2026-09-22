import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/app/constants.dart';

import 'package:webtrit_phone/models/system_info/system_info.dart';

// TODO:
// - rename to adapter supported flags or
// - think about remove it because its useles abstraction
//   - we already have system info in our models, and its enough to move this getters to AdapterInfo
//   - also real core supported getters exist in CoreInfo so there is logical mess
//   - see [SipPresenceMapper] for example

/// Abstraction for checking core system feature support.
abstract class CoreSupport {
  /// Check if the voicemail feature is supported by remote system.
  bool get supportsVoicemail;

  /// Whether a voicemail message can be kept, which the backend reports
  /// separately from voicemail itself.
  bool get supportsVoicemailSave;

  /// Whether deleting a voicemail means moving it to a trash it can be
  /// recovered from.
  bool get supportsVoicemailTrash;

  /// Whether a voicemail can be passed on to another user of the same backend.
  bool get supportsVoicemailForward;

  /// Check if the call center queues feature is supported by remote system.
  bool get supportsCallCenter;

  /// Check if the SMS messaging feature is supported by remote system.
  bool get supportsSms;

  /// Check if the internal messaging feature is supported by remote system.
  bool get supportsChats;

  /// Whether one conversation's notifications can be muted, which the backend
  /// reports separately from chats and SMS themselves.
  bool get supportsConversationMute;

  /// Check if the core system supports system notifications and push sending.
  bool get supportsSystemNotifications;

  /// Check if the system push notifications feature is supported by remote system.
  bool get supportsSystemPushNotifications;

  /// Check if the call-to-action list feature is supported by the remote system.
  bool get supportsCallToActions;

  /// Check if the call history (CDR) feature is supported by the remote system.
  bool get supportsCallHistory;

  /// Check if the external (server/PBX) contacts directory is supported by the remote system.
  bool get supportsExtensions;

  /// Check if the remote system bundles its own STUN/TURN servers, which the app
  /// then loads instead of falling back to a public STUN server.
  bool get supportsBundledIceServers;
}

class CoreSupportImpl extends Equatable implements CoreSupport {
  CoreSupportImpl(List<String>? supported, {bool iceServersConfigured = false})
    : _flags = {...?supported},
      _iceServersConfigured = iceServersConfigured;

  final Set<String> _flags;

  /// Not an adapter flag: the core advertises bundled ICE servers under `core`
  /// in `system-info`, not in `adapter.supported`.
  final bool _iceServersConfigured;

  bool _has(String flag) => _flags.contains(flag);

  @override
  bool get supportsVoicemail => _has(kVoicemailFeatureFlag);

  @override
  bool get supportsVoicemailSave => _has(kVoicemailSaveFeatureFlag);

  @override
  bool get supportsVoicemailTrash => _has(kVoicemailTrashFeatureFlag);

  @override
  bool get supportsVoicemailForward => _has(kVoicemailForwardFeatureFlag);

  @override
  bool get supportsCallCenter => _has(kCallCenterFeatureFlag);

  @override
  bool get supportsSms => _has(kSmsMessagingFeatureFlag);

  @override
  bool get supportsChats => _has(kChatMessagingFeatureFlag);

  @override
  bool get supportsConversationMute => _has(kConversationMuteFeatureFlag);

  @override
  bool get supportsSystemNotifications => _has(kSystemNotificationsFeatureFlag);

  @override
  bool get supportsSystemPushNotifications => _has(kSystemNotificationsPushFeatureFlag);

  @override
  bool get supportsCallToActions => _has(kCtaListFeatureFlag);

  @override
  bool get supportsCallHistory => _has(kCallHistoryFeatureFlag);

  @override
  bool get supportsExtensions => _has(kExtensionsFeatureFlag);

  @override
  bool get supportsBundledIceServers => _iceServersConfigured;

  @override
  List<Object?> get props {
    final sortedFlags = _flags.toList()..sort();
    return [List.unmodifiable(sortedFlags), _iceServersConfigured];
  }
}

class CoreSupportFactory {
  static CoreSupport create(WebtritSystemInfo? systemInfo) {
    return CoreSupportImpl(
      systemInfo?.adapter?.supported,
      iceServersConfigured: systemInfo?.core.iceServersConfigured ?? false,
    );
  }
}
