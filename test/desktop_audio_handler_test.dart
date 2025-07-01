import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:record/record.dart'
    show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'desktop_audio_handler_test.mocks.dart';

@GenerateMocks([AudioRecorder, AudioPlayer])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('record starts recording when permission granted', () async {
    final mockRecorder = MockAudioRecorder();
    when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(mockRecorder.start(any, path: anyNamed('path')))
        .thenAnswer((_) async {});

    final handler = DesktopAudioHandler(
      recorder: mockRecorder,
      playerFactory: () => MockAudioPlayer(),
    );

    final result = await handler.record(settings: const RecorderSettings());

    expect(result, isTrue);
    verify(mockRecorder.start(
      any,
      path: anyNamed('path'),
    )).called(1);
  });

  group('player controls', () {
    const testKey = 'key';
    const testPath = '/tmp/test.m4a';

    late MockAudioPlayer mockPlayer;
    late DesktopAudioHandler handler;

    setUp(() {
      mockPlayer = MockAudioPlayer();
      handler = DesktopAudioHandler(
        recorder: MockAudioRecorder(),
        playerFactory: () => mockPlayer,
      );
      when(mockPlayer.setFilePath(any)).thenAnswer((_) async => null);
      when(mockPlayer.setVolume(any)).thenAnswer((_) async => null);
      when(mockPlayer.play()).thenAnswer((_) async {});
      when(mockPlayer.pause()).thenAnswer((_) async {});
      when(mockPlayer.stop()).thenAnswer((_) async {});
      when(mockPlayer.seek(any)).thenAnswer((_) async {});
    });

    test('startPlayer calls play on AudioPlayer', () async {
      await handler.preparePlayer(
        path: testPath,
        key: testKey,
        frequency: 1,
      );

      final started = await handler.startPlayer(testKey);

      expect(started, isTrue);
      verify(mockPlayer.play()).called(1);
    });

    test('pausePlayer calls pause on AudioPlayer', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      final paused = await handler.pausePlayer(testKey);

      expect(paused, isTrue);
      verify(mockPlayer.pause()).called(1);
    });

    test('stopPlayer calls stop on AudioPlayer', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      final stopped = await handler.stopPlayer(testKey);

      expect(stopped, isTrue);
      verify(mockPlayer.stop()).called(1);
    });

    test('setVolume clamps value and calls setVolume on AudioPlayer', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      final success = await handler.setVolume(2.0, testKey);

      expect(success, isTrue);
      verify(mockPlayer.setVolume(1.0)).called(1);
    });

    test('seekTo calls seek with given progress', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      final success = await handler.seekTo(testKey, 500);

      expect(success, isTrue);
      verify(mockPlayer.seek(const Duration(milliseconds: 500))).called(1);
    });
  });

  group('waveform extraction', () {
    const key = 'extract';
    late StreamController<WaveformProgress> controller;
    late DesktopAudioHandler handler;

    setUp(() {
      controller = StreamController<WaveformProgress>();
      handler = DesktopAudioHandler(
        recorder: MockAudioRecorder(),
        playerFactory: () => MockAudioPlayer(),
        extractor: (
            {required File audioInFile,
            required File waveOutFile,
            WaveformZoom zoom = const WaveformZoom.pixelsPerSecond(100)}) {
          return controller.stream;
        },
      );
      PlatformStreams.instance.init();
    });

    tearDown(() {
      PlatformStreams.instance.dispose();
    });

    test('extractWaveformData returns computed points', () async {
      final waveform = Waveform(
        version: 0,
        flags: 0,
        sampleRate: 1,
        samplesPerPixel: 1,
        length: 2,
        data: [0, 10, 0, 20],
      );

      final future = handler.extractWaveformData(
        key: key,
        path: 'foo',
        noOfSamples: 10,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.add(_FakeWaveformProgress(1.0, waveform));
      await controller.close();

      final result = await future;
      expect(result, equals([10.0, 20.0]));
    });

    test('stopWaveformExtraction cancels subscription', () async {
      handler.extractWaveformData(key: key, path: 'foo', noOfSamples: 10);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.hasListener, isTrue);

      await handler.stopWaveformExtraction(key);
      expect(controller.hasListener, isFalse);
    });
  });
}

class _FakeWaveformProgress implements WaveformProgress {
  @override
  final double progress;

  @override
  final Waveform? waveform;

  _FakeWaveformProgress(this.progress, this.waveform);
}
