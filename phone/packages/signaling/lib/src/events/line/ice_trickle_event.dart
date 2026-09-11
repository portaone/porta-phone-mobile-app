import '../../ice_candidate_json.dart';
import '../abstract_events.dart';

class IceTrickleEvent extends LineEvent {
  const IceTrickleEvent({super.transaction, required super.line, required this.candidate});

  final Map<String, dynamic>? candidate;

  @override
  List<Object?> get props => [...super.props, candidate];

  static const typeValue = 'ice_trickle';

  @override
  Map<String, dynamic> toJson() => {...lineBaseJson(typeValue), 'candidate': iceCandidateToJson(candidate)};

  factory IceTrickleEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return IceTrickleEvent(
      transaction: json['transaction'],
      line: json['line'],
      candidate: iceCandidateFromJson(json['candidate']),
    );
  }
}
