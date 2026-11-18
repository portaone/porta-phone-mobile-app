import '../abstract_events.dart';

class IncomingCallEvent extends CallEvent {
  const IncomingCallEvent({
    super.transaction,
    required super.line,
    required super.callId,
    required this.callee,
    required this.caller,
    this.callerDisplayName,
    this.referredBy,
    this.replaceCallId,
    this.isFocus,
    this.jsep,
    this.offeredAt,
  });

  final String callee;
  final String caller;
  final String? callerDisplayName;
  final String? referredBy;
  final String? replaceCallId;
  final bool? isFocus;
  final Map<String, dynamic>? jsep;

  /// Core's `offered_at`, epoch milliseconds by Core's clock: the moment Core learned of this
  /// offer, when Janus reported its incomingcall - once per INVITE to this app.
  ///
  /// The event, its push (`offeredAt`) and the handshake's call log carry the same value; a new
  /// offer of the same Call-ID (a transfer back, a retried transfer) gets another. Two apps of one
  /// user get different values for one call. It identifies the offer: compare it for equality only,
  /// never with a clock. Null from a Core that does not send it.
  final int? offeredAt;

  @override
  List<Object?> get props => [
    ...super.props,
    callee,
    caller,
    callerDisplayName,
    referredBy,
    replaceCallId,
    isFocus,
    jsep,
    offeredAt,
  ];

  static const typeValue = 'incoming_call';

  @override
  Map<String, dynamic> toJson() => {
    ...callBaseJson(typeValue),
    'callee': callee,
    'caller': caller,
    if (callerDisplayName != null) 'caller_display_name': callerDisplayName,
    if (referredBy != null) 'referred_by': referredBy,
    if (replaceCallId != null) 'replace_call_id': replaceCallId,
    if (isFocus != null) 'is_focus': isFocus,
    if (jsep != null) 'jsep': jsep,
    if (offeredAt != null) 'offered_at': offeredAt,
  };

  factory IncomingCallEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return IncomingCallEvent(
      transaction: json['transaction'],
      line: json['line'],
      callId: json['call_id'],
      callee: json['callee'],
      caller: json['caller'],
      callerDisplayName: json['caller_display_name'],
      referredBy: json['referred_by'],
      replaceCallId: json['replace_call_id'],
      isFocus: json['is_focus'],
      jsep: json['jsep'],
      // Epoch milliseconds; a number of any kind is taken, anything else as none.
      offeredAt: switch (json['offered_at']) {
        final num ms => ms.toInt(),
        _ => null,
      },
    );
  }
}
