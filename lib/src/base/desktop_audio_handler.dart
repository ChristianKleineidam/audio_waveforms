import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:record/record.dart'
    show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_waveform/just_waveform.dart';

import '../models/recorder_settings.dart';
import 'constants.dart';
import 'utils.dart';
import 'player_identifier.dart';
import 'platform_streams.dart';

typedef _WaveformExtractor = Stream<dynamic> Function({
  required File audioInFile,
  required File waveOutFile,
  required WaveformZoom zoom,
});

class DesktopAudioHandler {
  DesktopAudioHandler({
    AudioRecorder? recorder,
    ja.AudioPlayer Function()? playerFactory,
    _WaveformExtractor? waveformExtractor,
  })  : _recorder = recorder ?? AudioRecorder(),
        _playerFactory = playerFactory ?? (() => ja.AudioPlayer()),
        _waveformExtractor =
            waveformExtractor ?? JustWaveform.extract;

  final AudioRecorder _recorder;
  final ja.AudioPlayer Function() _playerFactory;
  final Map<String, ja.AudioPlayer> _players = {};
  final _waveformSubscriptions = <String, StreamSubscription>{};
  final _waveformCompleters = <String, Completer<List<double>>>{};
  final _WaveformExtractor _waveformExtractor;

  Future<bool> record({
    required RecorderSettings settings,
    String? path,
  }) async {
    if (!await _recorder.hasPermission()) return false;
    final recordPath = path ??
        '${(await Directory.systemTemp.createTemp()).path}/recording.m4a';
    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: settings.bitRate ?? 128000,
        sampleRate: settings.sampleRate ?? 44100,
      ),
      path: recordPath,
    );
    return true;
  }

  Future<bool> initRecorder({
    String? path,
    required RecorderSettings settings,
  }) async {
    if (!await _recorder.hasPermission()) return false;

    if (path != null) {
      final file = File(path);
      await file.parent.create(recursive: true);
    }

    return true;
  }

  Future<bool?> pause() async {
    await _recorder.pause();
    return true;
  }

  Future<Map<String, dynamic>> stop() async {
    final filePath = await _recorder.stop();
    if (filePath == null) return {};
    final player = ja.AudioPlayer();
    await player.setFilePath(filePath);
    final duration = player.duration?.inMilliseconds ?? 0;
    await player.dispose();
    return {
      Constants.resultFilePath: filePath,
      Constants.resultDuration: duration
    };
  }

  Future<bool> resume() async {
    await _recorder.resume();
    return true;
  }

  Future<double?> getDecibel() async {
    final amp = await _recorder.getAmplitude();
    return amp?.current;
  }

  Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  Future<bool> preparePlayer({
    required String path,
    required String key,
    required int frequency,
    double? volume,
  }) async {
    final player = _players.putIfAbsent(key, () => _playerFactory());
    await player.setFilePath(path);
    if (volume != null) await player.setVolume(volume.clamp(0.0, 1.0));
    return true;
  }

  Future<bool> startPlayer(String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.play();
    return true;
  }

  Future<bool> stopPlayer(String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.stop();
    return true;
  }

  Future<bool> release(String key) async {
    final player = _players.remove(key);
    await player?.dispose();
    return true;
  }

  Future<bool> pausePlayer(String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.pause();
    return true;
  }

  Future<int?> getDuration(String key, int durationType) async {
    final player = _players[key];
    if (player == null) return null;
    if (durationType == 0) {
      return player.position.inMilliseconds;
    }
    await player.load();
    return player.duration?.inMilliseconds;
  }

  Future<bool> setVolume(double volume, String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.setVolume(volume.clamp(0.0, 1.0));
    return true;
  }

  Future<bool> setRate(double rate, String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.setSpeed(rate);
    return true;
  }

  Future<bool> seekTo(String key, int progress) async {
    final player = _players[key];
    if (player == null) return false;
    await player.seek(Duration(milliseconds: progress));
    return true;
  }

  final Map<String, StreamSubscription<ja.PlayerState>>
      _completionSubscriptions = {};

  Future<void> setReleaseMode(String key, FinishMode mode) async {
    final player = _players[key];
    if (player == null) return;

    await _completionSubscriptions[key]?.cancel();
    _completionSubscriptions.remove(key);

    switch (mode) {
      case FinishMode.loop:
        await player.setLoopMode(ja.LoopMode.one);
        break;
      case FinishMode.pause:
        await player.setLoopMode(ja.LoopMode.off);
        _completionSubscriptions[key] =
            player.playerStateStream.listen((state) {
          if (state.processingState == ja.ProcessingState.completed) {
            player.pause();
            player.seek(Duration.zero);
          }
        });
        break;
      case FinishMode.stop:
        await player.setLoopMode(ja.LoopMode.off);
        _completionSubscriptions[key] =
            player.playerStateStream.listen((state) {
          if (state.processingState == ja.ProcessingState.completed) {
            player.stop();
          }
        });
        break;
    }
  }

  Future<List<double>> extractWaveformData({
    required String key,
    required String path,
    required int noOfSamples,
  }) async {
    await stopWaveformExtraction(key);
    final tempFile =
        File('${(await Directory.systemTemp.createTemp()).path}/waveform_$key');
    final stream = _waveformExtractor(
      audioInFile: File(path),
      waveOutFile: tempFile,
      zoom: WaveformZoom.pixelsPerSecond(noOfSamples),
    );
    final completer = Completer<List<double>>();
    _waveformCompleters[key] = completer;
    _waveformSubscriptions[key] = stream.listen(
      (event) {
        final progress = event.progress as double? ?? 0.0;
        PlatformStreams.instance.addExtractionProgress(
          PlayerIdentifier<double>(key, progress),
        );
        if (progress == 1.0 && event.waveform != null) {
          final waveform = event.waveform as Waveform;
          final points = <double>[];
          for (var i = 0; i < waveform.length; i++) {
            points.add(waveform.getPixelMax(i).toDouble());
          }
          PlatformStreams.instance.addExtractedWaveformDataEvent(
            PlayerIdentifier<List<double>>(key, points),
          );
          completer.complete(points);
        }
      },
      onError: completer.completeError,
      onDone: () {
        _waveformSubscriptions.remove(key);
        _waveformCompleters.remove(key);
      },
    );
    return completer.future;
  }

  Future<void> stopWaveformExtraction(String key) async {
    await _waveformSubscriptions[key]?.cancel();
    _waveformSubscriptions.remove(key);
    _waveformCompleters.remove(key);
  }

  Future<bool> stopAllPlayers() async {
    for (final player in _players.values) {
      await player.stop();
    }
    return true;
  }

  Future<bool> pauseAllPlayers() async {
    for (final player in _players.values) {
      await player.pause();
    }
    return true;
  }
}
