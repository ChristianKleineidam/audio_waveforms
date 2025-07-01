import 'package:flutter/material.dart';

class PlayerWaveStyle {
  ///Color of the [wave] which is behind the live wave.
  final Color fixedWaveColor;

  ///Color of the [live] wave which indicates currently played part.
  final Color liveWaveColor;

  /// Space between two waves.
  final double spacing;

  ///Whether to show upper wave or not defaults to true
  final bool showTop;

  ///Whether to show bottom wave or not default to true
  final bool showBottom;

  /// The kind of finish to place on the end of lines drawn.
  /// Default to StrokeCap.round
  final StrokeCap waveCap;

  /// Color line in the middle
  final Color seekLineColor;

  /// Thickness of seek line. For microphone recording this line
  /// is in the middle.
  final double seekLineThickness;

  /// Width of each wave
  final double waveThickness;

  /// The background color of waveform box default is Black
  final Color backgroundColor;

  /// Provide gradient to waves which is behind the live wave.
  /// Use shader as shown in example.
  final Shader? fixedWaveGradient;

  /// This is applied to each wave while generating.
  /// Use this to scale the waves. Defaults to 100.0.
  final double scaleFactor;

  /// This gradient is applied to waves which indicates currently played part.
  final Shader? liveWaveGradient;

  /// Scales the wave when waveforms are seeked. The scaled waves returns back
  /// to original scale when gesture ends. To get result set value greater then
  /// 1.
  final double scrollScale;

  /// Shows seek line in the middle when enabled.
  final bool showSeekLine;

  /// Render duration labels below the waveform when enabled.
  final bool showDurationLabel;

  /// Show duration label in HH:MM:SS format. Default is MM:SS
  final bool showHourInDuration;

  /// Text style for duration labels
  final TextStyle durationStyle;

  /// Color of duration lines
  final Color durationLinesColor;

  /// Height of duration lines
  final double durationLinesHeight;

  /// Space between duration labels and waveform square
  final double labelSpacing;

  /// It might happen that label text gets cut or have extra clipping. Use this
  /// to override the calculated clipping height.
  final double? extraClipperHeight;

  /// Value > 0 will be padded right and value < 0 will be padded left.
  final double durationTextPadding;

  const PlayerWaveStyle({
    this.fixedWaveColor = Colors.white54,
    this.liveWaveColor = Colors.white,
    this.showTop = true,
    this.showBottom = true,
    this.showSeekLine = true,
    this.waveCap = StrokeCap.round,
    this.seekLineColor = Colors.white,
    this.seekLineThickness = 2.0,
    this.waveThickness = 3.0,
    this.backgroundColor = Colors.black,
    this.fixedWaveGradient,
    this.scaleFactor = 100.0,
    this.liveWaveGradient,
    this.spacing = 5,
    this.scrollScale = 1.0,
    this.showDurationLabel = false,
    this.showHourInDuration = false,
    this.durationStyle = const TextStyle(
      color: Colors.red,
      fontSize: 16.0,
    ),
    this.durationLinesColor = Colors.blueAccent,
    this.durationLinesHeight = 16.0,
    this.labelSpacing = 16.0,
    this.extraClipperHeight,
    this.durationTextPadding = 20.0,
  })  : assert(spacing >= 0),
        assert(waveThickness < spacing,
            "waveThickness can't be greater than spacing");

  /// Determines number of samples which will fit in provided width.
  /// Returned number of samples are also dependent on [spacing] set for
  /// this constructor.
  int getSamplesForWidth(double width) {
    return width ~/ spacing;
  }
}
