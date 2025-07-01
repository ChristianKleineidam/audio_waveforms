import 'package:flutter_test/flutter_test.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

void main() {
  test('RecorderController initializes', () {
    final controller = RecorderController();
    expect(controller.recorderState, RecorderState.stopped);
  });
}
