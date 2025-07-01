import Cocoa
import FlutterMacOS

public class AudioWaveformsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "simform_audio_waveforms_plugin/methods", binaryMessenger: registrar.messenger)
    let instance = AudioWaveformsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterError(code: "UNIMPLEMENTED", message: "AudioWaveforms desktop support is not yet implemented", details: call.method))
  }
}
