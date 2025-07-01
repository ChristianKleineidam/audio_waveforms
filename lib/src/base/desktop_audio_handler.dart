import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:record/record.dart'
    show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_waveform/just_waveform.dart';

import '../models/recorder_settings.dart';
import 'constants.dart';
import 'utils.dart';
import 'platform_streams.dart';
import 'player_identifier.dart';

class DesktopAudioHandler {
  DesktopAudioHandler(
      {AudioRecorder? recorder, ja.AudioPlayer Function()? playerFactory})
      : _recorder = recorder ?? AudioRecorder(),
        _playerFactory = playerFactory ?? (() => ja.AudioPlayer());

  final AudioRecorder _recorder;
  final ja.AudioPlayer Function() _playerFactory;
  final Map<String, ja.AudioPlayer> _players = {};
  final Map<String, Timer> _durationTimers = {};
  final Map<String, StreamSubscription<ja.PlayerState>> _stateSubscriptions =
      {};
  final Map<String, int> _frequencies = {};

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

  Future<bool> initRecorder(
      {String? path, required RecorderSettings settings}) async {
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
    _frequencies[key] = frequency;
    await player.setFilePath(path);
    if (volume != null) await player.setVolume(volume.clamp(0.0, 1.0));
    _stateSubscriptions[key]?.cancel();
    _stateSubscriptions[key] = player.playerStateStream.listen((state) {
      if (state.processingState == ja.ProcessingState.completed) {
        if (PlatformStreams.instance.isInitialised) {
          PlatformStreams.instance.addCompletionEvent(
            PlayerIdentifier<void>(key, null),
          );
          PlatformStreams.instance.addPlayerStateEvent(
            PlayerIdentifier<PlayerState>(key, PlayerState.stopped),
          );
        }
        _durationTimers[key]?.cancel();
      }
    });
    return true;
  }

  Future<bool> startPlayer(String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.play();
    _durationTimers[key]?.cancel();
    final freq = _frequencies[key] ?? 200;
    _durationTimers[key] = Timer.periodic(
      Duration(milliseconds: freq),
      (_) {
        final pos = player.position.inMilliseconds;
        if (PlatformStreams.instance.isInitialised) {
          PlatformStreams.instance.addCurrentDurationEvent(
            PlayerIdentifier<int>(key, pos),
          );
        }
      },
    );
    return true;
  }

  Future<bool> stopPlayer(String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.stop();
    _durationTimers.remove(key)?.cancel();
    return true;
  }

  Future<bool> release(String key) async {
    final player = _players.remove(key);
    _durationTimers.remove(key)?.cancel();
    _stateSubscriptions.remove(key)?.cancel();
    _frequencies.remove(key);
    await player?.dispose();
    return true;
  }

  Future<bool> pausePlayer(String key) async {
    final player = _players[key];
    if (player == null) return false;
    await player.pause();
    _durationTimers.remove(key)?.cancel();
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

  Future<void> setReleaseMode(String key, FinishMode mode) async {
    final player = _players[key];
    if (player == null) return;
    player.playerStateStream.listen((state) {
      if (state.processingState == ja.ProcessingState.completed) {
        if (mode == FinishMode.pause) {
          player.pause();
        } else {
          player.stop();
        }
      }
    });
  }

  Future<List<double>> extractWaveformData({
    required String key,
    required String path,
    required int noOfSamples,
  }) async {
    final tempFile =
        File('${(await Directory.systemTemp.createTemp()).path}/waveform_$key');
    final stream = JustWaveform.extract(
      audioInFile: File(path),
      waveOutFile: tempFile,
      zoom: WaveformZoom.pixelsPerSecond(noOfSamples),
    );
    final completer = Completer<List<double>>();
    stream.listen(
      (event) {
        if (event.progress == 1.0 && event.waveform != null) {
          final waveform = event.waveform!;
          final points = <double>[];
          for (var i = 0; i < waveform.length; i++) {
            points.add(waveform.getPixelMax(i).toDouble());
          }
          completer.complete(points);
        }
      },
      onError: completer.completeError,
    );
    return completer.future;
  }

  Future<void> stopWaveformExtraction(String key) async {}

  Future<bool> stopAllPlayers() async {
    for (final entry in _players.entries) {
      await entry.value.stop();
      _durationTimers.remove(entry.key)?.cancel();
    }
    return true;
  }

  Future<bool> pauseAllPlayers() async {
    for (final entry in _players.entries) {
      await entry.value.pause();
      _durationTimers.remove(entry.key)?.cancel();
    }
    return true;
  }
}
