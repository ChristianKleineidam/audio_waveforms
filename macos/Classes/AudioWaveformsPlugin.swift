import Cocoa
import FlutterMacOS
import AVFoundation

public class AudioWaveformsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger)
    let desktop = FlutterMethodChannel(name: Constants.desktopChannelName, binaryMessenger: registrar.messenger)
    let instance = AudioWaveformsPlugin(desktopChannel: desktop)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let desktopChannel: FlutterMethodChannel

  init(desktopChannel: FlutterMethodChannel) {
    self.desktopChannel = desktopChannel
    super.init()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Constants.checkPermission:
      desktopChannel.invokeMethod(call.method, arguments: nil, result: result)
    default:
      result(FlutterError(code: Constants.audioWaveforms, message: "AudioWaveforms desktop support is not yet implemented", details: call.method))
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
