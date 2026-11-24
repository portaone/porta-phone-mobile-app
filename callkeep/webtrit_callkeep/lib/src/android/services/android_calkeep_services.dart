import 'package:webtrit_callkeep/src/android/services/background_push_notification_bootstrap_service.dart';
import 'package:webtrit_callkeep/src/android/services/background_push_notification_service.dart';

/// Provides access to various Android Callkeep-related services.
///
/// This abstract class exposes static instances for interacting with and
/// configuring background services used in push notifications.
abstract class AndroidCallkeepServices {
  /// Provides configuration for the background push notification service.
  static final backgroundPushNotificationBootstrapService = BackgroundPushNotificationBootstrapService();

  /// Provides an interface for communication with the background push notification service.
  static final backgroundPushNotificationService = BackgroundPushNotificationService();
}
