#include "audio_waveforms_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace audio_waveforms {

void AudioWaveformsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "simform_audio_waveforms_plugin/methods",
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
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->Error("UNIMPLEMENTED", "AudioWaveforms desktop support is not yet implemented", method_call.method_name());
}

}  // namespace audio_waveforms
