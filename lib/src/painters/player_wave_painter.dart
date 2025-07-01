import 'package:flutter/material.dart';

import '../../audio_waveforms.dart';
import '../base/label.dart';
import '../base/utils.dart';

class PlayerWavePainter extends CustomPainter {
  final List<double> waveformData;
  final double animValue;
  final Offset totalBackDistance;
  final Offset dragOffset;
  final double audioProgress;
  final VoidCallback pushBack;
  final bool callPushback;
  final double emptySpace;
  final double scrollScale;
  final WaveformType waveformType;

  final PlayerWaveStyle playerWaveStyle;

  late final Paint _durationLinePaint = Paint()
    ..strokeWidth = 3
    ..color = playerWaveStyle.durationLinesColor;

  final List<Label> _labels = [];

  PlayerWavePainter({
    required this.waveformData,
    required this.animValue,
    required this.dragOffset,
    required this.totalBackDistance,
    required this.audioProgress,
    required this.pushBack,
    required this.callPushback,
    required this.scrollScale,
    required this.waveformType,
    required this.cachedAudioProgress,
    required this.playerWaveStyle,
  })  : fixedWavePaint = Paint()
          ..color = playerWaveStyle.fixedWaveColor
          ..strokeWidth = playerWaveStyle.waveThickness
          ..strokeCap = playerWaveStyle.waveCap
          ..shader = playerWaveStyle.fixedWaveGradient,
        liveWavePaint = Paint()
          ..color = playerWaveStyle.liveWaveColor
          ..strokeWidth = playerWaveStyle.waveThickness
          ..strokeCap = playerWaveStyle.waveCap
          ..shader = playerWaveStyle.liveWaveGradient,
        emptySpace = playerWaveStyle.spacing,
        middleLinePaint = Paint()
          ..color = playerWaveStyle.seekLineColor
          ..strokeWidth = playerWaveStyle.seekLineThickness;

  Paint fixedWavePaint;
  Paint liveWavePaint;
  Paint middleLinePaint;
  double cachedAudioProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(size, canvas);
    if (playerWaveStyle.showSeekLine && waveformType.isLong) {
      _drawMiddleLine(size, canvas);
    }
  }

  @override
  bool shouldRepaint(PlayerWavePainter oldDelegate) => true;

  void _drawMiddleLine(Size size, Canvas canvas) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      fixedWavePaint
        ..color = playerWaveStyle.seekLineColor
        ..strokeWidth = playerWaveStyle.seekLineThickness,
    );
  }

  void _drawWave(Size size, Canvas canvas) {
    final length = waveformData.length;
    final halfWidth = size.width * 0.5;
    final halfHeight = size.height * 0.5;
    if (cachedAudioProgress != audioProgress) {
      pushBack();
    }
    for (int i = 0; i < length; i++) {
      final currentDragPointer = dragOffset.dx - totalBackDistance.dx;
      final waveWidth = i * playerWaveStyle.spacing;
      final dx = waveWidth +
          currentDragPointer +
          emptySpace +
          (waveformType.isFitWidth ? 0 : halfWidth);
      final waveHeight = (waveformData[i] * animValue) *
          playerWaveStyle.scaleFactor *
          scrollScale;
      final bottomDy =
          halfHeight + (playerWaveStyle.showBottom ? waveHeight : 0);
      final topDy = halfHeight + (playerWaveStyle.showTop ? -waveHeight : 0);

      // Only draw waves which are in visible viewport.
      if (dx > 0 && dx < halfWidth * 2) {
        canvas.drawLine(
          Offset(dx, bottomDy),
          Offset(dx, topDy),
          i < audioProgress * length ? liveWavePaint : fixedWavePaint,
        );
        if (playerWaveStyle.showDurationLabel) {
          _addLabel(canvas, dx, size, i);
          _drawTextInRange(canvas, i, size);
        }
      }
    }
  }

  void _addLabel(Canvas canvas, double dx, Size size, int index) {
    canvas.drawLine(
      Offset(dx, size.height),
      Offset(dx, size.height + playerWaveStyle.durationLinesHeight),
      _durationLinePaint,
    );
    final labelDuration = Duration(seconds: index);
    _labels.add(
      Label(
        content: playerWaveStyle.showHourInDuration
            ? labelDuration.toHHMMSS()
            : labelDuration.inSeconds.toMMSS(),
        offset: Offset(
          dx - playerWaveStyle.durationTextPadding,
          size.height + playerWaveStyle.labelSpacing,
        ),
      ),
    );
  }

  void _drawTextInRange(Canvas canvas, int index, Size size) {
    if (_labels.isEmpty || index >= _labels.length) return;
    final label = _labels[index];
    final textPainter = TextPainter(
      text: TextSpan(text: label.content, style: playerWaveStyle.durationStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, label.offset);
  }
}
