import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

part 'destination_picking_state.dart';

/// Who, if anybody, is currently waiting for a person to be chosen.
///
/// A feature that wants somebody chosen puts its request here and sends the
/// person to the lists; it does not ask the shell for room and the shell does
/// not ask features whether they want any. That is the whole reason this
/// exists: the screen above the sections reads one state, so a feature can be
/// added without the shell learning its name.
class DestinationPickingCubit extends Cubit<DestinationPickingState> {
  DestinationPickingCubit() : super(const DestinationPickingState());

  /// Asks for somebody to be chosen. Answers whether the request took the
  /// floor.
  ///
  /// A refusal is not a failure to handle: it means somebody is already
  /// choosing for something that outranks this, and the caller should leave
  /// the person where they are rather than send them to the lists.
  bool ask(DestinationPickPurpose purpose) {
    final held = state.purpose;
    if (held != null && purpose.precedence.index <= held.precedence.index) return false;

    emit(DestinationPickingState(purpose: purpose, report: state.report));
    return true;
  }

  /// Takes back a request this feature made, wherever it is in its own life.
  ///
  /// Typed rather than by value: the feature knows what it asked for, not
  /// which of its own purposes is in force by now, and must never clear a
  /// request that belongs to somebody else.
  void withdraw<T extends DestinationPickPurpose>() {
    if (state.purpose is! T) return;

    emit(DestinationPickingState(report: state.report));
  }

  /// The person gave up: the banner's own way out.
  void cancel() => emit(DestinationPickingState(report: state.report));

  /// A destination was chosen and taken. Called by the mechanism rather than
  /// by the feature, so a request cannot be left standing after the choice
  /// that answered it.
  ///
  /// Named rather than blind: a choice answers the request it was offered for,
  /// and a late tap must not close the one that has taken the floor since.
  void finish(DestinationPickPurpose purpose) {
    if (state.purpose != purpose) return;

    emit(DestinationPickingState(report: state.report));
  }

  /// Says what came of it, wherever the person now is.
  void announce(DestinationPickReport report) => emit(DestinationPickingState(purpose: state.purpose, report: report));

  /// Forgets the last report once it has been said, so it is not said twice.
  void reportShown() => emit(DestinationPickingState(purpose: state.purpose));
}
