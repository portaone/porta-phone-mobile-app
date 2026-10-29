part of 'push_tokens_bloc.dart';

// DiagnosticableTreeMixin counts as a custom toString to freezed 4; ask for its own.
@Freezed(toStringOverride: true)
class PushTokensState with DiagnosticableTreeMixin, _$PushTokensState {
  const PushTokensState({this.pushToken, this.errorMessage});

  final String? errorMessage;

  final String? pushToken;

  factory PushTokensState.initial() => const PushTokensState();

  factory PushTokensState.uploadFailure(String? errorMessage) => PushTokensState(errorMessage: errorMessage);
}
