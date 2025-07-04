#include "audio_waveforms_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <iostream>
#include <winrt/Windows.Security.Authorization.AppCapabilityAccess.h>
#include <winrt/Windows.Devices.Enumeration.h>

namespace audio_waveforms {
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;
using flutter::MethodChannel;

namespace {
bool RequestMicrophonePermission() {
  using namespace winrt::Windows::Security::Authorization::AppCapabilityAccess;
  try {
    const auto status =
        AppCapabilityAccessManager::RequestAccessForCapabilityAsync(L"microphone")
            .get();
    return status == AppCapabilityAccessStatus::Allowed;
  } catch (const winrt::hresult_error&) {
    try {
      using namespace winrt::Windows::Devices::Enumeration;
      const auto info =
          DeviceAccessInformation::CreateFromDeviceClass(DeviceClass::AudioCapture);
#if WINVER >= 0x0A00
      const auto status = info.RequestAccessAsync().get();
#else
      const auto status = info.RequestAccess();
#endif
      return status == DeviceAccessStatus::Allowed;
    } catch (const winrt::hresult_error& e) {
      std::cerr << "Microphone permission request failed: "
                << winrt::to_string(e.message()) << std::endl;
    }
  }
  return false;
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
    result->Error("UNIMPLEMENTED", "AudioWaveforms desktop support is not yet implemented", method_call.method_name());
  }
}

}  // namespace audio_waveforms
