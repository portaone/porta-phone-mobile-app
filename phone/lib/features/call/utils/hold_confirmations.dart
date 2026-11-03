import 'dart:async';

/// Tells whether the gateway took a hold or an unhold of a call, so that one
/// it dropped is sent again.
///
/// The gateway answers a hold with `holding` and an unhold with `resuming`.
/// The signaling server acknowledges the request before that, whether the
/// gateway took it or not. While the gateway waits for the answer to the
/// re-INVITE of the call's previous hold or unhold, it drops the next one with
/// no answer and no error, and the call stays as it was: measured on the stand,
/// an unhold sent up to 250 ms after a hold was dropped every time, one sent
/// 300 ms after was taken (WT-2093).
///
/// [expect] is called before the request is sent, [confirmed] when the
/// gateway's answer arrives, and [HoldConfirmation.received] says whether it
/// came within [timeout]; a request with no answer is sent again, at most
/// [attempts] times in all.
class HoldConfirmations {
  HoldConfirmations({this.timeout = const Duration(seconds: 1), this.attempts = 3});

  /// How long the gateway's answer is waited for.
  final Duration timeout;

  /// How many times a request is sent in all.
  final int attempts;

  final Map<String, HoldConfirmation> _waiting = {};

  /// Waits for the answer to the hold ([onHold]) or unhold of [callId] about
  /// to be sent; an earlier wait of the call is given up.
  HoldConfirmation expect(String callId, {required bool onHold}) {
    _waiting.remove(callId)?._complete(false);
    return _waiting[callId] = HoldConfirmation._(this, callId, onHold, timeout);
  }

  /// The gateway's answer: `holding` ([onHold]) or `resuming` of [callId].
  /// An answer nothing waits for, or of the other kind, is ignored.
  void confirmed(String callId, {required bool onHold}) {
    final waiting = _waiting[callId];
    if (waiting == null || waiting.onHold != onHold) return;
    _waiting.remove(callId);
    waiting._complete(true);
  }

  /// The call is gone: its wait ends unanswered.
  void callRemoved(String callId) => _waiting.remove(callId)?._complete(false);
}

/// One hold or unhold waiting for the gateway's answer.
class HoldConfirmation {
  HoldConfirmation._(this._owner, this.callId, this.onHold, this._timeout);

  final HoldConfirmations _owner;
  final String callId;
  final bool onHold;
  final Duration _timeout;
  final Completer<bool> _answer = Completer<bool>();
  Timer? _timer;

  /// Whether the answer came, or comes within the timeout counted from now.
  Future<bool> get received {
    if (!_answer.isCompleted) {
      _timer ??= Timer(_timeout, () {
        if (identical(_owner._waiting[callId], this)) _owner._waiting.remove(callId);
        _complete(false);
      });
    }
    return _answer.future;
  }

  /// Nothing was sent: the wait ends unanswered.
  void cancel() {
    if (identical(_owner._waiting[callId], this)) _owner._waiting.remove(callId);
    _complete(false);
  }

  void _complete(bool value) {
    _timer?.cancel();
    if (!_answer.isCompleted) _answer.complete(value);
  }
}
