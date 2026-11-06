import 'package:adaptive_kit/adaptive_kit.dart';
import 'package:device_profile/device_profile.dart' show PlatformDeviceProfile;

/// Asks the platform for the shape of the screen. Never throws: without an
/// answer the kit infers the shape from the window. The plugin keeps its one
/// read, so this and the device name at startup share a single platform call.
Future<ScreenShape> queryScreenShape() async {
  final profile = await const PlatformDeviceProfile().read();
  return ScreenShape(isRound: profile?.screenShape.isRound);
}
