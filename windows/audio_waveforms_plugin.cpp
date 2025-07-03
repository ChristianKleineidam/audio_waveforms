#include "audio_waveforms_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#if __has_include(<winrt/Windows.Security.Authorization.AppCapabilityAccess.h>)
#  include <winrt/Windows.Security.Authorization.AppCapabilityAccess.h>
#  define USE_APP_CAPABILITY 1
#elif __has_include(<winrt/Windows.Devices.Enumeration.h>)
#  include <winrt/Windows.Devices.Enumeration.h>
#  define USE_DEVICE_ACCESS 1
#endif

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
#if defined(USE_APP_CAPABILITY)
      using namespace winrt::Windows::Security::Authorization::AppCapabilityAccess;
      auto status =
          AppCapabilityAccessManager::RequestAccessForCapabilityAsync(L"microphone").get();
      granted = status == AppCapabilityAccessStatus::Allowed;
#elif defined(USE_DEVICE_ACCESS)
      using namespace winrt::Windows::Devices::Enumeration;
      auto info =
          DeviceAccessInformation::CreateFromDeviceClass(DeviceClass::AudioCapture);
      auto status = info.RequestAccessAsync().get();
      granted = status == DeviceAccessStatus::Allowed;
#else
      granted = true;  // Assume permission when APIs are unavailable.
#endif
    } catch (const winrt::hresult_error& error) {
      granted = false;
      std::wstring message = error.message();
      result->Error("MIC_PERMISSION_ERROR", winrt::to_string(message));
      return;
    } catch (...) {
      granted = false;
    }
    result->Success(EncodableValue(granted));
  } else {
    result->Error("UNIMPLEMENTED", "AudioWaveforms desktop support is not yet implemented", method_call.method_name());
  }
}

}  // namespace audio_waveforms
