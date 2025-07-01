#ifndef FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_C_API_H_

#include <flutter/plugin_registrar_windows.h>

#ifdef AUDIO_WAVEFORMS_PLUGIN_IMPL
#define AUDIO_WAVEFORMS_PLUGIN_EXPORT __declspec(dllexport)
#else
#define AUDIO_WAVEFORMS_PLUGIN_EXPORT __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif

AUDIO_WAVEFORMS_PLUGIN_EXPORT void AudioWaveformsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#ifdef __cplusplus
}
#endif

#endif  // FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_C_API_H_
