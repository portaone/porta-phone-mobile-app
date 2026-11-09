import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/call_direction.dart';

class CallLogEntry extends Equatable {
  final int id;
  final CallDirection direction;
  final String number;
  final bool video;
  final DateTime createdTime;
  final String? username;
  final DateTime? acceptedTime;
  final DateTime? hungUpTime;

  const CallLogEntry({
    required this.id,
    required this.direction,
    required this.number,
    required this.video,
    required this.createdTime,
    this.username,
    this.acceptedTime,
    this.hungUpTime,
  });

  bool get isComplete => acceptedTime != null;

  /// An incoming call nobody answered: what the Missed filter keeps, and
  /// what a list marks as missed.
  bool get isMissedIncoming => !isComplete && direction == CallDirection.incoming;

  Duration? get duration {
    final hungUpTime = this.hungUpTime;
    final acceptedTime = this.acceptedTime;
    if (hungUpTime != null && acceptedTime != null) {
      return hungUpTime.difference(acceptedTime);
    } else {
      return null;
    }
  }

  @override
  String toString() {
    return 'CallLogEntry{direction: id: $id, $direction, number: $number, video: $video, username: $username, createdTime: $createdTime, acceptedTime: $acceptedTime, hungUpTime: $hungUpTime}';
  }

  @override
  List<Object?> get props => [id, direction, number, video, createdTime, username, acceptedTime, hungUpTime];
}
