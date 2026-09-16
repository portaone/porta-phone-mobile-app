import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/app_localizations.g.mapper.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';

/// The header's destructive control: what is picked, the trash, or - where the
/// header offers it - the whole mailbox.
///
/// Which of the three it is depends on where the screen is. That is deliberate:
/// one bulk destructive action per screen is enough, and two of them side by
/// side is how the wrong one gets pressed.
class VoicemailDeleteAction extends StatefulWidget {
  const VoicemailDeleteAction({super.key, required this.offersDeleteAll});

  /// Whether pressing this with nothing picked deletes every message.
  ///
  /// Emptying the mailbox belongs where the feature is managed, so a header
  /// that does not offer it shows this control only while something is picked:
  /// with nothing picked it would have nothing to do.
  ///
  /// Emptying the TRASH is offered by both headers regardless. It is where a
  /// person goes to get rid of things, so refusing to finish the job in one of
  /// the two places the trash is shown would be arbitrary.
  final bool offersDeleteAll;

  @override
  State<VoicemailDeleteAction> createState() => _VoicemailDeleteActionState();
}

class _VoicemailDeleteActionState extends State<VoicemailDeleteAction> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoicemailCubit, VoicemailState>(
      builder: (context, state) {
        final selecting = state.isMultipleVoicemailsSelection;

        if (!selecting && state.isShowingTrash) {
          return _EmptyTrashAction(count: state.trashedItems.length);
        }

        // Where there is a trash, deleting every message is not offered. The
        // trash already carries the one bulk action that ends in messages being
        // gone, and multi-select covers anything narrower; a second sweep next
        // to it would differ only in which of them can be taken back.
        if (!selecting && (!widget.offersDeleteAll || state.trashSupported)) return const SizedBox.shrink();

        // The button names itself, so while selecting it says how much it would
        // delete as part of that name - a count of its own would become a
        // second, nameless stop next to it. The badge draws the number and
        // stays silent.
        return SemanticAction(
          label: selecting
              ? '${context.l10n.voicemail_Label_delete}, '
                    '${context.l10n.common_SemanticsValue_selectedCount(state.selectedVoicemailsIds.length)}'
              : context.l10n.voicemail_Label_delete,
          child: Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: state.visibleItems.isNotEmpty
                    ? () => selecting ? _onDeleteSelected() : _onDeleteAll()
                    : null,
              ),
              if (selecting)
                CountBadge(
                  count: state.selectedVoicemailsIds.length,
                  size: 16,
                  // The count belongs to a destructive action, not to the
                  // accent every other badge carries.
                  color: Theme.of(context).colorScheme.error,
                  onColor: Theme.of(context).colorScheme.onError,
                ),
            ],
          ),
        );
      },
    );
  }

  void _onDeleteAll() async {
    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.voicemail_Label_deleteAll,
          content: context.l10n.voicemail_Label_deleteAllDescription,
        )) ??
        false;

    if (confirmed && mounted) {
      context.read<VoicemailCubit>().removeAllVoicemails();
    }
  }

  void _onDeleteSelected() async {
    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.voicemail_Dialog_deleteSelectedTitle,
          content: context.l10n.voicemail_Dialog_deleteSelectedContent,
        )) ??
        false;

    if (confirmed && mounted) {
      context.read<VoicemailCubit>().removeSelectedVoicemails();
    }
  }
}

/// Finishes what the trash started, for everything in it at once.
class _EmptyTrashAction extends StatefulWidget {
  const _EmptyTrashAction({required this.count});

  final int count;

  @override
  State<_EmptyTrashAction> createState() => _EmptyTrashActionState();
}

class _EmptyTrashActionState extends State<_EmptyTrashAction> {
  @override
  Widget build(BuildContext context) {
    return SemanticAction(
      label: context.l10n.voicemail_Label_emptyTrashAction,
      child: IconButton(
        icon: const Icon(Icons.delete_sweep),
        // Nothing to empty is not an error worth a dialog; the control simply
        // has nothing to do, which is what a disabled button says.
        onPressed: widget.count > 0 ? _onEmptyTrash : null,
      ),
    );
  }

  void _onEmptyTrash() async {
    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.voicemail_Dialog_emptyTrashTitle,
          // The count is in the question because it is the part a person
          // cannot check once the dialog is covering the list.
          content: context.l10n.voicemail_Dialog_emptyTrashContent(widget.count),
        )) ??
        false;

    if (confirmed && mounted) {
      context.read<VoicemailCubit>().emptyVoicemailTrash();
    }
  }
}
