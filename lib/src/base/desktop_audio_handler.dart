import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart' show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:flutter/services.dart';
import 'package:just_waveform/just_waveform.dart';

import '../models/recorder_settings.dart';
import 'constants.dart';
import 'utils.dart';

class DesktopAudioHandler {
  DesktopAudioHandler({AudioRecorder? recorder, AudioPlayer Function()? playerFactory})
      : _recorder = recorder ?? AudioRecorder(),
        _playerFactory = playerFactory ?? (() => AudioPlayer()) {
    _desktopChannel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _desktopChannel =
      MethodChannel(Constants.desktopChannelName);

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case Constants.checkPermission:
        return checkPermission();
      default:
        throw PlatformException(
          code: 'AudioWaveforms',
          message: 'Method not implemented',
          details: call.method,
        );
    }
  }

  final AudioRecorder _recorder;
  final AudioPlayer Function() _playerFactory;
  final Map<String, AudioPlayer> _players = {};

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

  Future<bool> initRecorder({String? path, required RecorderSettings settings}) async {
    return true;
  }

  Future<bool?> pause() async {
    await _recorder.pause();
    return true;
  }

  Future<Map<String, dynamic>> stop() async {
    final filePath = await _recorder.stop();
    if (filePath == null) return {};
    final player = AudioPlayer();
    await player.setFilePath(filePath);
    final duration = player.duration?.inMilliseconds ?? 0;
    await player.dispose();
    return {Constants.resultFilePath: filePath, Constants.resultDuration: duration};
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

  Future<void> setReleaseMode(String key, FinishMode mode) async {
    final player = _players[key];
    if (player == null) return;
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
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
    final tempFile = File('${(await Directory.systemTemp.createTemp()).path}/waveform_$key');
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
