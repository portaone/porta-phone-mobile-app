// The app's side of the screen share extension (ios/ScreenShare): tells Dart whether the extension
// is in this build, and relays the Darwin notifications the extension posts when a broadcast
// starts and stops - flutter_webrtc itself reports neither. Made by AppDelegate on the Flutter
// engine; read by ScreenBroadcast (lib/features/call/utils/screen_broadcast.dart).
import Flutter
import Foundation

final class ScreenBroadcastChannel: NSObject, FlutterStreamHandler {
  private static let name = "com.webtrit.phone/screen_broadcast"

  private let methods: FlutterMethodChannel
  private let events: FlutterEventChannel
  private var sink: FlutterEventSink?

  init(messenger: FlutterBinaryMessenger) {
    methods = FlutterMethodChannel(name: Self.name, binaryMessenger: messenger)
    events = FlutterEventChannel(name: "\(Self.name)/events", binaryMessenger: messenger)
    super.init()
    methods.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        result(Self.isAvailable)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    events.setStreamHandler(self)
  }

  /// A build without the extension has neither the app group key nor the extension in PlugIns
  /// (tool/scripts/ios_optional_features.sh takes both out), and the system picker would offer
  /// nothing to start.
  private static var isAvailable: Bool {
    guard ScreenShareBroadcast.appGroup != nil, let plugIns = Bundle.main.builtInPlugInsURL else { return false }
    return FileManager.default.fileExists(atPath: plugIns.appendingPathComponent("ScreenShare.appex").path)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    observe(true)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observe(false)
    sink = nil
    return nil
  }

  private func observe(_ on: Bool) {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = Unmanaged.passUnretained(self).toOpaque()
    for event in [ScreenShareBroadcast.Event.started, .stopped] {
      guard let name = ScreenShareBroadcast.notificationName(event) else { continue }
      if on {
        CFNotificationCenterAddObserver(
          center, observer,
          { _, observer, name, _, _ in
            guard let observer, let name else { return }
            let channel = Unmanaged<ScreenBroadcastChannel>.fromOpaque(observer).takeUnretainedValue()
            channel.received(name.rawValue as String)
          },
          name.rawValue, nil, .deliverImmediately)
      } else {
        CFNotificationCenterRemoveObserver(center, observer, name, nil)
      }
    }
  }

  private func received(_ name: String) {
    for event in [ScreenShareBroadcast.Event.started, .stopped]
    where ScreenShareBroadcast.notificationName(event)?.rawValue as String? == name {
      NSLog("ScreenBroadcastChannel: the extension says %@", event.rawValue)
      DispatchQueue.main.async { self.sink?(event.rawValue) }
    }
  }
}
