import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
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

    test('stopAllPlayers stops all active players', () async {
      await handler.preparePlayer(path: testPath, key: 'k1', frequency: 1);
      await handler.preparePlayer(path: testPath, key: 'k2', frequency: 1);

      final result = await handler.stopAllPlayers();

      expect(result, isTrue);
      verify(mockPlayer.stop()).called(2);
    });

    test('pauseAllPlayers pauses all active players', () async {
      await handler.preparePlayer(path: testPath, key: 'k1', frequency: 1);
      await handler.preparePlayer(path: testPath, key: 'k2', frequency: 1);

      final result = await handler.pauseAllPlayers();

      expect(result, isTrue);
      verify(mockPlayer.pause()).called(2);
    });
  });

  test('initRecorder sets config used in record', () async {
    final mockRecorder = MockAudioRecorder();
    when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(mockRecorder.start(any, path: anyNamed('path'))).thenAnswer((_) async {});

    final handler = DesktopAudioHandler(
      recorder: mockRecorder,
      playerFactory: () => MockAudioPlayer(),
    );

    const settings = RecorderSettings(bitRate: 256000, sampleRate: 48000);
    const initPath = '/tmp/init.m4a';

    final init = await handler.initRecorder(path: initPath, settings: settings);
    expect(init, isTrue);

    await handler.record(settings: const RecorderSettings());

    final captured = verify(mockRecorder.start(captureAny, path: captureAnyNamed('path'))).captured;
    final RecordConfig config = captured[0] as RecordConfig;
    final String? usedPath = captured[1] as String?;
    expect(usedPath, initPath);
    expect(config.bitRate, settings.bitRate);
    expect(config.sampleRate, settings.sampleRate);
  });
}
