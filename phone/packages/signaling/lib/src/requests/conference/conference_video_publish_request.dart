import '../../conference_video_types.dart';
import '../abstract_requests.dart';

/// Publishes the client's camera and/or screen to the conference room, or
/// renegotiates what it publishes (adding or removing the screen, an ICE
/// restart) with a new offer on the same publisher PeerConnection.
///
/// The offer carries video only - audio goes through the mixer - and should
/// list both H.264 and VP8: the room never transcodes. [descriptions] names each
/// video m-line by its `mid`; without them Core publishes every m-line as a
/// camera, so an empty list is left out of the request. The answer arrives as
/// `conference_video_publisher_answer`.
class ConferenceVideoPublishRequest extends SessionRequest {
  const ConferenceVideoPublishRequest({required super.transaction, required this.jsep, this.descriptions = const []});

  final Map<String, dynamic> jsep;
  final List<ConferenceVideoDescription> descriptions;

  @override
  List<Object?> get props => [...super.props, jsep, descriptions];

  static const typeValue = 'conference_video_publish';

  factory ConferenceVideoPublishRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    final descriptions = json['descriptions'] as List<dynamic>?;
    return ConferenceVideoPublishRequest(
      transaction: json['transaction'] as String,
      jsep: json['jsep'] as Map<String, dynamic>,
      descriptions: descriptions == null
          ? const []
          : descriptions
                .map((e) => ConferenceVideoDescription.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      Request.typeKey: typeValue,
      'transaction': transaction,
      'jsep': jsep,
      if (descriptions.isNotEmpty) 'descriptions': descriptions.map((d) => d.toJson()).toList(growable: false),
    };
  }
}
