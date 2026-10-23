import 'dart:async';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/push_notification/push_notifications.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

final _logger = Logger('VoicemailPushService');

/// Handles the push Core sends for a new message in the mailbox.
///
/// While the app is in the foreground the system does not show a remote push,
/// so the push is shown again as a local one, and a read of the mailbox is
/// requested: the unread count and the list follow the store, and the store is
/// otherwise brought up to date only by the next polling cycle. A push that
/// opened the app, or a tap on the local one, takes the person to the mailbox.
class VoicemailPushService {
  VoicemailPushService(
    this.remotePushRepository,
    this.localPushRepository, {
    required this.requestRefresh,
    required this.openVoicemail,
  });

  final RemotePushRepository remotePushRepository;
  final LocalPushRepository localPushRepository;

  /// Asks for the mailbox to be read into the store the count follows.
  final void Function() requestRefresh;

  /// Shows the mailbox.
  final void Function() openVoicemail;

  final List<StreamSubscription> _subs = [];

  void init() {
    _subs.add(remotePushRepository.voicemailForegroundPushs.listen(_onForegroundPush));
    _subs.add(remotePushRepository.voicemailOpenedPushs.listen(_onOpenedPush));
    _subs.add(localPushRepository.voicemailActions.listen(_onLocalPushAction));
  }

  void _onForegroundPush(VoicemailPush push) {
    _logger.info('Foreground push: $push');
    requestRefresh();

    final (title, body) = (push.title, push.body);
    if (title == null || body == null) return;
    unawaited(localPushRepository.displayPush(AppLocalPush.voicemail(push.voicemailId, title, body)));
  }

  void _onOpenedPush(VoicemailPush push) {
    _logger.info('Opened push: $push');
    requestRefresh();
    openVoicemail();
  }

  void _onLocalPushAction(AppLocalPushAction action) {
    if (action.type == LocalPushActionType.tap) openVoicemail();
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }
}
