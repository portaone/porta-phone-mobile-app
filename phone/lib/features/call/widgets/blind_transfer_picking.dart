import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../bloc/call_bloc.dart';
import '../controllers/call_controller.dart';
import '../models/blind_transfer_purpose.dart';

/// Mirrors "this call is looking for somebody to be handed to" into the
/// mechanism that sends people to the lists.
///
/// The call keeps owning that state, and deliberately so: it is one of six
/// states of a transfer, set in one place inside [CallBloc] and cleared in ten -
/// signalling failures, the call ending, the attended-transfer branches. A
/// second copy driven by hand from each of those places would be one forgotten
/// edge away from a banner nothing can take off the screen.
///
/// So the call is not asked to push. One slice of what it already publishes is
/// reflected here, in one direction, and the mechanism learns nothing about
/// calls.
///
/// A bridge is what a mode already living in somebody else's bloc needs. A
/// feature that decides for itself asks the mechanism where the person asks for
/// it, and mounts nothing.
class BlindTransferPicking extends BlocListener<CallBloc, CallState> {
  BlindTransferPicking({super.key, required CallController controller})
    : super(
        listenWhen: (previous, current) => previous.isBlingTransferInitiated != current.isBlingTransferInitiated,
        listener: (context, state) => _mirror(context, state, controller),
      );

  static void _mirror(BuildContext context, CallState state, CallController controller) {
    final picking = context.read<DestinationPickingCubit>();

    if (!state.isBlingTransferInitiated) {
      picking.withdraw<BlindTransferPurpose>();
      return;
    }

    picking.ask(
      BlindTransferPurpose(
        announcement: context.l10n.main_Text_blindTransferInitiated,
        pickLabel: context.l10n.contact_SemanticsLabel_transfer,
        controller: controller,
      ),
    );
  }
}
