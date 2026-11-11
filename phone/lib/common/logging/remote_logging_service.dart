import 'package:logging/logging.dart';

/// Sends the app's log records off the device.
abstract class RemoteLoggingService {
  /// The lowest level sent now; [Level.OFF] while nothing is sent.
  Level get minLevel;

  /// Starts taking records from the root logger, or, when called again,
  /// replaces the [labels] sent with every record.
  void initialize(Map<String, String> labels);

  Future<void> dispose();
}
