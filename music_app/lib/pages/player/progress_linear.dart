import 'package:flutter/material.dart';
import 'package:muzee/main.dart';

class ProgressLinear extends StatelessWidget {
  const ProgressLinear({super.key});

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
        final progress = (durationMs > 0) ? positionMs / durationMs : 0.0;
        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
          minHeight: 2,
        );
      },
    );
  }
}
