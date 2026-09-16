import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/models/models.dart';

/// Announces to every list below it that somebody is being chosen, and why.
///
/// The lists ask this one question - "am I picking, and can this row be
/// picked?" - instead of each knowing which feature wants somebody and how to
/// tell it. Adding a purpose adds a [DestinationPickPurpose]; the lists do not
/// change.
class DestinationPicking extends InheritedWidget {
  const DestinationPicking({super.key, required this.purpose, required super.child});

  /// What is being picked for, or null when nothing is.
  final DestinationPickPurpose? purpose;

  /// The purpose in force, or null when the lists are behaving normally.
  static DestinationPickPurpose? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DestinationPicking>()?.purpose;
  }

  @override
  bool updateShouldNotify(DestinationPicking oldWidget) => purpose != oldWidget.purpose;
}

/// Hands a choice over, if the purpose will take it. Answers whether it did.
///
/// The acceptance check lives here rather than at each place a person can be
/// picked from. A screen that forgets it is exactly the failure this mechanism
/// exists to remove - the purpose's own rule silently not applying on one of
/// them - and a screen cannot forget a check it does not perform.
bool submitDestination(DestinationPickPurpose purpose, DestinationCandidate candidate) {
  if (!purpose.accepts(candidate)) return false;

  purpose.submit(candidate);
  return true;
}

/// What a row does when it is picked: hand the choice over, then leave.
///
/// Leaving is half of it. The choice was made on a list the person was sent
/// to, so the list has done its job; staying would leave them looking at the
/// place they came from with nothing left to do there. A choice the purpose
/// refuses leaves the screen where it is: nothing happened, so there is
/// nothing to come back from.
bool pickDestination(BuildContext context, DestinationPickPurpose purpose, DestinationCandidate candidate) {
  if (!submitDestination(purpose, candidate)) return false;

  context.router.maybePop();
  return true;
}

/// How a row should behave right now.
///
/// Both halves matter and they are not the same question. While a choice is
/// being made every row stops doing what it normally does - expanding, dialling
/// - whether or not it can be chosen; only a row the purpose accepts becomes
/// tappable.
extension DestinationPickingContext on BuildContext {
  DestinationPickPurpose? get pickPurpose => DestinationPicking.of(this);

  /// Whether a choice is being made at all.
  bool get isPickingDestination => DestinationPicking.of(this) != null;
}
