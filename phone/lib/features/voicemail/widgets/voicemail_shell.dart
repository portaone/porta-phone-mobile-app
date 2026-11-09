import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/feature_access.dart';
import 'package:webtrit_phone/push_notification/push_notifications.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../services/services.dart';

final _logger = Logger('VoicemailShell');

/// Keeps the session's mailbox in step where voicemail is available: runs
/// [VoicemailPushService], and asks for a read of the box each time
/// [boxChanges] says to - the server saying the box changed, or the session
/// coming (back) up.
class VoicemailShell extends StatefulWidget {
  const VoicemailShell({required this.boxChanges, required this.child, super.key});

  /// When the box should be read again.
  final Stream<void> boxChanges;

  final Widget child;

  @override
  State<VoicemailShell> createState() => _VoicemailShellState();
}

class _VoicemailShellState extends State<VoicemailShell> {
  late final featureAccess = context.read<FeatureAccess>();

  late final VoicemailSync _sync;
  VoicemailPushService? pushService;
  StreamSubscription<void>? _boxChangesSubscription;
  StreamSubscription<VoicemailPush>? _drain;

  @override
  void initState() {
    super.initState();
    // Read once: [MainShell] pins one [FeatureAccess] snapshot for the session.
    if (!featureAccess.voicemailAvailable) {
      // The broker holds a push that opened the app until somebody listens. A
      // session without voicemail takes it and drops it, so a later session
      // with voicemail is not sent to the mailbox by a tap from long before.
      _drain = context.read<RemotePushRepository>().voicemailOpenedPushs.listen((_) {});
      return;
    }

    _sync = context.read<VoicemailSync>();
    pushService = VoicemailPushService(
      context.read<RemotePushRepository>(),
      context.read<LocalPushRepository>(),
      requestRefresh: _requestRefresh,
      openVoicemail: _openVoicemail,
    )..init();
    _listenToBoxChanges();
  }

  @override
  void didUpdateWidget(VoicemailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (pushService != null && !identical(oldWidget.boxChanges, widget.boxChanges)) {
      unawaited(_boxChangesSubscription?.cancel());
      _listenToBoxChanges();
    }
  }

  void _listenToBoxChanges() {
    // Each change asks; folding a burst into one read is the sync task's job.
    _boxChangesSubscription = widget.boxChanges.listen(
      (_) => _requestRefresh(),
      onError: (Object error, StackTrace stackTrace) => _logger.warning('box changes failed', error, stackTrace),
    );
  }

  void _requestRefresh() => _sync.requestRefresh();

  void _openVoicemail() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    context.router.navigate(voicemailRouteOf(featureAccess.bottomMenuConfig));
  }

  @override
  void dispose() {
    // In the reverse of the order they were made.
    _boxChangesSubscription?.cancel();
    pushService?.dispose();
    _drain?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
