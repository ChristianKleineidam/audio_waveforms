import 'package:audio_waveforms/src/base/desktop_audio_handler.dart';
import 'package:audio_waveforms/src/models/recorder_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:record/record.dart' show AudioRecorder, RecordConfig, AudioEncoder;
import 'package:just_audio/just_audio.dart';
import 'package:audio_waveforms/src/base/constants.dart';
import 'desktop_audio_handler_test.mocks.dart';

@GenerateMocks([AudioRecorder, AudioPlayer])
void main() {
  test('record starts recording when permission granted', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockRecorder = MockAudioRecorder();
    when(mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(mockRecorder.start(any, path: anyNamed('path')))
        .thenAnswer((_) async => null);

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

  test('checkPermission via method channel delegates to handler', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockRecorder = MockAudioRecorder();
    when(mockRecorder.hasPermission()).thenAnswer((_) async => true);

    final handler = DesktopAudioHandler(
      recorder: mockRecorder,
      playerFactory: () => MockAudioPlayer(),
    );

    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final completer = Completer<ByteData?>();
    messenger.handlePlatformMessage(
      Constants.desktopChannelName,
      codec.encodeMethodCall(
        const MethodCall(Constants.checkPermission),
      ),
      (data) => completer.complete(data),
    );
    final reply = await completer.future ?? ByteData(0);
    final result = codec.decodeEnvelope(reply) as bool;

    expect(result, isTrue);
    verify(mockRecorder.hasPermission()).called(1);
  });
}
