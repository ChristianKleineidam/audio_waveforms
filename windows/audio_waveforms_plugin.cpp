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
  auto desktop = std::make_unique<MethodChannel<EncodableValue>>(registrar->messenger(),
      "simform_audio_waveforms_plugin/desktop",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AudioWaveformsPlugin>(std::move(desktop));

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AudioWaveformsPlugin::AudioWaveformsPlugin(std::unique_ptr<MethodChannel<EncodableValue>> desktop)
    : desktop_channel_(std::move(desktop)) {}

AudioWaveformsPlugin::~AudioWaveformsPlugin() {}

void AudioWaveformsPlugin::HandleMethodCall(
    const MethodCall<EncodableValue> &method_call,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  if (method_call.method_name() == "checkPermission") {
    auto shared_result = std::shared_ptr<MethodResult<EncodableValue>>(result.release());
    auto result_handler = std::make_unique<MethodResultFunctions<EncodableValue>>(
        [shared_result](const EncodableValue* value) {
          if (value)
            shared_result->Success(*value);
          else
            shared_result->Success(EncodableValue());
        },
        [shared_result](const std::string& code, const std::string& message,
                       const EncodableValue* details) {
          shared_result->Error(code, message,
                               details ? *details : EncodableValue());
        },
        [shared_result]() { shared_result->NotImplemented(); });
    desktop_channel_->InvokeMethod(method_call.method_name(), nullptr,
                                   std::move(result_handler));
  } else {
    result->Error("UNIMPLEMENTED", "AudioWaveforms desktop support is not yet implemented", method_call.method_name());
  }
}

}  // namespace audio_waveforms
