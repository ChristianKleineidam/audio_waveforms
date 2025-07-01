#include "audio_waveforms_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <winrt/Windows.Devices.Enumeration.h>

namespace audio_waveforms {
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;
using flutter::MethodChannel;

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
    bool granted = false;
    try {
      using namespace winrt::Windows::Devices::Enumeration;
      auto info = DeviceAccessInformation::CreateFromDeviceClass(DeviceClass::AudioCapture);
      auto status = info.CurrentStatus();
      if (status == DeviceAccessStatus::Allowed) {
        granted = true;
      } else if (status == DeviceAccessStatus::UserPromptRequired) {
        status = info.RequestAccessAsync().get();
        granted = status == DeviceAccessStatus::Allowed;
      } else {
        granted = false;
      }
    } catch (...) {
      granted = false;
    }
    result->Success(EncodableValue(granted));
  } else {
    result->Error("UNIMPLEMENTED", "AudioWaveforms desktop support is not yet implemented", method_call.method_name());
  }
}

}  // namespace audio_waveforms
