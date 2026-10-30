part of 'embedded_cubit.dart';

enum EmbeddedIntents { reloadWebView }

@freezed
class EmbeddedState with _$EmbeddedState {
  const EmbeddedState({this.payload = const {}, this.currentUrl = '', this.canGoBack = false, this.intent});

  final Map<String, dynamic> payload;

  final String currentUrl;

  final bool canGoBack;

  final EmbeddedIntents? intent;

  bool get isReadyToInjectedScript => payload.isNotEmpty;

  bool get isReloadWebView => intent == EmbeddedIntents.reloadWebView;
}
