import 'package:equatable/equatable.dart';

import '../abstract_events.dart';

/// The voicemail box changed: a message was left, heard or deleted on any device.
///
/// Means "read the box again", not "a message arrived". Not tied to a line or a
/// call, and not a [GlobalEvent]: those are the presence and dialogs the call
/// feature takes in, this one is for voicemail. [voiceMessage] comes only when
/// the SIP server reports the counters; PortaSwitch does not.
class MessageSummaryUpdate extends Event {
  const MessageSummaryUpdate({required this.messagesWaiting, this.voiceMessage});

  static const typeValue = 'message_summary_update';
  final bool messagesWaiting;
  final SignalingVoiceMessageSummary? voiceMessage;

  @override
  List<Object?> get props => [messagesWaiting, voiceMessage];

  static MessageSummaryUpdate? tryFromJson(Map<String, dynamic> json) {
    return json[Event.typeKey] == typeValue ? MessageSummaryUpdate.fromJson(json) : null;
  }

  factory MessageSummaryUpdate.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    final voiceMessage = json['voice_message'];
    return MessageSummaryUpdate(
      messagesWaiting: json['messages_waiting'] as bool,
      voiceMessage: voiceMessage == null
          ? null
          : SignalingVoiceMessageSummary.fromJson(Map<String, dynamic>.from(voiceMessage as Map)),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    Event.typeKey: typeValue,
    'messages_waiting': messagesWaiting,
    if (voiceMessage != null) 'voice_message': voiceMessage!.toJson(),
  };
}

/// Voice message counters of a [MessageSummaryUpdate].
class SignalingVoiceMessageSummary with EquatableMixin {
  const SignalingVoiceMessageSummary({
    required this.newCount,
    required this.oldCount,
    required this.urgentNewCount,
    required this.urgentOldCount,
  });

  final int newCount;
  final int oldCount;
  final int urgentNewCount;
  final int urgentOldCount;

  @override
  List<Object?> get props => [newCount, oldCount, urgentNewCount, urgentOldCount];

  factory SignalingVoiceMessageSummary.fromJson(Map<String, dynamic> json) {
    return SignalingVoiceMessageSummary(
      newCount: json['new'] as int,
      oldCount: json['old'] as int,
      urgentNewCount: json['urgent_new'] as int,
      urgentOldCount: json['urgent_old'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'new': newCount,
    'old': oldCount,
    'urgent_new': urgentNewCount,
    'urgent_old': urgentOldCount,
  };
}
