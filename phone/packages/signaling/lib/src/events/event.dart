import 'package:equatable/equatable.dart';

import 'abstract_events.dart';

abstract class Event extends Equatable {
  const Event();

  static const typeKey = 'event';

  factory Event.fromJson(Map<String, dynamic> json) {
    final event = tryFromJson(json);
    if (event == null) {
      final eventTypeValue = json[Event.typeKey];
      if (eventTypeValue == ErrorEvent.typeValue) {
        throw ArgumentError('Incorrect error event');
      } else if (eventTypeValue is String) {
        throw UnknownEventTypeError(eventTypeValue);
      } else {
        throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Incorrect event type');
      }
    } else {
      return event;
    }
  }

  static Event? tryFromJson(Map<String, dynamic> json) {
    return GlobalEvent.tryFromJson(json) ?? SessionEvent.tryFromJson(json);
  }

  Map<String, dynamic> toJson();
}

/// An event whose type is well formed but has no decoder in this app.
///
/// Any other decoding failure stays a plain [ArgumentError] or the error of the
/// event's own `fromJson`: those mean a broken message, this one a server newer
/// than the app.
class UnknownEventTypeError extends ArgumentError {
  UnknownEventTypeError(this.type) : super.value(type, Event.typeKey, 'Unknown event type');

  final String type;
}
