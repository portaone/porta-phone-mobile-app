/// The app's answer to a request that an embedded page posted on one of its channels.
///
/// A page that posts a request - a signup on the login channel, for one - waits for its outcome
/// and cannot learn it by itself. The app hands it this through `window.onWebTritResult` when the
/// resource's `resultStrategy` is `notify`. The shape is the same for every request; which
/// [reason] values a request can end with is part of that request's own contract.
class PageResult {
  const PageResult({required this.channel, required this.event, required this.ok, this.reason});

  /// The channel the request came on, such as `WebtritLoginChannel`.
  final String channel;

  /// The event the page posted, such as `signup`.
  final String event;

  /// Whether the request reached what the page asked for.
  final bool ok;

  /// Why it did not, when [ok] is false.
  final String? reason;

  Map<String, Object> toJson() => {'channel': channel, 'event': event, 'ok': ok, 'reason': ?reason};

  @override
  String toString() => 'PageResult($channel.$event, ok: $ok${reason == null ? '' : ', $reason'})';
}
