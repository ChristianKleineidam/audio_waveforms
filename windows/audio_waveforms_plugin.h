#ifndef FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace audio_waveforms {

class AudioWaveformsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AudioWaveformsPlugin();
  virtual ~AudioWaveformsPlugin();

  // Disallow copy and assign.
  AudioWaveformsPlugin(const AudioWaveformsPlugin&) = delete;
  AudioWaveformsPlugin& operator=(const AudioWaveformsPlugin&) = delete;

  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace audio_waveforms

#endif  // FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_H_
