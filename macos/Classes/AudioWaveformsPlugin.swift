import Cocoa
import FlutterMacOS
import AVFoundation

public class AudioWaveformsPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: Constants.methodChannelName, binaryMessenger: registrar.messenger)
    let instance = AudioWaveformsPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Constants.checkPermission:
      channel?.invokeMethod(call.method, arguments: nil, result: result)
    default:
      result(FlutterError(code: Constants.audioWaveforms, message: "AudioWaveforms desktop support is not yet implemented", details: call.method))
    }
  }
}
