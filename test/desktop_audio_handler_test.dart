import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/src/base/utils.dart' show FinishMode;
import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:record/record.dart'
    show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_audio/just_audio.dart';
import 'desktop_audio_handler_test.mocks.dart';

@GenerateMocks([AudioRecorder, AudioPlayer])
void main() {
  group('initRecorder', () {
    test('returns false when permission denied', () async {
      final mockRecorder = MockAudioRecorder();
      when(mockRecorder.hasPermission()).thenAnswer((_) async => false);

      final handler = DesktopAudioHandler(
        recorder: mockRecorder,
        playerFactory: () => MockAudioPlayer(),
      );

      final result = await handler.initRecorder(
        settings: const RecorderSettings(),
      );

      expect(result, isFalse);
    });

    test('creates directory when path provided', () async {
      final mockRecorder = MockAudioRecorder();
      when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
      final tempDir = await Directory.systemTemp.createTemp();
      final path = '${tempDir.path}/nested/file.m4a';

      final handler = DesktopAudioHandler(
        recorder: mockRecorder,
        playerFactory: () => MockAudioPlayer(),
      );

      final result = await handler.initRecorder(
        path: path,
        settings: const RecorderSettings(),
      );

      expect(result, isTrue);
      expect(File(path).parent.existsSync(), isTrue);

      await tempDir.delete(recursive: true);
    });
  });
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

    test('setRate adjusts playback speed', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      when(mockPlayer.setSpeed(any)).thenAnswer((_) async {});

      final success = await handler.setRate(1.5, testKey);

      expect(success, isTrue);
      verify(mockPlayer.setSpeed(1.5)).called(1);
    });

    test('getDuration returns current and max duration', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      when(mockPlayer.position).thenReturn(const Duration(milliseconds: 300));
      when(mockPlayer.load()).thenAnswer((_) async {});
      when(mockPlayer.duration).thenReturn(const Duration(milliseconds: 1000));

      final current = await handler.getDuration(testKey, 0);
      final max = await handler.getDuration(testKey, 1);

      expect(current, 300);
      expect(max, 1000);
    });

    test('setReleaseMode loop uses LoopMode.one', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);

      when(mockPlayer.setLoopMode(any)).thenAnswer((_) async {});

      await handler.setReleaseMode(testKey, FinishMode.loop);

      verify(mockPlayer.setLoopMode(LoopMode.one)).called(1);
    });

    test('setReleaseMode pause pauses on completion', () async {
      final controller = StreamController<PlayerState>();
      when(mockPlayer.playerStateStream).thenAnswer((_) => controller.stream);
      when(mockPlayer.setLoopMode(any)).thenAnswer((_) async {});

      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);
      await handler.setReleaseMode(testKey, FinishMode.pause);

      controller.add(PlayerState(false, ProcessingState.completed));
      await Future<void>.delayed(Duration.zero);

      verify(mockPlayer.pause()).called(1);
      verify(mockPlayer.seek(Duration.zero)).called(1);
    });

    test('setReleaseMode stop stops on completion', () async {
      final controller = StreamController<PlayerState>();
      when(mockPlayer.playerStateStream).thenAnswer((_) => controller.stream);
      when(mockPlayer.setLoopMode(any)).thenAnswer((_) async {});

      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);
      await handler.setReleaseMode(testKey, FinishMode.stop);

      controller.add(PlayerState(false, ProcessingState.completed));
      await Future<void>.delayed(Duration.zero);

      verify(mockPlayer.stop()).called(1);
    });
  });
}
