#include "audio_waveforms_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <iostream>
#include <winrt/Windows.Devices.Enumeration.h>

namespace audio_waveforms {
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;
using flutter::MethodChannel;

namespace {
bool RequestMicrophonePermission() {
  using namespace winrt::Windows::Devices::Enumeration;
  try {
    // Is any Audio-Capture device currently allowed?
    auto info =
        DeviceAccessInformation::CreateFromDeviceClass(DeviceClass::AudioCapture);
    auto status = info.CurrentStatus();  // <- synchronous property
    return status == DeviceAccessStatus::Allowed;
  } catch (const winrt::hresult_error& e) {
    std::cerr << "Microphone permission check failed: "
              << winrt::to_string(e.message()) << std::endl;
    return false;
  }
}
}  // namespace

void AudioWaveformsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<MethodChannel<EncodableValue>>(registrar->messenger(),
      "simform_audio_waveforms_plugin/methods",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AudioWaveformsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AudioWaveformsPlugin::AudioWaveformsPlugin() {}

AudioWaveformsPlugin::~AudioWaveformsPlugin() {}

void AudioWaveformsPlugin::HandleMethodCall(
    const MethodCall<EncodableValue> &method_call,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  if (method_call.method_name() == "checkPermission") {
    const bool granted = RequestMicrophonePermission();
    result->Success(EncodableValue(granted));
  } else {
    std::string message =
        "Method '" + std::string(method_call.method_name()) +
        "' is not implemented for desktop. "
        "Try using RecorderController or PlayerController from the "
        "audio_waveforms package instead.";
    result->Error("UNIMPLEMENTED", message, method_call.method_name());
  }
}

}  // namespace audio_waveforms
