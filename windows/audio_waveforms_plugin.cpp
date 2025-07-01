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
  auto plugin = std::make_unique<AudioWaveformsPlugin>();
  plugin->channel_ = std::make_unique<MethodChannel<EncodableValue>>(
      registrar->messenger(), "simform_audio_waveforms_plugin/methods",
      &flutter::StandardMethodCodec::GetInstance());

  plugin->channel_->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

AudioWaveformsPlugin::AudioWaveformsPlugin() : channel_(nullptr) {}

AudioWaveformsPlugin::~AudioWaveformsPlugin() { channel_.reset(); }

void AudioWaveformsPlugin::HandleMethodCall(
    const MethodCall<EncodableValue> &method_call,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  if (method_call.method_name() == "checkPermission") {
    channel_->InvokeMethod(method_call.method_name(), std::make_unique<EncodableValue>(), std::move(result));
  } else {
    result->Error("UNIMPLEMENTED", "AudioWaveforms desktop support is not yet implemented", method_call.method_name());
  }
}

}  // namespace audio_waveforms
