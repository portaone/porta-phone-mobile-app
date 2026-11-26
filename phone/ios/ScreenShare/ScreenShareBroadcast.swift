// What the app and its broadcast upload extension agree on, compiled into both targets: the app
// group they share (the Info.plist key RTCAppGroupIdentifier, which flutter_webrtc reads as well),
// the socket in its container the WebRTC plugin listens on and the extension writes frames to, and
// the Darwin notifications the extension posts when a broadcast starts and stops. Used by
// SampleHandler (the extension) and ScreenBroadcastChannel (the app, which relays the
// notifications to Dart).
import Foundation

enum ScreenShareBroadcast {
  enum Event: String {
    case started
    case stopped
  }

  /// The app group of the screen share; nil in a build without the extension, where the key is
  /// absent or empty.
  static var appGroup: String? {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "RTCAppGroupIdentifier") as? String,
          !group.isEmpty
    else { return nil }
    return group
  }

  /// The unix socket flutter_webrtc's FlutterSocketConnection binds in the group's container.
  static var socketPath: String? {
    guard let group = appGroup,
          let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
    else { return nil }
    return container.appendingPathComponent("rtc_SSFD").path
  }

  /// Darwin notification names are system wide: they carry the app group so that the extensions of
  /// two brand apps on one phone do not signal each other's app.
  static func notificationName(_ event: Event) -> CFNotificationName? {
    guard let group = appGroup else { return nil }
    return CFNotificationName("\(group).screenShare.\(event.rawValue)" as CFString)
  }

  static func post(_ event: Event) {
    guard let name = notificationName(event) else { return }
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), name, nil, nil, true)
  }
}
