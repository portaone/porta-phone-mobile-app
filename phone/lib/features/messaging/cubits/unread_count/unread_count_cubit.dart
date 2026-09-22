import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:webtrit_phone/features/messaging/cubits/conversation_user_settings/conversation_user_settings_cubit.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

final _logger = Logger('UnreadCountCubit');

/// How many conversations are unread - per conversation for the row badges,
/// and in total for the tab and the bottom bar.
///
/// The totals leave muted conversations out. The user asked to hear nothing
/// from them, and a badge that grows for them says otherwise; the row's own
/// count still shows what was missed, where the user looks for it. That is
/// decided here, once, so a reader of a total never has to know about the
/// mutes - and follows [ConversationUserSettingsCubit]'s clock, since a mute
/// lapses with no message arriving to recount on.
class UnreadCountCubit extends Cubit<UnreadCountState> {
  UnreadCountCubit({
    required this.chatsRepository,
    required this.smsRepository,
    required this.sessionRepository,
    required this.userSettings,
    this.updateDebounce = const Duration(seconds: 1),
  }) : super(UnreadCountState.initial());

  final ChatsRepository chatsRepository;
  final SmsRepository smsRepository;
  final SessionRepository sessionRepository;
  final ConversationUserSettingsCubit userSettings;
  final Duration updateDebounce;
  StreamSubscription? _chatsUpdatesSub;
  StreamSubscription? _smsUpdatesSub;
  StreamSubscription? _userSettingsSub;

  Map<int, int> _chatCounts = const {};
  Map<int, int> _smsCounts = const {};

  void init() {
    _logger.fine('Initializing');
    _updateUnreadCount();
    _chatsUpdatesSub = chatsRepository.eventBus.debounce(updateDebounce).listen((_) => _updateUnreadCount());
    _smsUpdatesSub = smsRepository.eventBus.debounce(updateDebounce).listen((_) => _updateUnreadCount());
    // The counts are unchanged by a mute; only the totals over them move.
    _userSettingsSub = userSettings.stream.listen((_) => _emit());
  }

  void _updateUnreadCount() async {
    final userId = sessionRepository.getCurrent().userId;
    _chatCounts = await chatsRepository.unreadedCountPerChat(userId);
    _smsCounts = await smsRepository.unreadedCountPerConversation(userId);
    if (isClosed) return;
    _emit();
  }

  void _emit() {
    final settings = userSettings.state;
    final newState = UnreadCountState.fromCountPerChat(
      _chatCounts,
      _smsCounts,
      mutedChatIds: settings.mutedChatIds,
      mutedSmsConversationIds: settings.mutedSmsConversationIds,
    );
    emit(newState);

    _logger.fine('UnreadMessagesState: $newState');
  }

  @override
  Future<void> close() {
    _logger.fine('Closing');
    _chatsUpdatesSub?.cancel();
    _smsUpdatesSub?.cancel();
    _userSettingsSub?.cancel();
    return super.close();
  }
}

class UnreadCountState with EquatableMixin {
  UnreadCountState._(
    this.chatUnreadCounts,
    this.chatsWithUnreadCount,
    this.smsUnreadCounts,
    this.smsConversationsWithUnreadCount,
  );

  factory UnreadCountState.initial() => UnreadCountState._({}, 0, {}, 0);

  /// Totals over the counts, with the muted conversations left out; the
  /// counts themselves are kept whole for the row badges.
  factory UnreadCountState.fromCountPerChat(
    Map<int, int> chatUnreadCounts,
    Map<int, int> smsUnreadCounts, {
    Set<int> mutedChatIds = const {},
    Set<int> mutedSmsConversationIds = const {},
  }) {
    int unreadAndNotMuted(Map<int, int> counts, Set<int> muted) {
      return counts.entries.where((e) => e.value > 0 && !muted.contains(e.key)).length;
    }

    return UnreadCountState._(
      chatUnreadCounts,
      unreadAndNotMuted(chatUnreadCounts, mutedChatIds),
      smsUnreadCounts,
      unreadAndNotMuted(smsUnreadCounts, mutedSmsConversationIds),
    );
  }

  final Map<int, int> chatUnreadCounts;

  /// How many chats are unread and not muted - what a tab or a bar shows.
  final int chatsWithUnreadCount;

  final Map<int, int> smsUnreadCounts;

  /// How many text conversations are unread and not muted.
  final int smsConversationsWithUnreadCount;

  /// The row's own count: unread whether muted or not.
  int unreadCountForChatConversation(int id) => chatUnreadCounts[id] ?? 0;

  int unreadCountForSmsConversation(int id) => smsUnreadCounts[id] ?? 0;

  @override
  List<Object?> get props => [chatUnreadCounts, chatsWithUnreadCount, smsUnreadCounts, smsConversationsWithUnreadCount];

  @override
  bool get stringify => true;
}
