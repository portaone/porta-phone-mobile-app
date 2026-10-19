import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';

import '../bloc/call_bloc.dart';
import '../models/models.dart';

/// Takes back a request to choose whom to consult once the call it was for is
/// gone, or once the person is back on the call screen.
///
/// The request is made where the person asks for it, and a choice or the
/// banner's own cancel ends it. What neither covers is the call going on
/// meanwhile: the call the person started from can end while they are in the
/// lists - and a banner still offering to consult somebody about it would
/// place a call that is for nothing. Coming back to the call screen without
/// choosing is giving up too: the lists are no longer where the person is,
/// and a banner waiting for them there later would pick for a moment that
/// has passed.
class AttendedTransferPicking extends BlocListener<CallBloc, CallState> {
  AttendedTransferPicking({super.key})
    : super(
        // The calls are watched only while the screen is away: the request is
        // made on the screen a moment before it steps aside, and a call update
        // in that moment is not the person giving up.
        listenWhen: (previous, current) =>
            _returnedToScreen(previous, current) ||
            (current.display != CallDisplay.screen && previous.activeCalls != current.activeCalls),
        listener: _withdrawIfStale,
      );

  static bool _returnedToScreen(CallState previous, CallState current) =>
      previous.display != CallDisplay.screen && current.display == CallDisplay.screen;

  static void _withdrawIfStale(BuildContext context, CallState state) {
    final picking = context.read<DestinationPickingCubit>();
    final purpose = picking.state.purpose;
    if (purpose is! AttendedTransferPurpose) return;

    final anchorGone = state.retrieveActiveCall(purpose.anchorCallId) == null;
    // Reached either because the screen came back - listenWhen lets nothing
    // else through while it is shown - or because the calls changed while it
    // was away.
    if (anchorGone || state.display == CallDisplay.screen) picking.withdraw<AttendedTransferPurpose>();
  }
}
