import 'package:equatable/equatable.dart';

import 'embedded_payload_data.dart';

/// Defines the strategy for handling reconnections in an embedded resource context.
enum ReconnectStrategy {
  /// Do nothing; assume page handles its own recovery
  none,

  /// Call JS bridge to notify app about reconnection (e.g., reinject token)
  notifyOnly,

  /// Reload the same URI without forcing full restart of the app
  softReload,

  /// Reloads the full WebView, discarding app state (may break SPA)
  hardReload,
}

/// What the app does with an embedded page when a request the page posted to it ends without
/// success - a signup on the login channel that ends without a session, for one.
///
/// The page put itself into a waiting state when it posted and cannot learn the outcome by itself.
enum ResultStrategy {
  /// Back in the page's own history, or a reload when it has none - what the error dialog's
  /// Back button has always done, so pages that know nothing of this setting keep working.
  historyBack,

  /// Calls `window.onWebTritResult(result)` and leaves the rest to the page; a page
  /// without that function gets [historyBack].
  notify,

  /// Loads the page again from its address, with a fresh history.
  restart,

  /// Reloads the current page.
  reload,

  /// Leaves the page as it is.
  none,
}

class EmbeddedData extends Equatable {
  EmbeddedData({
    required this.id,
    required this.uri,
    required this.reconnectStrategy,
    this.resultStrategy = ResultStrategy.historyBack,
    this.titleL10n,
    List<EmbeddedPayloadData> payload = const [],
    this.enableConsoleLogCapture = false,
  }) : _payload = List.unmodifiable(payload);

  /// The URI representing either a local asset file path or a remote URL.
  final String id;

  /// The unique identifier for the embedded resource, used to link it with other features or components.
  final Uri uri;

  final List<EmbeddedPayloadData> _payload;

  /// The list of payload data to be passed to the embedded resource.
  List<EmbeddedPayloadData> get payload => _payload;

  /// The flag to enable capturing `console.*` logs from inside the WebView.
  final bool enableConsoleLogCapture;

  /// The strategy to apply when the network reconnects.
  final ReconnectStrategy reconnectStrategy;

  /// What to do with the page when a request it posted to the app ends without success.
  final ResultStrategy resultStrategy;

  /// The key to use to look up the localized title.
  final String? titleL10n;

  @override
  List<Object?> get props => [id, uri, _payload, enableConsoleLogCapture, reconnectStrategy, resultStrategy, titleL10n];
}
