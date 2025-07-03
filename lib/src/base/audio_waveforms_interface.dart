part of '../controllers/player_controller.dart';

class AudioWaveformsInterface {
  AudioWaveformsInterface._();

  /// Public constructor used for testing subclasses.
  AudioWaveformsInterface.test() : this._();

  static AudioWaveformsInterface instance = AudioWaveformsInterface._();

  /// Replaces the global [instance] for testing purposes.
  @visibleForTesting
  static void setInstance(AudioWaveformsInterface testInstance) {
    instance = testInstance;
  }

  final DesktopAudioHandler _desktopHandler = DesktopAudioHandler();

  static const MethodChannel _methodChannel =
      MethodChannel(Constants.methodChannelName);

  ///platform call to start recording
  Future<bool> record({
    required RecorderSettings recorderSetting,
    String? path,
    bool useLegacyNormalization = false,
    bool overrideAudioSession = true,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.record(
        settings: recorderSetting,
        path: path,
      );
    }
    final isRecording = await _methodChannel.invokeMethod(
      Constants.startRecording,
      (Platform.isIOS || Platform.isMacOS)
          ? recorderSetting.iosToJson(
              path: path,
              overrideAudioSession: overrideAudioSession,
              useLegacyNormalization: useLegacyNormalization,
            )
          : {
              Constants.useLegacyNormalization: useLegacyNormalization,
            },
    );
    return isRecording ?? false;
  }

  /// Platform call to initialise the recorder.
  /// This method is only required for Android platform.
  Future<bool> initRecorder({
    String? path,
    required RecorderSettings recorderSettings,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.initRecorder(
        path: path,
        settings: recorderSettings,
      );
    }
    final initialized = await _methodChannel.invokeMethod(
      Constants.initRecorder,
      recorderSettings.androidToJson(path: path),
    );
    return initialized ?? false;
  }

  ///platform call to pause recording
  Future<bool?> pause() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.pause();
    }
    final isRecording =
        await _methodChannel.invokeMethod(Constants.pauseRecording);
    return isRecording;
  }

  ///platform call to stop recording
  Future<Map<String, dynamic>> stop() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.stop();
    }
    Map<Object?, Object?> audioInfo =
        await _methodChannel.invokeMethod(Constants.stopRecording);
    return audioInfo.cast<String, dynamic>();
  }

  ///platform call to resume recording.
  ///This method is only required for Android platform
  Future<bool> resume() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.resume();
    }
    final isRecording =
        await _methodChannel.invokeMethod(Constants.resumeRecording);
    return isRecording ?? false;
  }

  ///platform call to get decibel
  Future<double?> getDecibel() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.getDecibel();
    }
    var db = await _methodChannel.invokeMethod(Constants.getDecibel);
    return db;
  }

  ///platform call to check microphone permission
  Future<bool> checkPermission() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.checkPermission();
    }
    var hasPermission =
        await _methodChannel.invokeMethod(Constants.checkPermission);
    return hasPermission ?? false;
  }

  ///platform call to prepare player
  Future<bool> preparePlayer({
    required String path,
    required String key,
    required int frequency,
    double? volume,
    bool overrideAudioSession = false,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.preparePlayer(
        path: path,
        key: key,
        frequency: frequency,
        volume: volume,
      );
    }
    var result = await _methodChannel.invokeMethod(Constants.preparePlayer, {
      Constants.path: path,
      Constants.volume: volume,
      Constants.playerKey: key,
      Constants.updateFrequency: frequency,
      Constants.overrideAudioSession: overrideAudioSession,
    });
    return result ?? false;
  }

  ///platform call to start player
  Future<bool> startPlayer(String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.startPlayer(key);
    }
    var result = await _methodChannel.invokeMethod(Constants.startPlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to stop player
  Future<bool> stopPlayer(String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.stopPlayer(key);
    }
    var result = await _methodChannel.invokeMethod(Constants.stopPlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to release resource
  Future<bool> release(String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.release(key);
    }
    var result = await _methodChannel.invokeMethod(Constants.releasePlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to pause player
  Future<bool> pausePlayer(String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.pausePlayer(key);
    }
    var result = await _methodChannel.invokeMethod(Constants.pausePlayer, {
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to get duration max/current
  Future<int?> getDuration(String key, int durationType) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.getDuration(key, durationType);
    }
    var duration = await _methodChannel.invokeMethod(Constants.getDuration, {
      Constants.durationType: durationType,
      Constants.playerKey: key,
    });
    return duration;
  }

  ///platform call to set volume
  Future<bool> setVolume(double volume, String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.setVolume(volume, key);
    }
    var result = await _methodChannel.invokeMethod(Constants.setVolume, {
      Constants.volume: volume,
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to set rate
  Future<bool> setRate(double rate, String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.setRate(rate, key);
    }
    var result = await _methodChannel.invokeMethod(Constants.setRate, {
      Constants.rate: rate,
      Constants.playerKey: key,
    });
    return result ?? false;
  }

  ///platform call to seek audio at provided position
  Future<bool> seekTo(String key, int progress) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.seekTo(key, progress);
    }
    var result = await _methodChannel.invokeMethod(Constants.seekTo,
        {Constants.progress: progress, Constants.playerKey: key});
    return result ?? false;
  }

  /// Sets the release mode.
  Future<void> setReleaseMode(String key, FinishMode finishMode) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.setReleaseMode(key, finishMode);
    }
    return await _methodChannel.invokeMethod(Constants.finishMode, {
      Constants.finishType: finishMode.index,
      Constants.playerKey: key,
    });
  }

  Future<List<double>> extractWaveformData({
    required String key,
    required String path,
    required int noOfSamples,
  }) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.extractWaveformData(
        key: key,
        path: path,
        noOfSamples: noOfSamples,
      );
    }
    final result =
        await _methodChannel.invokeMethod(Constants.extractWaveformData, {
      Constants.playerKey: key,
      Constants.path: path,
      Constants.noOfSamples: noOfSamples,
    });
    return List<double>.from(result ?? []);
  }

  /// Stops current executing waveform extraction, if any.
  Future<void> stopWaveformExtraction(String key) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.stopWaveformExtraction(key);
    }
    return await _methodChannel.invokeMethod(Constants.stopExtraction, {
      Constants.playerKey: key,
    });
  }

  Future<bool> stopAllPlayers() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.stopAllPlayers();
    }
    var result = await _methodChannel.invokeMethod(Constants.stopAllPlayers);
    return result ?? false;
  }

  Future<bool> pauseAllPlayers() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _desktopHandler.pauseAllPlayers();
    }
    var result = await _methodChannel.invokeMethod(Constants.pauseAllPlayers);
    return result ?? false;
  }

  Future<void> setMethodCallHandler() async {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case Constants.onCurrentDuration:
          var duration = call.arguments[Constants.current];
          var key = call.arguments[Constants.playerKey];
          if (duration.runtimeType == int) {
            var identifier = PlayerIdentifier<int>(key, duration);
            PlatformStreams.instance.addCurrentDurationEvent(identifier);
          }
          break;
        case Constants.onDidFinishPlayingAudio:
          var key = call.arguments[Constants.playerKey];
          var playerState =
              getPlayerState(call.arguments[Constants.finishType]);
          var stateIdentifier = PlayerIdentifier<PlayerState>(key, playerState);
          var completionIdentifier = PlayerIdentifier<void>(key, null);
          PlatformStreams.instance.addCompletionEvent(completionIdentifier);
          PlatformStreams.instance.addPlayerStateEvent(stateIdentifier);
          if (PlatformStreams.instance.playerControllerFactory[key] != null) {
            PlatformStreams.instance.playerControllerFactory[key]
                ?._playerState = playerState;
          }
          break;
        case Constants.onCurrentExtractedWaveformData:
          var key = call.arguments[Constants.playerKey];
          var progress = call.arguments[Constants.progress];
          var waveformData =
              List<double>.from(call.arguments[Constants.waveformData]);
          PlatformStreams.instance.addExtractedWaveformDataEvent(
            PlayerIdentifier<List<double>>(key, waveformData),
          );
          PlatformStreams.instance.addExtractionProgress(
            PlayerIdentifier<double>(key, progress),
          );
          break;
      }
    });
  }

  PlayerState getPlayerState(int finishModel) {
    switch (finishModel) {
      case 0:
        return PlayerState.playing;
      case 1:
        return PlayerState.paused;
      default:
        return PlayerState.stopped;
    }
  }

  void removeMethodCallHandler() {
    _methodChannel.setMethodCallHandler(null);
  }
}
