import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/theme/neo/neo_colors.dart';

class VideoFullscreenPage extends StatefulWidget {
  const VideoFullscreenPage({super.key, required this.controller});

  final VideoController controller;

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  @override
  void initState() {
    super.initState();
    UiRouteFlags.videoFullscreenVisible.value = true;
    _enterFullscreenMode();
  }

  Future<void> _enterFullscreenMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreSystemMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    UiRouteFlags.videoFullscreenVisible.value = false;
    _restoreSystemMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: MaterialVideoControlsTheme(
              normal: MaterialVideoControlsThemeData(
                seekBarThumbColor: context.neo.accent,
                seekBarPositionColor: context.neo.accent,
                bottomButtonBarMargin: const EdgeInsets.only(
                  bottom: 24,
                  left: 16,
                  right: 16,
                ),
              ),
              fullscreen: MaterialVideoControlsThemeData(
                seekBarThumbColor: context.neo.accent,
                seekBarPositionColor: context.neo.accent,
                bottomButtonBarMargin: const EdgeInsets.only(
                  bottom: 24,
                  left: 16,
                  right: 16,
                ),
              ),
              child: Video(
                controller: widget.controller,
                controls: MaterialVideoControls,
                pauseUponEnteringBackgroundMode: false,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  color: context.neo.onSurface,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF0A0A0A,
                    ).withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
