import 'dart:async';

/// One kind of push on its way from the global handler to whoever in the app
/// takes it.
///
/// Every listener sees every push. Whether a push that arrives before anyone
/// listens is kept is stated when the channel is made, because it is the whole
/// difference between the channels and is easy to get wrong by copying one.
class PushChannel<T> {
  PushChannel._(this._controller, this.stream);

  /// Holds what arrives until the first listener comes, then hands it over.
  ///
  /// For a push that opened the app: it arrives before the session that
  /// handles it is up. Once someone has listened, nothing more is held - a
  /// push arriving with nobody listening is dropped.
  factory PushChannel.buffered() {
    final controller = StreamController<T>();
    return PushChannel._(controller, controller.stream.asBroadcastStream());
  }

  final StreamController<T> _controller;

  /// The pushes of this kind; any number of listeners may subscribe.
  final Stream<T> stream;

  /// Hands [push] to the listeners, or holds it if the channel was made to.
  void add(T push) => _controller.add(push);
}
