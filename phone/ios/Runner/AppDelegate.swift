import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter
        .current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ApsEnvironment") {
      let channel = FlutterMethodChannel(name: ApsEnvironment.channel, binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        if call.method == "get" {
          result(ApsEnvironment.current())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}

/// The APNs environment this build was signed for, the one its push tokens belong to: the
/// `aps-environment` entitlement of the provisioning profile embedded in the build - `development`
/// for a development-signed build, `production` for an ad-hoc one. A build from the App Store
/// carries no embedded profile and is always production. Nil on the simulator or when the profile
/// cannot be read: the app then falls back to its own guess.
enum ApsEnvironment {
  static let channel = "com.webtrit.phone/aps_environment"

  static func current() -> String? {
    #if targetEnvironment(simulator)
    return nil
    #else
    guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") else {
      return "production"
    }
    // The profile is a signed CMS message with the property list inside it in plain text.
    guard let data = try? Data(contentsOf: url),
          let text = String(data: data, encoding: .isoLatin1),
          let start = text.range(of: "<?xml"),
          let end = text.range(of: "</plist>"),
          let plist = try? PropertyListSerialization.propertyList(
            from: Data(text[start.lowerBound..<end.upperBound].utf8), format: nil) as? [String: Any],
          let entitlements = plist["Entitlements"] as? [String: Any]
    else {
      return nil
    }
    return entitlements["aps-environment"] as? String
    #endif
  }
}
