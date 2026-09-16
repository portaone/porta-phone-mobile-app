import 'package:flutter/material.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

/// Nothing to show, and why.
///
/// Which is not the same sentence under every filter. An empty mailbox is a
/// fact; an empty Saved list is a feature nobody has used yet and says how to;
/// an empty trash is the state worth being in and says what the trash costs
/// while it is not.
class EmptyMailboxView extends StatelessWidget {
  const EmptyMailboxView({super.key, this.filter = VoicemailFilter.all});

  final VoicemailFilter filter;

  String _title(BuildContext context) => switch (filter) {
    VoicemailFilter.all || VoicemailFilter.unheard => context.l10n.voicemail_Label_empty,
    VoicemailFilter.saved => context.l10n.voicemail_Label_emptySaved,
    VoicemailFilter.trash => context.l10n.voicemail_Label_emptyTrash,
  };

  String? _hint(BuildContext context) => switch (filter) {
    VoicemailFilter.all || VoicemailFilter.unheard => null,
    VoicemailFilter.saved => context.l10n.voicemail_Label_emptySavedHint,
    VoicemailFilter.trash => context.l10n.voicemail_Label_emptyTrashHint,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _hint(context);

    // A scrollable, so the pull to refresh keeps working while the list is
    // empty - and one that accepts a drag it has no room to scroll, or the
    // gesture never reaches the indicator above it.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            spacing: 8,
            children: [
              Text(_title(context), textAlign: TextAlign.center),
              if (hint != null)
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
