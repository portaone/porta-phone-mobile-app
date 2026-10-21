import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import 'number_choice_sheet.dart';

/// Which of a contact's numbers to give to [purpose], for a contact the
/// purpose will not take as a whole because it has several.
///
/// The sheet belongs to the request it was opened for and goes when the
/// request does: the call it was asked for can end, or another request take
/// over, while the person is still looking at it. Left open, a number tapped
/// there would answer nobody and the sheet would close with nothing happening.
class DestinationNumberPicker extends StatelessWidget {
  const DestinationNumberPicker({required this.picking, required this.purpose, required this.choices, super.key});

  /// The requests, read where the sheet was opened from: a sheet sits on a
  /// route of its own, which need not be under the provider.
  final DestinationPickingCubit picking;

  final DestinationPickPurpose purpose;
  final List<NumberChoice> choices;

  /// The number picked, or null when the sheet was closed without one or went
  /// with its request.
  static Future<String?> show(
    BuildContext context, {
    required DestinationPickPurpose purpose,
    required List<NumberChoice> choices,
  }) {
    final picking = context.read<DestinationPickingCubit>();
    return context.showModalBottomSheet<String>(
      builder: (context) => DestinationNumberPicker(picking: picking, purpose: purpose, choices: choices),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DestinationPickingCubit, DestinationPickingState>(
      bloc: picking,
      listenWhen: (previous, current) => current.purpose != purpose,
      listener: _close,
      child: NumberChoiceSheet(
        title: context.l10n.contacts_DestinationNumberPicker_title,
        choices: choices,
        identifier: destinationNumberPickerId,
        choiceIdentifier: destinationNumberOptionId,
      ),
    );
  }

  // Only while the sheet is on top: once it is closing, popping again would
  // take the screen under it.
  void _close(BuildContext context, DestinationPickingState state) {
    if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.of(context).pop();
  }
}
