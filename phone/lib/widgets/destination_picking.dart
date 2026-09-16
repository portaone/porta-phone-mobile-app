import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
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
///
/// Closing the request is the other half, and for the same reason: the feature
/// that asked is by now waiting on a backend somewhere, and a request left
/// standing would keep every list in picking mode with nothing left to pick
/// for. Only where the choice is what ends it - a purpose mirroring a mode it
/// does not own here says so, and is closed by whoever does own it.
bool submitDestination(BuildContext context, DestinationPickPurpose purpose, DestinationCandidate candidate) {
  final picking = context.read<DestinationPickingCubit>();

  // A row built for a request that no longer holds the floor is no answer to
  // the one that does. A live request can take over between a row being built
  // and a tap landing on it, and the tap must not act for whoever has since
  // been pushed aside - nor close the request that replaced them.
  if (picking.state.purpose != purpose) return false;
  if (!purpose.accepts(candidate)) return false;

  purpose.submit(candidate);
  if (purpose.closedByChoice) picking.finish(purpose);
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
  if (!submitDestination(context, purpose, candidate)) return false;

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
