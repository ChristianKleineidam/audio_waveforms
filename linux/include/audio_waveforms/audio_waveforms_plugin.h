#ifndef FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(AudioWaveformsPlugin, audio_waveforms_plugin, AUDIO_WAVEFORMS, PLUGIN, GObject)

FLUTTER_PLUGIN_EXPORT void audio_waveforms_plugin_register_with_registrar(FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_AUDIO_WAVEFORMS_PLUGIN_H_
