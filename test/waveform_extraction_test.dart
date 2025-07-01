import 'dart:async';

import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';

import 'desktop_audio_handler_test.mocks.dart';

class FakeProgress {
  FakeProgress(this.progress, this.waveform);
  final double progress;
  final Waveform? waveform;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('waveform extraction', () {
    late StreamController<FakeProgress> controller;
    late DesktopAudioHandler handler;

    setUp(() async {
      controller = StreamController<FakeProgress>();
      handler = DesktopAudioHandler(
        recorder: MockAudioRecorder(),
        playerFactory: () => MockAudioPlayer(),
        waveformExtractor: ({required audioInFile, required waveOutFile, required zoom}) => controller.stream,
      );
      await PlatformStreams.instance.init();
    });

    tearDown(() async {
      PlatformStreams.instance.dispose();
    });

    test('extractWaveformData returns waveform data', () async {
      final waveform = Waveform(
        version: 1,
        flags: 0,
        sampleRate: 44100,
        samplesPerPixel: 100,
        length: 2,
        data: [0, 1, 0, 2],
      );

      final future = handler.extractWaveformData(key: 'k', path: 'p', noOfSamples: 2);

      controller
        ..add(FakeProgress(0.0, null))
        ..add(FakeProgress(1.0, waveform))
        ..close();

      final result = await future;
      expect(result, [1.0, 2.0]);
    });

    test('stopWaveformExtraction cancels extraction', () {
      fakeAsync((async) {
        final waveform = Waveform(
          version: 1,
          flags: 0,
          sampleRate: 44100,
          samplesPerPixel: 100,
          length: 1,
          data: [0, 1],
        );

        final future = handler.extractWaveformData(key: 'k', path: 'p', noOfSamples: 1);
        expect(future, doesNotComplete);

        controller.add(FakeProgress(0.0, null));
        handler.stopWaveformExtraction('k');
        controller
          ..add(FakeProgress(1.0, waveform))
          ..close();

        async.elapse(const Duration(seconds: 1));
      });
    });
  });
}
