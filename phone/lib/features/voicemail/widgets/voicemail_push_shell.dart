import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/feature_access.dart';
import 'package:webtrit_phone/push_notification/push_notifications.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../services/services.dart';

/// Runs [VoicemailPushService] for the session, where voicemail is available.
class VoicemailPushShell extends StatefulWidget {
  const VoicemailPushShell({required this.child, super.key});

  final Widget child;

  @override
  State<VoicemailPushShell> createState() => _VoicemailPushShellState();
}

class _VoicemailPushShellState extends State<VoicemailPushShell> {
  late final featureAccess = context.read<FeatureAccess>();

  VoicemailPushService? pushService;
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

    pushService = VoicemailPushService(
      context.read<RemotePushRepository>(),
      context.read<LocalPushRepository>(),
      requestRefresh: context.read<VoicemailSync>().requestRefresh,
      openVoicemail: _openVoicemail,
    )..init();
  }

  void _openVoicemail() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    context.router.navigate(voicemailRouteOf(featureAccess.bottomMenuConfig));
  }

  @override
  void dispose() {
    _drain?.cancel();
    pushService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
