// The broadcast upload extension of a screen share in a call. iOS runs it in a process of its own
// once the person starts the broadcast from the system picker, which the app shows through
// flutter_webrtc's getDisplayMedia with the deviceId 'broadcast'; the whole screen goes out, as
// on Android.
//
// Steps: connect to the socket the app listens on in the shared app group container
// (SocketConnection), say "started" to the app (a Darwin notification, ScreenShareBroadcast; the
// app relays it to Dart through ScreenBroadcastChannel), send every screen frame as a JPEG
// (SampleUploader), and when the app closes the socket - the person stopped the share in the app,
// or the call ended - finish the broadcast, which takes the recording indicator away. "stopped"
// goes to the app whichever side ended it.
import ReplayKit
import os

/// What the extension did, in the device log under subsystem "ScreenShare": its own steps leave no
/// other trace, and a share that shows nothing is told apart by them (connected? frames sent?).
let screenShareLog = Logger(subsystem: "ScreenShare", category: "broadcast")

final class SampleHandler: RPBroadcastSampleHandler {
  /// The app opens its socket before it shows the picker; the retries cover a picker that starts
  /// the extension faster than the socket is bound.
  private static let connectAttempts = 10
  private static let connectRetryDelay: TimeInterval = 0.3

  private var connection: SocketConnection?
  private var uploader: SampleUploader?

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    guard let path = ScreenShareBroadcast.socketPath else {
      screenShareLog.error("started without an app group socket path")
      finish("Screen sharing is not available in this app.")
      return
    }
    connect(path: path, attempt: 1)
  }

  private func connect(path: String, attempt: Int) {
    let connection = SocketConnection(path: path)
    guard connection.open() else {
      screenShareLog.info("socket not open yet, attempt \(attempt, privacy: .public)")
      if attempt >= Self.connectAttempts {
        screenShareLog.error("no socket from the app after \(attempt, privacy: .public) attempts")
        finish("Start screen sharing from a call in the app.")
      } else {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Self.connectRetryDelay) {
          self.connect(path: path, attempt: attempt + 1)
        }
      }
      return
    }
    screenShareLog.info("connected to the app's socket, attempt \(attempt, privacy: .public)")
    connection.onClose = { [weak self] in
      screenShareLog.info("the app closed the socket")
      self?.finish("Screen sharing stopped.")
    }
    uploader = SampleUploader(connection: connection)
    self.connection = connection
    ScreenShareBroadcast.post(.started)
  }

  override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
    guard sampleBufferType == .video else { return }
    uploader?.send(sampleBuffer)
  }

  override func broadcastFinished() {
    screenShareLog.info("broadcast finished, \(self.uploader?.framesSent ?? 0, privacy: .public) frames sent")
    connection?.close()
    connection = nil
    uploader = nil
    ScreenShareBroadcast.post(.stopped)
  }

  /// Ends the broadcast; iOS shows [reason] to the person and then calls broadcastFinished.
  private func finish(_ reason: String) {
    let error = NSError(domain: "ScreenShare", code: 0, userInfo: [NSLocalizedDescriptionKey: reason])
    finishBroadcastWithError(error)
  }
}
