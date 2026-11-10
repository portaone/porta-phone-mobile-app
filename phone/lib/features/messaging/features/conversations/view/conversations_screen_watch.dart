import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'conversations_screen_style.dart';
import 'conversations_screen_styles.dart';

/// The conversations on a watch: one list on the face at a time, a pill in
/// place of the tabs; the pill moves the screen's tab controller, so both
/// arrangements remember the same list.
class ConversationsScreenWatch extends StatelessWidget {
  const ConversationsScreenWatch({
    super.key,
    required this.section,
    required this.query,
    required this.onSearch,
    required this.onNewChat,
    required this.onNewSms,
    this.style,
  });

  /// The section's title, the lists and the one shown.
  final WatchSection<ConversationsTab> section;

  /// What the lists are narrowed by.
  final String query;

  final ValueChanged<String> onSearch;

  /// Starts a new chat.
  final VoidCallback onNewChat;

  /// Starts a new SMS conversation.
  final VoidCallback onNewSms;

  final ConversationsScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).extension<ConversationsScreenStyles>()?.primary;
    return ThemedScaffold(
      background: effectiveStyle?.background,
      contentThemeOverride: effectiveStyle?.contentThemeOverride ?? ThemeMode.system,
      body: ConversationsWatchBody(
        section: section,
        query: query,
        onSearch: onSearch,
        onNew: switch (section.selected) {
          ConversationsTab.chat => onNewChat,
          ConversationsTab.sms => onNewSms,
        },
      ),
    );
  }
}
