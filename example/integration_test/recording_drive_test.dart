import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'dart:io';

import 'package:audio_waveforms_example/main.dart' as app;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/constants.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
import 'package:audio_waveforms_example/chat_bubble.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final directory = await Directory.systemTemp.createTemp('waveforms_test');
    return directory.path;
  }
}

class FakeAudioWaveformsInterface extends AudioWaveformsInterface {
  FakeAudioWaveformsInterface() : super.test();

  double _db = 0.0;
  bool _recording = false;

  @override
  Future<bool> record({
    required RecorderSettings recorderSetting,
    String? path,
    bool useLegacyNormalization = false,
    bool overrideAudioSession = true,
  }) async {
    _recording = true;
    return true;
  }

  @override
  Future<bool> initRecorder({
    String? path,
    required RecorderSettings recorderSettings,
  }) async {
    return true;
  }

  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<double?> getDecibel() async {
    _db += 1.0;
    return _db;
  }

  @override
  Future<Map<String, dynamic>> stop() async {
    _recording = false;
    return {
      Constants.resultDuration: 1000,
      Constants.resultFilePath: 'test.m4a',
    };
  }

  @override
  Future<bool> preparePlayer({
    required String path,
    required String key,
    required int frequency,
    double? volume,
    bool overrideAudioSession = false,
  }) async {
    return true;
  }

  @override
  Future<bool> startPlayer(String key) async => true;

  @override
  Future<bool> pausePlayer(String key) async => true;

  @override
  Future<bool> stopPlayer(String key) async => true;

  @override
  Future<bool> release(String key) async => true;

  @override
  Future<int?> getDuration(String key, int durationType) async => 1000;

  @override
  Future<bool> setVolume(double volume, String key) async => true;

  @override
  Future<bool> setRate(double rate, String key) async => true;

  @override
  Future<bool> seekTo(String key, int progress) async => true;

  @override
  Future<void> setReleaseMode(String key, FinishMode finishMode) async {}

  @override
  Future<List<double>> extractWaveformData({
    required String key,
    required String path,
    required int noOfSamples,
  }) async {
    return List<double>.filled(noOfSamples, 0);
  }

  @override
  Future<void> stopWaveformExtraction(String key) async {}

  @override
  Future<bool> stopAllPlayers() async => true;

  @override
  Future<bool> pauseAllPlayers() async => true;

  @override
  Future<bool> resume() async => true;

  @override
  Future<bool?> pause() async => true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recording flow', (tester) async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    AudioWaveformsInterface.setInstance(FakeAudioWaveformsInterface());

    app.main();
    await tester.pumpAndSettle();

    // Tap start recording button.
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Waveform widget should appear.
    expect(find.byType(AudioWaveforms), findsOneWidget);

    // Tap stop recording button.
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    // Recorded bubble should appear.
    expect(find.byType(WaveBubble), findsWidgets);
  });
}
