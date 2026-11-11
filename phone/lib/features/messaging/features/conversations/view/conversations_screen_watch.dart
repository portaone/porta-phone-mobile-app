import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

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
    required this.createChatBuilder,
    required this.createSmsBuilder,
    this.style,
  });

  /// The section's title, the lists and the one shown.
  final WatchSection<ConversationsTab> section;

  /// What the lists are narrowed by.
  final String query;

  final ValueChanged<String> onSearch;

  /// Makes the cubit of a new chat, shared with the phone's sheet.
  final ChatConversationBuilderCubit Function(BuildContext context) createChatBuilder;

  /// Makes the cubit of a new SMS, shared with the phone's sheet.
  final SmsConversationBuilderCubit Function(BuildContext context) createSmsBuilder;

  final ConversationsScreenStyle? style;

  /// Opens a conversation builder on a page of its own: a face has no room
  /// for a sheet over the list.
  void _openBuilder(BuildContext context, WidgetBuilder builder) {
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: builder)));
  }

  void _newChat(BuildContext context) => _openBuilder(
    context,
    (context) => BlocProvider(create: createChatBuilder, child: const ChatConversationBuilderWatch()),
  );

  void _newSms(BuildContext context) => _openBuilder(
    context,
    (context) => BlocProvider(create: createSmsBuilder, child: const SmsConversationBuilderWatch()),
  );

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
          ConversationsTab.chat => () => _newChat(context),
          ConversationsTab.sms => () => _newSms(context),
        },
      ),
    );
  }
}
