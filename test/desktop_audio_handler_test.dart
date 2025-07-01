import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
import 'package:audio_waveforms/src/base/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:record/record.dart' show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_audio/just_audio.dart';
import 'desktop_audio_handler_test.mocks.dart';

@GenerateMocks([AudioRecorder, AudioPlayer])
void main() {
  test('record starts recording when permission granted', () async {
    final mockRecorder = MockAudioRecorder();
    when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(mockRecorder.start(any, path: anyNamed('path'))).thenAnswer((_) async {});

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

  group('recorder controls', () {
    late MockAudioRecorder mockRecorder;
    late MockAudioPlayer mockPlayer;
    late DesktopAudioHandler handler;

    setUp(() {
      mockRecorder = MockAudioRecorder();
      mockPlayer = MockAudioPlayer();
      handler = DesktopAudioHandler(
        recorder: mockRecorder,
        playerFactory: () => mockPlayer,
      );

      when(mockRecorder.stop()).thenAnswer((_) async => '/tmp/record.m4a');
      when(mockRecorder.pause()).thenAnswer((_) async {});
      when(mockRecorder.resume()).thenAnswer((_) async {});

      when(mockPlayer.setFilePath(any)).thenAnswer((_) async => null);
      when(mockPlayer.dispose()).thenAnswer((_) async {});
      when(mockPlayer.duration).thenReturn(const Duration(milliseconds: 1200));
    });

    test('pause calls pause on AudioRecorder', () async {
      final result = await handler.pause();

      expect(result, isTrue);
      verify(mockRecorder.pause()).called(1);
    });

    test('resume calls resume on AudioRecorder', () async {
      final result = await handler.resume();

      expect(result, isTrue);
      verify(mockRecorder.resume()).called(1);
    });

    test('stop returns path and duration', () async {
      final result = await handler.stop();

      expect(result[Constants.resultFilePath], '/tmp/record.m4a');
      expect(result[Constants.resultDuration], 1200);
      verify(mockRecorder.stop()).called(1);
      verify(mockPlayer.setFilePath('/tmp/record.m4a')).called(1);
      verify(mockPlayer.dispose()).called(1);
    });
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
}
