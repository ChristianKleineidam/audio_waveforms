import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fake_async/fake_async.dart';
import 'package:audio_waveforms/src/base/platform_streams.dart';
import 'package:audio_waveforms/src/base/player_identifier.dart';
import 'package:record/record.dart'
    show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_audio/just_audio.dart';
import 'desktop_audio_handler_test.mocks.dart';

@GenerateMocks([AudioRecorder, AudioPlayer])
void main() {
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
      when(mockPlayer.playerStateStream)
          .thenAnswer((_) => const Stream.empty());
      when(mockPlayer.position).thenAnswer((_) => Duration.zero);
    });

    tearDown(() {
      if (PlatformStreams.instance.isInitialised) {
        PlatformStreams.instance.dispose();
      }
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

    test('preparePlayer sets file path and clamps volume', () async {
      await handler.preparePlayer(
        path: testPath,
        key: testKey,
        frequency: 1,
        volume: 2.0,
      );

      verify(mockPlayer.setFilePath(testPath)).called(1);
      verify(mockPlayer.setVolume(1.0)).called(1);
    });

    test('release disposes player and prevents further playback', () async {
      await handler.preparePlayer(path: testPath, key: testKey, frequency: 1);
      await handler.release(testKey);

      verify(mockPlayer.dispose()).called(1);
      final canStart = await handler.startPlayer(testKey);

      expect(canStart, isFalse);
    });

    test('startPlayer emits duration updates until paused', () {
      fakeAsync((async) {
        var position = Duration.zero;
        when(mockPlayer.position).thenAnswer((_) => position);
        when(mockPlayer.playerStateStream)
            .thenAnswer((_) => const Stream.empty());

        async.run((_) async {
          await handler.preparePlayer(
            path: testPath,
            key: testKey,
            frequency: 50,
          );
          await handler.startPlayer(testKey);
        });
        async.flushMicrotasks();

        position = const Duration(milliseconds: 80);
        async.elapse(const Duration(milliseconds: 50));

        verify(mockPlayer.position).called(greaterThan(0));

        reset(mockPlayer);
        when(mockPlayer.position).thenAnswer((_) => position);
        async.run((_) async {
          await handler.pausePlayer(testKey);
        });
        async.flushMicrotasks();
        position = const Duration(milliseconds: 120);
        async.elapse(const Duration(milliseconds: 50));

        verifyNever(mockPlayer.position);
      });
    });
  });
}
