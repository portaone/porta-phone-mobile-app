/// What the app does with an embedded page when a request the page posted to it ends without
/// success - a signup on the login channel that ends without a session, for one.
///
/// The page put itself into a waiting state when it posted and cannot learn the outcome by
/// itself, so the app has to bring it back. Unset, or a value this build does not know, is
/// [historyBack].
enum ResultStrategyConfig {
  /// Back in the page's own history, or a reload when it has none.
  historyBack,

  /// Calls `window.onWebTritResult(result)` on the page and leaves the rest to it; a page
  /// without that function gets [historyBack].
  notify,

  /// Loads the page again from its configured address, with a fresh history.
  restart,

  /// Reloads the current page. A single-page app that submits again when a step is shown would
  /// post the same request again.
  reload,

  /// Leaves the page as it is.
  none,
}
