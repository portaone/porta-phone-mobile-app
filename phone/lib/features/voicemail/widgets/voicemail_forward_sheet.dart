import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';

/// How long the sheet waits after a keystroke before asking the database again.
///
/// Long enough that typing a name is one query rather than eight, short enough
/// that a person who stops typing does not notice the wait.
const _searchDebounce = Duration(milliseconds: 250);

/// Picks the colleague a voicemail is passed on to.
///
/// Answers with the chosen contact, or null if the sheet was dismissed. It does
/// not forward anything itself: the screen that opened it owns the message and
/// is the one that has to say what came of sending it.
Future<Contact?> showVoicemailForwardSheet(BuildContext context) {
  return context.showModalBottomSheet<Contact>(
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => Provider.value(value: context.read<ContactsRepository>(), child: const _VoicemailForwardSheet()),
  );
}

class _VoicemailForwardSheet extends StatefulWidget {
  const _VoicemailForwardSheet();

  @override
  State<_VoicemailForwardSheet> createState() => _VoicemailForwardSheetState();
}

class _VoicemailForwardSheetState extends State<_VoicemailForwardSheet> {
  String _search = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (mounted) setState(() => _search = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.voicemail_Widget_forwardSheetTitle, style: theme.textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SemanticId(
              identifier: voicemailForwardSearchId,
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.voicemail_Label_forwardSearchHint,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _Colleagues(search: _search)),
        ],
      ),
    );
  }
}

class _Colleagues extends StatelessWidget {
  const _Colleagues({required this.search});

  final String search;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ContactsRepository>();

    return StreamBuilder<List<Contact>>(
      // Searched in the database rather than over a list held here: it reaches
      // the alias and the numbers as well as the name, which is what a person
      // typing half a surname is relying on.
      stream: repository.watchContacts(search, ContactSourceType.external),
      builder: (context, snapshot) {
        final contacts = snapshot.data;
        if (contacts == null) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

        // Everyone a forward can actually reach. A row that cannot be a
        // recipient is left out rather than shown unselectable: the reason it
        // cannot - no server id of its own - means nothing to a person.
        final colleagues = contacts.where((contact) => contact.canReceiveForwardedVoicemail).toList();
        if (colleagues.isEmpty) return const _NoColleagues();

        return ListView.builder(
          itemCount: colleagues.length,
          itemBuilder: (context, index) => _ColleagueTile(contact: colleagues[index]),
        );
      },
    );
  }
}

class _ColleagueTile extends StatelessWidget {
  const _ColleagueTile({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = contact.extension;

    return SemanticAction(
      // One name carrying both, because the row is a single stop for a reader
      // and the extension is what separates two colleagues with one name.
      label: extension == null
          ? context.l10n.voicemail_SemanticsLabel_forwardTo(contact.displayTitle)
          : context.l10n.voicemail_SemanticsLabel_forwardToExtension(contact.displayTitle, extension),
      child: ListTile(
        leading: LeadingAvatar(
          username: contact.displayTitle,
          thumbnail: contact.thumbnail,
          thumbnailUrl: contact.thumbnailUrl,
          radius: 24,
        ),
        title: Text(contact.displayTitle),
        subtitle: extension == null ? null : Text(extension, style: theme.textTheme.bodySmall),
        // One tap sends. There is no confirmation step because there is
        // nothing to lose by it: the original stays where it is, and the worst
        // outcome is a colleague with one message they did not need.
        onTap: () => Navigator.of(context).pop(contact),
      ),
    );
  }
}

class _NoColleagues extends StatelessWidget {
  const _NoColleagues();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(context.l10n.voicemail_Label_forwardNoColleagues, textAlign: TextAlign.center),
          Text(
            context.l10n.voicemail_Label_forwardNoColleaguesHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
