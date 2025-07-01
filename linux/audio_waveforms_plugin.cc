#include "include/audio_waveforms/audio_waveforms_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

struct _AudioWaveformsPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AudioWaveformsPlugin, audio_waveforms_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void audio_waveforms_plugin_handle_method_call(
    AudioWaveformsPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  response = FL_METHOD_RESPONSE(fl_method_error_response_new(
      "UNIMPLEMENTED",
      "AudioWaveforms desktop support is not yet implemented",
      fl_value_new_string(fl_method_call_get_name(method_call))));
  fl_method_call_respond(method_call, response, nullptr);
}

static void audio_waveforms_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(audio_waveforms_plugin_parent_class)->dispose(object);
}

static void audio_waveforms_plugin_class_init(AudioWaveformsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = audio_waveforms_plugin_dispose;
}

static void audio_waveforms_plugin_init(AudioWaveformsPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  AudioWaveformsPlugin* plugin = AUDIO_WAVEFORMS_PLUGIN(user_data);
  audio_waveforms_plugin_handle_method_call(plugin, method_call);
}

void audio_waveforms_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  AudioWaveformsPlugin* plugin = AUDIO_WAVEFORMS_PLUGIN(
      g_object_new(audio_waveforms_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "simform_audio_waveforms_plugin/methods",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);
  g_object_unref(plugin);
}
