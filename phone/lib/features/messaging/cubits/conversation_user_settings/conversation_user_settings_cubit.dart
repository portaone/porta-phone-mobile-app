import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:bloc/bloc.dart';
import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

final _logger = Logger('ConversationUserSettingsCubit');

/// What the user holds about every conversation, and what of it is in force
/// right now - for everyone who has to know without having the conversation
/// open: the list rows, the unread totals, the info screens.
///
/// Today that is the notification mute, and "right now" is the whole
/// difficulty. A timed mute expires silently - the
/// core sends no event at the moment it lapses, it just stops reporting the
/// conversation as muted on the next read - so what is stored cannot be
/// shown as it is. This cubit derives the answer from the stored mutes and
/// the current time, and re-derives it when either changes: on every write
/// to the settings tables, on one timer set to the nearest expiry, and on the
/// app coming back to the foreground, since a timer does not fire while the
/// app is suspended and the expiry may have passed in the meantime.
///
/// One timer for all conversations rather than one per row: the list has
/// many rows and few timed mutes, and every reader then sees the change on
/// the same frame. Reconnect needs nothing here - the sync worker re-reads
/// every conversation on reconnect and the stored mutes change under this
/// cubit's subscription.
///
/// The timer does no work of its own - no request, no write - which is what
/// keeps it out of the polling rules in docs/polling_workers.md: those govern
/// refresh cycles, and this is a clock.
class ConversationUserSettingsCubit extends Cubit<ConversationUserSettingsState> with WidgetsBindingObserver {
  ConversationUserSettingsCubit({required this.chatsRepository, required this.smsRepository})
    : super(const ConversationUserSettingsState());

  final ChatsRepository chatsRepository;
  final SmsRepository smsRepository;

  StreamSubscription? _chatSettingsSub;
  StreamSubscription? _smsSettingsSub;
  Timer? _expiry;

  Map<int, ConversationUserSettings> _chatSettings = const {};
  Map<int, ConversationUserSettings> _smsConversationSettings = const {};

  void init() {
    _logger.fine('Initializing');
    WidgetsBinding.instance.addObserver(this);
    _chatSettingsSub = chatsRepository.watchChatUserSettings().listen((settings) {
      _chatSettings = settings;
      _reevaluate();
    });
    _smsSettingsSub = smsRepository.watchConversationUserSettings().listen((settings) {
      _smsConversationSettings = settings;
      _reevaluate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A timer sleeps with the app. Whatever lapsed meanwhile is re-read here,
    // before the first frame after the resume draws a stale icon.
    if (state == AppLifecycleState.resumed) _reevaluate();
  }

  void _reevaluate() {
    if (isClosed) return;

    final now = clock.now();
    emit(
      ConversationUserSettingsState(
        chatSettings: _chatSettings,
        smsConversationSettings: _smsConversationSettings,
        mutedChatIds: _mutedAt(_chatSettings, now),
        mutedSmsConversationIds: _mutedAt(_smsConversationSettings, now),
      ),
    );
    _scheduleExpiry(now);
  }

  static Set<int> _mutedAt(Map<int, ConversationUserSettings> settings, DateTime now) {
    return {
      for (final MapEntry(key: id, value: s) in settings.entries)
        if (s.mute.isActiveAt(now)) id,
    };
  }

  /// One timer, to the nearest expiry still ahead; none when every mute is
  /// forever or already over. Re-armed on every evaluation, so a mute that is
  /// shortened or lifted early never leaves a timer aimed at the old moment
  /// - it fires, re-evaluates, and finds nothing changed.
  void _scheduleExpiry(DateTime now) {
    _expiry?.cancel();
    _expiry = null;

    DateTime? nearest;
    for (final settings in _chatSettings.values.followedBy(_smsConversationSettings.values)) {
      final mute = settings.mute;
      final until = mute.mutedUntil;
      if (!mute.muted || until == null || !until.isAfter(now)) continue;
      if (nearest == null || until.isBefore(nearest)) nearest = until;
    }
    if (nearest == null) return;

    // Capped, because a far-off expiry is not a far-off timer on every
    // platform: the web runtime hands the milliseconds to setTimeout, which
    // treats anything past 2^31-1 (about 25 days) as zero - the timer fires at
    // once, the re-evaluation re-arms it, and the loop spins for as long as
    // the shell is up. Firing early is harmless: the re-evaluation finds
    // nothing changed and arms the next leg.
    final delay = nearest.difference(now);
    _logger.fine('Next expiry at $nearest');
    _expiry = Timer(delay < _maxExpiryDelay ? delay : _maxExpiryDelay, _reevaluate);
  }

  static const _maxExpiryDelay = Duration(days: 1);

  @override
  Future<void> close() {
    _logger.fine('Closing');
    _expiry?.cancel();
    _chatSettingsSub?.cancel();
    _smsSettingsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}

class ConversationUserSettingsState extends Equatable {
  const ConversationUserSettingsState({
    this.chatSettings = const {},
    this.smsConversationSettings = const {},
    this.mutedChatIds = const {},
    this.mutedSmsConversationIds = const {},
  });

  /// The stored settings, as the core last reported them; a conversation with
  /// none is absent. What a reader wants is almost always [isChatMuted] -
  /// these are for the one that has to show the mute's expiry itself.
  final Map<int, ConversationUserSettings> chatSettings;
  final Map<int, ConversationUserSettings> smsConversationSettings;

  /// The conversations muted at the moment of the last evaluation.
  final Set<int> mutedChatIds;
  final Set<int> mutedSmsConversationIds;

  bool isChatMuted(int chatId) => mutedChatIds.contains(chatId);

  bool isSmsConversationMuted(int conversationId) => mutedSmsConversationIds.contains(conversationId);

  NotificationMute chatMute(int chatId) => (chatSettings[chatId] ?? ConversationUserSettings.none).mute;

  /// The mute in force on [chatId] right now: the stored one while it is
  /// active, none once it has lapsed - what a control should show.
  NotificationMute activeChatMute(int chatId) => isChatMuted(chatId) ? chatMute(chatId) : NotificationMute.none;

  NotificationMute activeSmsConversationMute(int conversationId) {
    return isSmsConversationMuted(conversationId) ? smsConversationMute(conversationId) : NotificationMute.none;
  }

  NotificationMute smsConversationMute(int conversationId) {
    return (smsConversationSettings[conversationId] ?? ConversationUserSettings.none).mute;
  }

  @override
  List<Object?> get props => [chatSettings, smsConversationSettings, mutedChatIds, mutedSmsConversationIds];

  @override
  bool get stringify => true;
}
