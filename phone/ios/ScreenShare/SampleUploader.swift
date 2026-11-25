// Turns the broadcast's screen frames into the messages flutter_webrtc's
// FlutterSocketConnectionFrameReader reads, and writes them to the SocketConnection: an HTTP-framed
// message with the headers Content-Length, Buffer-Width, Buffer-Height and Buffer-Orientation and a
// JPEG of the frame as its body. Used by SampleHandler for every video sample.
//
// The extension may use about 50 MB, and ReplayKit hands it up to 60 frames a second at the
// screen's full resolution, so a frame is dropped while the one before is still being written or
// when it comes sooner than the frame rate allows, and every frame is scaled down by half.
import CoreImage
import CoreMedia
import Foundation
import ReplayKit

final class SampleUploader {
  private static let scale: CGFloat = 0.5
  private static let minFrameInterval: CFTimeInterval = 1.0 / 15.0
  private static let jpegQuality: Float = 0.8

  private let connection: SocketConnection
  private let queue = DispatchQueue(label: "screen-share.upload", qos: .userInitiated)
  private let context = CIContext(options: [.cacheIntermediates: false])
  private let lock = NSLock()
  private var busy = false

  /// Frames written whole to the socket so far.
  private(set) var framesSent = 0
  private var lastFrameTime: CFTimeInterval = 0
  private var message: Data?
  private var offset = 0

  init(connection: SocketConnection) {
    self.connection = connection
    connection.onSpaceAvailable = { [weak self] in
      self?.queue.async { self?.writeMessage() }
    }
  }

  /// Sends [sample] unless the frame before is still on its way or came too recently.
  func send(_ sample: CMSampleBuffer) {
    let now = CACurrentMediaTime()
    lock.lock()
    let take = !busy && now - lastFrameTime >= Self.minFrameInterval
    if take {
      busy = true
      lastFrameTime = now
    }
    lock.unlock()
    guard take else { return }

    guard let data = frameMessage(sample) else {
      finishMessage()
      return
    }
    queue.async {
      self.message = data
      self.offset = 0
      self.writeMessage()
    }
  }

  /// Writes as much of the message as the socket takes now; the rest goes on its next room.
  private func writeMessage() {
    guard let message, connection.hasSpaceAvailable else { return }
    let written = message.withUnsafeBytes { raw -> Int in
      guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return -1 }
      return connection.write(base + offset, count: message.count - offset)
    }
    if written < 0 {
      screenShareLog.error("a frame could not be written to the socket")
      self.message = nil
      finishMessage()
      return
    }
    offset += written
    if offset >= message.count {
      framesSent += 1
      if framesSent == 1 { screenShareLog.info("first frame sent to the app") }
      self.message = nil
      finishMessage()
    }
  }

  private func finishMessage() {
    lock.lock()
    busy = false
    lock.unlock()
  }

  private func frameMessage(_ sample: CMSampleBuffer) -> Data? {
    guard let pixels = CMSampleBufferGetImageBuffer(sample) else { return nil }
    let width = Int(CGFloat(CVPixelBufferGetWidth(pixels)) * Self.scale)
    let height = Int(CGFloat(CVPixelBufferGetHeight(pixels)) * Self.scale)
    let orientation =
      (CMGetAttachment(sample, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber)?
      .uint32Value ?? CGImagePropertyOrientation.up.rawValue

    let image = CIImage(cvPixelBuffer: pixels).transformed(by: CGAffineTransform(scaleX: Self.scale, y: Self.scale))
    let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    let options = [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): Self.jpegQuality]
    guard let jpeg = context.jpegRepresentation(of: image, colorSpace: colorSpace, options: options) else { return nil }

    let framed = CFHTTPMessageCreateResponse(nil, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(framed, "Content-Length" as CFString, String(jpeg.count) as CFString)
    CFHTTPMessageSetHeaderFieldValue(framed, "Buffer-Width" as CFString, String(width) as CFString)
    CFHTTPMessageSetHeaderFieldValue(framed, "Buffer-Height" as CFString, String(height) as CFString)
    CFHTTPMessageSetHeaderFieldValue(framed, "Buffer-Orientation" as CFString, String(orientation) as CFString)
    CFHTTPMessageSetBody(framed, jpeg as CFData)
    return CFHTTPMessageCopySerializedMessage(framed)?.takeRetainedValue() as Data?
  }
}
