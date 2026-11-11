import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/chat_conversation_builder_cubit.dart';

/// A new chat on a watch: a page in place of the phone's sheet, built like
/// Contacts - the title, the search as one pill (the watch keyboard over the
/// whole face), the bar, the rows. Create group first where groups are on,
/// then the contacts; a tap opens the chat. Create group picks the members
/// (tinted with a tick, Next on the edge), then the name - a pill opening the
/// keyboard - with Create on the edge once it is long enough. Back steps back
/// through the stages before it leaves.
class ChatConversationBuilderWatch extends StatelessWidget {
  const ChatConversationBuilderWatch({super.key});

  /// The shortest group name the phone takes.
  static const minGroupNameLength = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ChatConversationBuilderCubit>();
    return BlocBuilder<ChatConversationBuilderCubit, ChatCBState>(
      builder: (context, state) => PopScope(
        canPop: state is! ChatCBGroupContactsSelection && state is! ChatCBGroupFillInfo,
        onPopInvokedWithResult: (didPop, _) => _onPop(cubit, state, didPop: didPop),
        child: Scaffold(
          body: switch (state) {
            ChatCBDialogContactSelection() => _DialogContacts(state: state),
            ChatCBGroupContactsSelection() => _GroupContacts(state: state),
            ChatCBGroupFillInfo() => _GroupName(state: state),
            ChatCBInitializingError(:final error) => WatchStatePage(
              title: l10n.messaging_ConversationBuilders_title_new,
              icon: const Icon(Icons.error_outline),
              message: error.toString(),
            ),
            _ => WatchStatePage.loading(
              title: l10n.messaging_ConversationBuilders_title_new,
              progressLabel: l10n.common_SemanticsLabel_loading,
            ),
          },
        ),
      ),
    );
  }

  /// Back steps back through the stages, and waits while the group is being
  /// made: the cubit writes the name stage back when the request ends, over
  /// the stage Back went to.
  static void _onPop(ChatConversationBuilderCubit cubit, ChatCBState state, {required bool didPop}) {
    if (didPop || (state is ChatCBGroupFillInfo && state.processing)) return;
    cubit.onBackToPrevStage();
  }
}

/// The search pill over a list of contacts.
class _Search extends StatelessWidget {
  const _Search({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WatchSearchRow(
      initialQuery: query,
      onChanged: context.read<ChatConversationBuilderCubit>().onSearchFilterChange,
      searchLabel: l10n.messaging_ConversationBuilders_contactSearch_hint,
      clearLabel: l10n.contacts_SemanticsLabel_clearSearch,
    );
  }
}

class _DialogContacts extends StatelessWidget {
  const _DialogContacts({required this.state});

  final ChatCBDialogContactSelection state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ChatConversationBuilderCubit>();
    final contacts = state.filteredContacts.toList();
    final first = state.enableGroupChats ? 1 : 0;
    return WatchScrollList.builder(
      title: l10n.messaging_ConversationBuilders_title_new,
      header: [
        _Search(query: state.searchFilter),
        const WatchSeparator(),
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: first + (contacts.isEmpty ? 1 : contacts.length),
      // Create group first where groups are on, then the contacts or the line
      // saying there are none.
      itemBuilder: (context, index) => switch (index - first) {
        < 0 => WatchListTile(
          leading: const Icon(Icons.group_add),
          title: l10n.messaging_ConversationBuilders_createGroup,
          onTap: cubit.onGroupCreateStageChoosen,
        ),
        _ when contacts.isEmpty => WatchListNote(l10n.messaging_ConversationBuilders_noContacts),
        final row => _ContactRow(contacts[row]),
      },
    );
  }
}

/// A contact to open the chat with, its extension under the name.
class _ContactRow extends StatelessWidget {
  const _ContactRow(this.contact);

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return WatchListTile(
      leading: WatchContactAvatar(contact: contact),
      title: contact.displayTitle,
      subtitle: switch (contact.extension) {
        final extension? => context.l10n.messaging_ConversationBuilders_contactExtension(extension),
        null => null,
      },
      onTap: () => context.read<ChatConversationBuilderCubit>().onDialogCreateConfirm(contact),
    );
  }
}

class _GroupContacts extends StatelessWidget {
  const _GroupContacts({required this.state});

  final ChatCBGroupContactsSelection state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ChatConversationBuilderCubit>();
    final contacts = state.filteredContacts.toList();
    final picked = state.selectedContacts;
    return WatchScrollList.builder(
      title: l10n.messaging_ConversationBuilders_title_group,
      header: [
        _Search(query: state.searchFilter),
        const WatchSeparator(),
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: contacts.isEmpty ? 1 : contacts.length,
      itemBuilder: (context, index) => contacts.isEmpty
          ? WatchListNote(l10n.messaging_ConversationBuilders_noContacts)
          : _MemberRow(contacts[index], selected: picked.contains(contacts[index])),
      // Next counts the members, shown once one is picked.
      edge: picked.isEmpty
          ? null
          : (context, overlay) => WatchAction(
              label: l10n.messaging_Watch_nextMembers(picked.length),
              onPressed: cubit.onGroupFillInfoStageChoosen,
            ).buildButton(overlay),
    );
  }
}

/// A contact to pick for the group or drop from it, tinted with a tick once
/// picked.
class _MemberRow extends StatelessWidget {
  const _MemberRow(this.contact, {required this.selected});

  final Contact contact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatConversationBuilderCubit>();
    return WatchListTile(
      leading: WatchContactAvatar(contact: contact),
      title: contact.displayTitle,
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () => selected ? cubit.onGroupContactDeselected(contact) : cubit.onGroupContactSelected(contact),
    );
  }
}

class _GroupName extends StatefulWidget {
  const _GroupName({required this.state});

  final ChatCBGroupFillInfo state;

  @override
  State<_GroupName> createState() => _GroupNameState();
}

class _GroupNameState extends State<_GroupName> {
  /// What the keyboard types into.
  late final _name = TextEditingController(text: widget.state.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = context.l10n;
    final cubit = context.read<ChatConversationBuilderCubit>();
    // Counted as the phone counts it, spaces and all.
    final ready = state.name.length >= ChatConversationBuilderWatch.minGroupNameLength && !state.processing;
    final rows = [
      WatchListLabel(l10n.messaging_ConversationBuilders_membersHeadline),
      for (final contact in state.selectedContacts)
        WatchListTile(
          leading: WatchContactAvatar(contact: contact),
          title: contact.displayTitle,
          readOnly: true,
        ),
    ];
    final list = WatchScrollList.builder(
      title: l10n.messaging_ConversationBuilders_title_group,
      header: [
        WatchKeyboardInput(
          controller: _name,
          onChanged: cubit.onGroupNameChange,
          builder: (context, open) => WatchPillButton(
            label: state.name.isEmpty ? l10n.messaging_ConversationBuilders_nameFieldLabel : state.name,
            semanticsLabel: [
              l10n.messaging_ConversationBuilders_nameFieldLabel,
              if (state.name.isNotEmpty) state.name,
            ].join(', '),
            icon: Icons.edit,
            onPressed: state.processing ? null : open,
          ),
        ),
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index],
      edge: (context, overlay) => WatchAction(
        label: l10n.messaging_ConversationBuilders_create,
        onPressed: ready ? cubit.onGroupCreateConfirm : null,
      ).buildButton(overlay),
    );
    // While the group is being made: a spinner over the stage, as the phone's
    // sheet, and the stage taking no taps. The list stays the same widget in
    // the same place, so it keeps its scroll and the name field its focus.
    return Stack(
      children: [
        AbsorbPointer(absorbing: state.processing, child: list),
        if (state.processing) Center(child: WatchSpinner(label: l10n.common_SemanticsLabel_loading)),
      ],
    );
  }
}
