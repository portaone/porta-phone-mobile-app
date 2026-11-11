import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/sms_conversation_builder_cubit.dart';

/// A new SMS conversation on a watch: a page in place of the phone's sheet,
/// built like Contacts - the title, "Name or phone number" as the search pill,
/// the bar, the rows. A number typed that parses is the first row; then the
/// Cloud PBX and the local contacts, one row per SMS number. A tap opens the
/// conversation, or first asks which of the user's numbers it is sent from;
/// an invalid number, or none of the user's own, is said on the face.
class SmsConversationBuilderWatch extends StatefulWidget {
  const SmsConversationBuilderWatch({super.key});

  @override
  State<SmsConversationBuilderWatch> createState() => _SmsConversationBuilderWatchState();
}

class _SmsConversationBuilderWatchState extends State<SmsConversationBuilderWatch> {
  late final _cubit = context.read<SmsConversationBuilderCubit>();

  Future<void> _onState(SmsCBState state) async {
    final l10n = context.l10n;
    switch (state) {
      case SmsCBUserNumberConfirmationNeeded(:final userNumbers) when userNumbers.isNotEmpty:
        final picked = await Navigator.of(context)
            .push<String>(MaterialPageRoute(builder: (_) => _SenderNumberPage(numbers: userNumbers)));
        picked != null ? _cubit.onConfirmUserNumber(picked) : _cubit.onBackToCommon();
      case SmsCBUserNumberConfirmationNeeded():
        await AcknowledgeDialog.show(
          context,
          title: l10n.messaging_ConversationsScreen_noNumberAlert_title,
          content: l10n.messaging_ConversationsScreen_noNumberAlert_text,
        );
        _cubit.onBackToCommon();
      case SmsCBWrongNumberSelected():
        await AcknowledgeDialog.show(
          context,
          title: l10n.messaging_ConversationBuilders_invalidNumber_title,
          content: [
            l10n.messaging_ConversationBuilders_invalidNumber_message1,
            l10n.messaging_ConversationBuilders_numberFormatExample,
            l10n.messaging_ConversationBuilders_invalidNumber_message2,
          ].join(),
        );
        _cubit.onBackToCommon();
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.messaging_ConversationBuilders_title_new;
    return BlocConsumer<SmsConversationBuilderCubit, SmsCBState>(
      listenWhen: (previous, current) =>
          current is SmsCBUserNumberConfirmationNeeded || current is SmsCBWrongNumberSelected,
      listener: (context, state) => unawaited(_onState(state)),
      builder: (context, state) => Scaffold(
        body: switch (state) {
          SmsCBInitializing() => WatchStatePage.loading(
            title: title,
            progressLabel: l10n.common_SemanticsLabel_loading,
          ),
          SmsCBInitializingError(:final error) => WatchStatePage(
            title: title,
            icon: const Icon(Icons.error_outline),
            message: error.toString(),
          ),
          SmsCBCommon() => _List(state: state),
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state});

  final SmsCBCommon state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SmsConversationBuilderCubit>();
    final external = state.externalContacts.toList();
    final local = state.localContacts.toList();
    // Digits only, as the phone's field tells a number from a name.
    final numberTyped = state.searchFilter.length > 6 && RegExp(r'^[0-9]*$').hasMatch(state.searchFilter);
    // What each row is, not the rows themselves: they are built as they
    // scroll into view.
    final rows = <_Row>[
      // A number typed that does not parse: the format it takes, as the
      // phone's field says under it.
      if (numberTyped && state.parsedNumber.isEmpty) const _InvalidNumberRow(),
      // The number typed, once it parses: the phone's Create.
      if (state.parsedNumber.isNotEmpty) const _ParsedNumberRow(),
      if (external.isNotEmpty) ...[
        const _LabelRow(external: true),
        for (final contact in external)
          for (final number in contact.smsNumbers) _ContactNumberRow(contact, number),
      ],
      if (local.isNotEmpty) ...[
        const _LabelRow(external: false),
        for (final contact in local)
          for (final number in contact.smsNumbers) _ContactNumberRow(contact, number),
      ],
      if (external.isEmpty && local.isEmpty) const _NoContactsRow(),
    ];
    return WatchScrollList.builder(
      title: l10n.messaging_ConversationBuilders_title_new,
      header: [
        WatchSearchRow(
          initialQuery: state.searchFilter,
          onChanged: cubit.setSearchFilter,
          searchLabel: l10n.messaging_ConversationBuilders_contactOrNumberSearch_hint,
          clearLabel: l10n.contacts_SemanticsLabel_clearSearch,
        ),
        const WatchSeparator(),
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: rows.length,
      itemBuilder: (context, index) => switch (rows[index]) {
        _InvalidNumberRow() => WatchListNote(
          l10n.messaging_ConversationBuilders_numberSearch_errorError +
              l10n.messaging_ConversationBuilders_numberFormatExample,
        ),
        _ParsedNumberRow() => WatchListTile(
          leading: const Icon(Icons.sms_outlined),
          title: state.parsedNumber,
          fitTitle: true,
          subtitle: l10n.messaging_ConversationBuilders_create,
          onTap: cubit.onConfirmByParsedNumber,
        ),
        _LabelRow(:final external) => WatchListLabel(
          external
              ? l10n.messaging_ConversationBuilders_externalContacts_heading
              : l10n.messaging_ConversationBuilders_localContacts_heading,
        ),
        _ContactNumberRow(:final contact, :final number) => _NumberRow(contact, number),
        _NoContactsRow() => WatchListNote(l10n.messaging_ConversationBuilders_noContacts),
      },
    );
  }
}

/// One row of the list, as data: what it shows is built when it is drawn.
sealed class _Row {
  const _Row();
}

class _InvalidNumberRow extends _Row {
  const _InvalidNumberRow();
}

class _ParsedNumberRow extends _Row {
  const _ParsedNumberRow();
}

/// The heading of the Cloud PBX contacts, or of the phone's.
class _LabelRow extends _Row {
  const _LabelRow({required this.external});

  final bool external;
}

class _ContactNumberRow extends _Row {
  const _ContactNumberRow(this.contact, this.number);

  final Contact contact;
  final String number;
}

class _NoContactsRow extends _Row {
  const _NoContactsRow();
}

/// One SMS number of a contact: each number is a row of its own, a watch has
/// no room for the phone's row that unfolds.
class _NumberRow extends StatelessWidget {
  const _NumberRow(this.contact, this.number);

  final Contact contact;
  final String number;

  @override
  Widget build(BuildContext context) {
    final id = contact.sourceType == ContactSourceType.external ? contact.sourceId : null;
    return WatchListTile(
      leading: WatchContactAvatar(contact: contact),
      title: contact.displayTitle,
      subtitle: number,
      onTap: () => context.read<SmsConversationBuilderCubit>().onConfirm(number, id),
    );
  }
}

/// Which of the user's own numbers the conversation is sent from, for an
/// account with more than one: a row per number, a tap picks it.
class _SenderNumberPage extends StatelessWidget {
  const _SenderNumberPage({required this.numbers});

  final List<String> numbers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WatchScrollList(
        title: context.l10n.messaging_ConversationsScreen_selectNumberSheet_title,
        spacing: context.adaptiveMetrics.gap,
        children: [
          for (final number in numbers)
            WatchListTile(title: number, fitTitle: true, onTap: () => Navigator.of(context).pop(number)),
        ],
      ),
    );
  }
}
