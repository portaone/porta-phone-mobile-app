import 'activity_control.dart';
import 'callkeep_diagnostics.dart';

/// Provides access to various Android Callkeep **utilities and helpers**.
///
/// This abstract class exposes static instances for one-off configurations
/// and helper methods that interact with the Android system.
abstract class AndroidCallkeepUtils {
  /// Provides access to Android-specific Activity controls.
  ///
  /// This includes methods for managing behavior over the lock screen,
  /// waking the screen, moving the task to the back, and checking the device lock state.
  static final activityControl = ActivityControl();

  /// Provides access to system diagnostics and reporting tools.
  ///
  /// Use this to generate diagnostic reports containing device state,
  /// service status, and recent call failures.
  static final diagnostics = CallkeepDiagnostics();
}
