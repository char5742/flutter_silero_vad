import Flutter
import UIKit

public class FlutterSileroVadPlugin: NSObject, FlutterPlugin {
  private var vad: VadIterator?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_silero_vad", binaryMessenger: registrar.messenger())
    let instance = FlutterSileroVadPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      if let args = call.arguments as? [String: Any],
        let modelPath = args["modelPath"] as? String,
        let sampleRate = args["sampleRate"] as? Int64,
        let frameSize = args["frameSize"] as? Int64,
        let threshold = args["threshold"] as? Double,
        let minSilenceDurationMs = args["minSilenceDurationMs"] as? Int64,
        let speechPadMs = args["speechPadMs"] as? Int64
      {
        vad = VadIterator(
          modelPath: modelPath, sampleRate: sampleRate, frameSize: frameSize,
          threshold: Float(threshold), minSilenceDurationMs: minSilenceDurationMs,
          speechPadMs: speechPadMs
        )
        result("vad initialized")
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      }

    case "predict":
      if let args = call.arguments as? [String: Any],
        let dataBinary = args["data"] as? FlutterStandardTypedData,
        let vad = vad
      {
        let floatData = dataBinary.data.withUnsafeBytes {
          Array(UnsafeBufferPointer<Float>(start: $0, count: Int(dataBinary.elementCount)))
        }
        let res = try! vad.predict(data: floatData)
        result(res)
      } else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS", message: "Invalid arguments or uninitialized VAD",
            details: nil))
      }

    case "resetState":
      vad?.resetState()
      result("vad reset state")

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
