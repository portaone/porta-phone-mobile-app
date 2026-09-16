import 'package:flutter/foundation.dart';

/// What a feature has to say once the choice it asked for is over.
///
/// Said above the sections rather than on the screen that asked, because by
/// the time there is anything to say the person is wherever the lists left
/// them. The sentence arrives already localized: what a forward that was too
/// large means is the feature's business, and the shell only shows it.
@immutable
class DestinationPickReport {
  const DestinationPickReport({required this.message, this.isFailure = false, this.retryLabel, this.onRetry});

  final String message;

  /// Drawn as a failure rather than a confirmation.
  final bool isFailure;

  /// Offered only where trying again could end differently, and named by the
  /// feature: what a retry means is not the same sentence for everyone.
  final String? retryLabel;

  final VoidCallback? onRetry;

  bool get isRetryable => retryLabel != null && onRetry != null;
}
