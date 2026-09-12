/// Which backend carries calls on Android.
///
/// Reported by `getCallDeliveryMode`; it does not select anything. The backend is chosen
/// once per process: the `android.software.telecom` system feature decides it, and where
/// the feature is absent a device that still reports a phone type falls through to
/// [telecom] anyway.
///
/// - [telecom]: calls go through a self-managed `android.telecom.ConnectionService`,
///   so the system tracks call state and arbitrates audio routing and focus against
///   other calls on the device.
/// - [standalone]: the device has no Telecom, so calls are carried by a foreground
///   service of our own. It implements the same call operations - incoming,
///   outgoing, answer, decline, hangup, DTMF, hold, mute - but audio device choice
///   is limited to speaker versus earpiece, with no Bluetooth or wired headset
///   routing. The limitation that bites is delivery rather than capability: nothing
///   outside the app keeps a call alive, so an incoming call on a cold start can be
///   delayed or lost to Doze, background restrictions, or an OEM that refuses the
///   foreground-service start outright. (The service promotes in two phases -
///   `phoneCall` while ringing, `phoneCall|microphone` once answered - which is what
///   makes a push-delivered call survive the Android 14 restriction on raising the
///   `microphone` type from the background, not a cause of the problem.)
/// - [unknown]: the mode could not be determined, or the platform is not Android.
enum CallkeepAndroidCallDeliveryMode { telecom, standalone, unknown }
