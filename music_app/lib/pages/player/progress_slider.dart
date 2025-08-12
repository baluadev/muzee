import 'package:flutter/material.dart';
import 'package:muzee/main.dart';

class ProgressSlider extends StatelessWidget {
  const ProgressSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<({Duration position, Duration duration})>(
      stream: myPlayerService.progressStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final position = data?.position ?? Duration.zero;
        final duration = data?.duration ?? Duration.zero;

        final durationMs = duration.inMilliseconds;
        final positionMs = position.inMilliseconds.clamp(0, durationMs);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.white.withOpacity(0.75),
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.white,
                overlayColor: Colors.white.withAlpha(32),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
              ),
              child: Slider(
                min: 0,
                max: durationMs > 0 ? durationMs.toDouble() : 1.0,
                value: durationMs > 0 ? positionMs.toDouble() : 0.0,
                onChanged: (value) {
                  myPlayerService.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _formatDuration(duration),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
