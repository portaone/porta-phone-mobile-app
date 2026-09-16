import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/bloc.dart';

/// Size of the marks around the filter's name, and the space between them.
///
/// A size down from a button's, because this is a line of text with an icon on
/// either side rather than a control with a shape of its own.
const _pickerIconSize = 20.0;
const _pickerGap = 8.0;
const _pickerMenuGap = 12.0;

/// The line under the title: which messages are being shown, and how many are
/// still unheard.
///
/// It goes in the app bar rather than at the top of the list. The tab shell
/// runs its body behind a transparent bar, so a row placed with the list would
/// sit underneath that bar; and a filter belongs with the title it qualifies,
/// not with the first item of what it selected.
class VoicemailFilterRow extends StatelessWidget implements PreferredSizeWidget {
  const VoicemailFilterRow({super.key});

  /// What the app bar reserves for this row: the control plus the gap that
  /// separates it from the list below.
  static const height = kMainAppBarBottomControlHeight + kMainAppBarBottomPaddingGap;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<VoicemailCubit, VoicemailState>(
      buildWhen: (previous, current) =>
          previous.filter != current.filter ||
          previous.filters != current.filters ||
          previous.unheardCount != current.unheardCount,
      builder: (context, state) {
        // One filter is no choice, so the control that offers the choice is not
        // drawn. That is the plain mailbox: no save, no trash, nothing to pick
        // between but All and New.
        if (state.filters.length < 2) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: kMainAppBarBottomPaddingGap),
          child: SizedBox(
            height: kMainAppBarBottomControlHeight,
            child: Row(
              children: [
                VoicemailFilterPicker(
                  filters: state.filters,
                  selected: state.filter,
                  onSelected: (filter) => context.read<VoicemailCubit>().setFilter(filter),
                ),
                const Spacer(),
                if (state.unheardCount > 0)
                  Text(
                    context.l10n.voicemail_Label_unheardCount(state.unheardCount),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Picks which messages the list shows, as the compact control the contacts
/// screen uses to pick which address book it is drawing.
///
/// The same shape on purpose: both answer "which list am I looking at", both
/// are changed seldom, and a person who has learned one has learned the other.
class VoicemailFilterPicker extends StatelessWidget {
  const VoicemailFilterPicker({super.key, required this.filters, required this.selected, required this.onSelected});

  final List<VoicemailFilter> filters;
  final VoicemailFilter selected;
  final ValueChanged<VoicemailFilter> onSelected;

  IconData _icon(VoicemailFilter filter) => switch (filter) {
    VoicemailFilter.all => Icons.inbox_outlined,
    VoicemailFilter.unheard => Icons.mark_email_unread_outlined,
    VoicemailFilter.saved => Icons.bookmark_outline,
    VoicemailFilter.trash => Icons.delete_outline,
  };

  String _label(BuildContext context, VoicemailFilter filter) => switch (filter) {
    VoicemailFilter.all => context.l10n.voicemail_Filter_all,
    VoicemailFilter.unheard => context.l10n.voicemail_Filter_unheard,
    VoicemailFilter.saved => context.l10n.voicemail_Filter_saved,
    VoicemailFilter.trash => context.l10n.voicemail_Filter_trash,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      // The name says which filter is on, because the control's own label is
      // the word it currently shows and a reader would otherwise announce the
      // value twice and the purpose not at all.
      label: context.l10n.voicemail_SemanticsLabel_filter(_label(context, selected)),
      identifier: voicemailFilterPickerId,
      button: true,
      child: PopupMenuButton<VoicemailFilter>(
        key: voicemailFilterPickerKey,
        initialValue: selected,
        onSelected: onSelected,
        // No tooltip. It merges into the same semantics node as the label
        // above and is then spoken on top of it, which says the same sentence
        // twice and gives the picker's own name nowhere to be heard.
        tooltip: '',
        itemBuilder: (context) => [
          for (final filter in filters)
            PopupMenuItem(
              value: filter,
              child: Row(
                spacing: _pickerMenuGap,
                children: [
                  Icon(_icon(filter), size: _pickerIconSize),
                  Expanded(child: Text(_label(context, filter))),
                  if (filter == selected) Icon(Icons.check, size: _pickerIconSize, color: theme.colorScheme.primary),
                ],
              ),
            ),
        ],
        // What is drawn is the filter's own name with marks around it, and the
        // name above already says it as part of a sentence. Left visible to
        // semantics it merges into the same node and is announced a second
        // time, on its own, after the sentence that explains it. The button's
        // tap action sits above this, so excluding the drawing costs nothing.
        child: ExcludeSemantics(
          child: SizedBox(
            height: kMainAppBarBottomControlHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _pickerGap,
              children: [
                Icon(_icon(selected), size: _pickerIconSize, color: theme.colorScheme.onSurfaceVariant),
                Text(_label(context, selected), style: theme.textTheme.bodyMedium),
                Icon(Icons.expand_more, size: _pickerIconSize, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
