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
}
