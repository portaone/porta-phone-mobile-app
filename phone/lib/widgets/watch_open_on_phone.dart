import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:adaptive_kit/adaptive_kit.dart';
import 'package:phone_link/phone_link.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// Sends [uri] to the paired phone; true once the phone has taken it.
typedef WatchPhoneOpener = Future<bool> Function(Uri uri);

/// A page a watch cannot show - a watch has no web view - sent to the paired
/// phone instead: the page's name, "Opens on your phone", and Open on phone
/// on the edge. Taken by the phone, the face says where to look and goes back
/// after a moment; with no phone to take it, it says so with Try again.
class WatchOpenOnPhonePage extends StatefulWidget {
  const WatchOpenOnPhonePage({super.key, required this.title, required this.uri, this.opener = PhoneLink.open});

  final String title;
  final Uri uri;

  /// What sends the page; the plugin's, a fake in tests.
  final WatchPhoneOpener opener;

  /// How long "Check your phone" stays before the page goes back.
  static const sentFor = Duration(seconds: 3);

  /// How long the phone has to take the page before it counts as not taken.
  static const answerWithin = Duration(seconds: 15);

  @override
  State<WatchOpenOnPhonePage> createState() => _WatchOpenOnPhonePageState();
}

enum _Sending { idle, sending, sent, failed }

class _WatchOpenOnPhonePageState extends State<WatchOpenOnPhonePage> {
  var _state = _Sending.idle;
  Timer? _back;

  @override
  void dispose() {
    _back?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _state = _Sending.sending);
    // An opener that throws or never answers would leave the edge button
    // disabled for good; either counts as the phone not taking the page, so
    // Try again stays within reach.
    final answer = widget.opener(widget.uri);
    bool taken;
    try {
      taken = await answer.timeout(WatchOpenOnPhonePage.answerWithin);
    } on TimeoutException {
      taken = false;
      // A phone that answers late has still opened the page: the face says so
      // then, rather than leave Try again to open it a second time.
      unawaited(
        answer.then((late) {
          if (late && mounted && _state == _Sending.failed) _sent();
        }, onError: (_) {}),
      );
    } catch (_) {
      taken = false;
    }
    if (!mounted) return;
    taken ? _sent() : setState(() => _state = _Sending.failed);
  }

  void _sent() {
    setState(() => _state = _Sending.sent);
    _back = Timer(WatchOpenOnPhonePage.sentFor, _goBack);
  }

  void _goBack() {
    if (!mounted) return;
    // Only this page, and only while it is on top: the navigator may be the
    // main screen's, shared with Settings, a chat or a call opened over the
    // page in the meantime, which a pop would close instead. Under another
    // page it is not left, and offers to send again once back on top.
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _state = _Sending.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: switch (_state) {
        _Sending.idle || _Sending.sending => WatchStatePage(
          title: widget.title,
          icon: const Icon(Icons.phone_android),
          message: l10n.common_Watch_openOnPhone_message,
          hint: l10n.common_Watch_openOnPhone_hint,
          action: WatchAction(
            label: l10n.common_Watch_openOnPhone_action,
            onPressed: _state == _Sending.sending ? null : _send,
            identifier: watchOpenOnPhoneId,
          ),
        ),
        _Sending.sent => WatchStatePage(
          title: widget.title,
          icon: const Icon(Icons.check_circle_outline),
          message: l10n.common_Watch_openOnPhone_sent,
          hint: l10n.common_Watch_openOnPhone_sentHint,
        ),
        _Sending.failed => WatchStatePage(
          title: widget.title,
          icon: const Icon(Icons.phonelink_off),
          message: l10n.common_Watch_openOnPhone_failed,
          hint: l10n.common_Watch_openOnPhone_failedHint,
          action: WatchAction(
            label: l10n.common_Watch_openOnPhone_retry,
            onPressed: _send,
            identifier: watchOpenOnPhoneRetryId,
          ),
        ),
      },
    );
  }
}
