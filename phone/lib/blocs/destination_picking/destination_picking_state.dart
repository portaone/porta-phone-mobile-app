part of 'destination_picking_cubit.dart';

/// Both halves of what the shell above the sections has to know: who is asking
/// for a person, and what is waiting to be said about a choice already made.
///
/// They are independent - a report outlives the request that produced it, and
/// arrives when the request is already gone - so every transition names both
/// rather than copying one over. A `copyWith` here would make "leave this as
/// it was" and "clear this" the same call, which is how a request or a
/// sentence goes missing.
class DestinationPickingState extends Equatable {
  const DestinationPickingState({this.purpose, this.report});

  /// What somebody is being chosen for, or null when nothing is.
  final DestinationPickPurpose? purpose;

  /// What is waiting to be said about a choice that is over.
  final DestinationPickReport? report;

  @override
  List<Object?> get props => [purpose, report];
}
