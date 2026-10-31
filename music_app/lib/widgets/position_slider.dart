import 'package:flutter/material.dart';
import 'package:muzee/main.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:tuber_playback/tuber_playback.dart';

class PositionSlider extends StatefulWidget {
  const PositionSlider({super.key});

  @override
  State<PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends State<PositionSlider> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream,
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data != null;
        final positionData = hasData
            ? snapshot.data!
            : PositionData(Duration.zero, Duration.zero, Duration.zero);

        final maxDuration = positionData.duration.inSeconds > 0
            ? positionData.duration.inSeconds.toDouble()
            : 1.0;

        final currentValue = _isDragging
            ? _dragValue
            : positionData.position.inSeconds.toDouble();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: context.neo.accent,
                inactiveTrackColor: const Color(
                  0xFF849588,
                ).withValues(alpha: 0.3),
                thumbColor: context.neo.accent,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayColor: context.neo.accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: currentValue.clamp(0.0, maxDuration),
                onChanged: hasData
                    ? (value) {
                        setState(() {
                          _isDragging = true;
                          _dragValue = value;
                        });
                      }
                    : null,
                onChangeEnd: hasData
                    ? (value) {
                        audioHandler.seek(Duration(seconds: value.toInt()));
                        setState(() {
                          _isDragging = false;
                        });
                      }
                    : null,
                max: maxDuration,
                semanticFormatterCallback: (value) =>
                    formatDuration(value.toInt()),
              ),
            ),
            _buildPositionRow(context, primaryColor, positionData),
          ],
        );
      },
    );
  }

  Widget _buildPositionRow(
    BuildContext context,
    Color fontColor,
    PositionData positionData,
  ) {
    final positionText = formatDuration(positionData.position.inSeconds);
    final durationText = formatDuration(positionData.duration.inSeconds);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: context.neo.onSurfaceMuted,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: textStyle),
          Text(durationText, style: textStyle),
        ],
      ),
    );
  }
}
