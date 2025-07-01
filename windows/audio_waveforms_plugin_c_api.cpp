#include "include/audio_waveforms/audio_waveforms_plugin_c_api.h"

#include "audio_waveforms_plugin.h"

void AudioWaveformsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  audio_waveforms::AudioWaveformsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
