import Cocoa
import FlutterMacOS
import AVFoundation

public class AudioWaveformsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger)
    let instance = AudioWaveformsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Constants.checkPermission:
      checkPermission(result: result)
    default:
      let details = "Method \(call.method) is not implemented for desktop. Try using RecorderController or PlayerController from the audio_waveforms package instead."
      result(FlutterError(code: Constants.audioWaveforms, message: details, details: call.method))
    }
  }

  private func checkPermission(result: @escaping FlutterResult) {
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .authorized:
      result(true)
    case .denied, .restricted:
      result(false)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .audio) { granted in
        result(granted)
      }
    @unknown default:
      result(false)
    }
  }
}
