import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/wave_clipper.dart';

void main() {
  testWidgets('clipper height adjusts for labels', (tester) async {
    final controller = PlayerController();
    final style = PlayerWaveStyle(showDurationLabel: true);

    await tester.pumpWidget(
      MaterialApp(
        home: AudioFileWaveforms(
          size: const Size(200, 50),
          playerController: controller,
          waveformData: const [0.1, 0.2, 0.3],
          playerWaveStyle: style,
        ),
      ),
    );

    final clipPath = tester.widget<ClipPath>(find.byType(ClipPath));
    final clipper = clipPath.clipper as WaveClipper;
    expect(clipper.extraClipperHeight, greaterThan(0));
  });
}
