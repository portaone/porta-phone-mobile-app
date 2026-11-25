// The extension's end of the socket flutter_webrtc listens on while the app captures the screen
// (FlutterSocketConnection in the plugin is the server). Opened by SampleHandler, written by
// SampleUploader; it reports when it has room for more bytes and, once, when the app closed it -
// the app stopped the capture - so that the extension can finish the broadcast.
import Foundation

final class SocketConnection: NSObject, StreamDelegate {
  /// Called on the stream thread when the output can take more bytes.
  var onSpaceAvailable: (() -> Void)?

  /// Called once, on the stream thread, when the app closed the socket or it failed.
  var onClose: (() -> Void)?

  private let path: String
  private var input: InputStream?
  private var output: OutputStream?
  private var thread: Thread?
  private var closed = false

  init(path: String) {
    self.path = path
  }

  /// Connects to the app's socket; false when nobody listens there, as when the broadcast was
  /// started from Control Center rather than from a call.
  func open() -> Bool {
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return false }
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let bytes = Array(path.utf8)
    guard bytes.count < MemoryLayout.size(ofValue: address.sun_path) else {
      Darwin.close(fd)
      return false
    }
    withUnsafeMutableBytes(of: &address.sun_path) { raw in
      raw.copyBytes(from: bytes)
      raw[bytes.count] = 0
    }
    let connected = withUnsafePointer(to: &address) { pointer in
      pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
    guard connected == 0 else {
      Darwin.close(fd)
      return false
    }
    // A write after the app closed its end must fail, not raise SIGPIPE and kill the extension.
    var on: Int32 = 1
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))

    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, fd, &readStream, &writeStream)
    guard let input = readStream?.takeRetainedValue() as InputStream?,
          let output = writeStream?.takeRetainedValue() as OutputStream?
    else {
      Darwin.close(fd)
      return false
    }
    let closeSocket = Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String)
    input.setProperty(kCFBooleanTrue, forKey: closeSocket)
    output.setProperty(kCFBooleanTrue, forKey: closeSocket)
    input.delegate = self
    output.delegate = self
    self.input = input
    self.output = output

    // The streams need a run loop of their own: the broadcast's callbacks come on threads that
    // have none running.
    let thread = Thread {
      input.schedule(in: .current, forMode: .default)
      output.schedule(in: .current, forMode: .default)
      input.open()
      output.open()
      while !Thread.current.isCancelled {
        _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.5))
      }
      input.close()
      output.close()
    }
    thread.qualityOfService = .userInitiated
    thread.start()
    self.thread = thread
    return true
  }

  var hasSpaceAvailable: Bool { output?.hasSpaceAvailable ?? false }

  /// Writes what the output takes now; the number of bytes written, or -1 when it failed.
  func write(_ pointer: UnsafePointer<UInt8>, count: Int) -> Int {
    output?.write(pointer, maxLength: count) ?? -1
  }

  func close() {
    input?.delegate = nil
    output?.delegate = nil
    thread?.cancel()
    thread = nil
  }

  func stream(_ stream: Stream, handle event: Stream.Event) {
    switch event {
    case .hasSpaceAvailable:
      onSpaceAvailable?()
    case .endEncountered, .errorOccurred:
      guard !closed else { return }
      closed = true
      onClose?()
    default:
      break
    }
  }
}
