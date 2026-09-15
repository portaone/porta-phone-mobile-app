import 'package:flutter/widgets.dart';

import 'package:webtrit_phone/models/main_flavor.dart';

import 'destination_candidate.dart';

/// Why somebody is being sent to the app's own lists to choose a person, and
/// what happens once they have.
///
/// There is one of these per purpose, and the lists know about none of them.
/// Before this, the one purpose there was - handing a call to somebody else -
/// was spelled out in each of the eight places a person can be picked from:
/// each read the same call flag, each derived its own number, each submitted
/// and popped. A second purpose meant editing all eight, and the lists would
/// have accumulated knowledge of features they have nothing to do with.
abstract interface class DestinationPickPurpose {
  /// What the banner says while the lists are being browsed, already
  /// localized: this is built where a context is at hand, so the lists that
  /// show it need no strings of their own.
  String get announcement;

  /// Whether this section can supply a destination for this purpose.
  ///
  /// Only the sections that can are told that a choice is being made. A page
  /// of conversations announcing a choice that cannot be made there is worse
  /// than saying nothing.
  bool offeredBy(MainFlavor flavor);

  /// Whether this row is a destination this purpose can use.
  ///
  /// A row that is not stays inert rather than disappearing: the list is still
  /// the list, and a person looking for somebody who is not eligible should
  /// see that they are there and not pickable, not wonder where they went.
  bool accepts(DestinationCandidate candidate);

  /// Gives up on the choice, or null where this purpose has no giving up to
  /// offer.
  ///
  /// Not every one needs it. A call being handed over is left by returning to
  /// the call, which is a control the person already has on screen; a message
  /// looking for a recipient has nothing of the kind, and without this the
  /// only way out would be to send it to somebody.
  VoidCallback? get onCancel;

  /// The mark the control that picks a row carries.
  ///
  /// Handing a call on and passing a message along are different gestures, and
  /// a row wearing the phone icon for both says the wrong thing about one of
  /// them.
  IconData get pickIcon;

  /// What the control that picks [candidate] is called, for a reader.
  ///
  /// The wording belongs to the purpose: a row offering to hand a call over
  /// and the same row offering to pass a message along are different
  /// sentences, and a screen that names the control itself can only name one
  /// of them.
  String pickLabel(DestinationCandidate candidate);

  /// Acts on the choice. Called once, and only for a candidate [accepts] took.
  void submit(DestinationCandidate candidate);
}
