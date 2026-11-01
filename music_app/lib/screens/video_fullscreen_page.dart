import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/theme/neo/neo_motion.dart';
import 'package:muzee/widgets/playback_icon_button.dart';
import 'package:muzee/widgets/position_slider.dart';

/// The video on its own, in landscape.
///
/// Tap the left or right side to go back or forward 5 seconds; taps in a row
/// add up (twice = 10 s, three times = 15 s, …). Tap the middle to show or
/// hide the controls, which hide by themselves after a few seconds of play.
class VideoFullscreenPage extends StatefulWidget {
  const VideoFullscreenPage({
    super.key,
    required VideoController this.controller,
  }) : video = null;

  /// Shows [video] in place of the player's surface (tests can't create a
  /// [VideoController]).
  @visibleForTesting
  const VideoFullscreenPage.withVideo({super.key, required Widget this.video})
    : controller = null;

  final VideoController? controller;
  final Widget? video;

  /// How far one tap on a side seeks.
  static const seekStep = Duration(seconds: 5);

  /// Taps closer together than this add up.
  static const seekStreakWindow = Duration(milliseconds: 700);

  static const controlsAutoHide = Duration(seconds: 3);

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  StreamSubscription<PlaybackState>? _playbackSub;
  bool _playing = false;

  /// -1 back, 1 forward, 0 no seek streak running.
  int _seekDirection = 0;
  int _seekSeconds = 0;
  Duration? _seekTarget;
  Timer? _seekStreakTimer;

  @override
  void initState() {
    super.initState();
    UiRouteFlags.videoFullscreenVisible.value = true;
    _enterFullscreenMode();
    _playing = audioHandler.playbackState.value.playing;
    _playbackSub = audioHandler.playbackState.listen((state) {
      if (state.playing == _playing) return;
      setState(() => _playing = state.playing);
      _scheduleHide();
    });
    _scheduleHide();
  }

  Future<void> _enterFullscreenMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreSystemMode() async {
    // Back to whatever the device allows (an empty list): forcing portrait
    // here would lock the whole app in portrait afterwards.
    await SystemChrome.setPreferredOrientations(const []);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekStreakTimer?.cancel();
    _playbackSub?.cancel();
    UiRouteFlags.videoFullscreenVisible.value = false;
    _restoreSystemMode();
    super.dispose();
  }

  /// While playing, the controls hide after a while; paused, they stay.
  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_controlsVisible || !_playing) return;
    _hideTimer = Timer(VideoFullscreenPage.controlsAutoHide, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    _scheduleHide();
  }

  bool get _canSeek {
    final item = audioHandler.mediaItem.valueOrNull;
    if (item?.extras?['isLive'] == true) return false;
    return (audioHandler.audioPlayer.duration ?? Duration.zero) > Duration.zero;
  }

  void _seek(int direction) {
    if (!_canSeek) return;
    final player = audioHandler.audioPlayer;
    final duration = player.duration ?? Duration.zero;
    final inStreak = _seekDirection == direction && _seekTarget != null;
    // Taps in a row seek from where the last one went: the player may not
    // have reported the new position yet.
    final from = inStreak ? _seekTarget! : player.position;
    var target = from + VideoFullscreenPage.seekStep * direction;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;

    setState(() {
      _seekDirection = direction;
      _seekSeconds =
          (inStreak ? _seekSeconds : 0) +
          VideoFullscreenPage.seekStep.inSeconds;
      _seekTarget = target;
    });
    audioHandler.seek(target);
    if (_controlsVisible) _scheduleHide();

    _seekStreakTimer?.cancel();
    _seekStreakTimer = Timer(VideoFullscreenPage.seekStreakWindow, () {
      if (!mounted) return;
      setState(() {
        _seekDirection = 0;
        _seekTarget = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final fade = resolveMotion(context, NeoMotion.of(context).standard);
    final step = VideoFullscreenPage.seekStep.inSeconds;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child:
                widget.video ??
                Video(
                  controller: widget.controller!,
                  controls: NoVideoControls,
                  pauseUponEnteringBackgroundMode: false,
                ),
          ),
          // Tap zones: back · show/hide controls · forward.
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _TapZone(
                  label: l10n.seekBackSeconds(step),
                  onTap: () => _seek(-1),
                ),
              ),
              Expanded(
                flex: 4,
                child: _TapZone(label: null, onTap: _toggleControls),
              ),
              Expanded(
                flex: 3,
                child: _TapZone(
                  label: l10n.seekForwardSeconds(step),
                  onTap: () => _seek(1),
                ),
              ),
            ],
          ),
          _SeekFeedback(
            direction: _seekDirection,
            seconds: _seekSeconds,
            duration: fade,
          ),
          AnimatedOpacity(
            opacity: _controlsVisible ? 1 : 0,
            duration: fade,
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: _Controls(onClose: () => Navigator.of(context).pop()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapZone extends StatelessWidget {
  const _TapZone({required this.label, required this.onTap});

  /// Screen-reader label; null for the show/hide zone, which only matters
  /// visually.
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final zone = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
    );
    if (label == null) return ExcludeSemantics(child: zone);
    return Semantics(button: true, label: label, onTap: onTap, child: zone);
  }
}

/// "−10s" / "+15s" on the side that was tapped, while taps keep coming.
class _SeekFeedback extends StatelessWidget {
  const _SeekFeedback({
    required this.direction,
    required this.seconds,
    required this.duration,
  });

  final int direction;
  final int seconds;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final forward = direction > 0;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: direction == 0 ? 0 : 1,
        duration: duration,
        child: Align(
          alignment: forward ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 0.3,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: forward
                    ? const BorderRadius.horizontal(left: Radius.circular(999))
                    : const BorderRadius.horizontal(
                        right: Radius.circular(999),
                      ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      forward
                          ? FluentIcons.fast_forward_24_filled
                          : FluentIcons.rewind_24_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${forward ? '+' : '−'}${seconds}s',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Close and title on top, previous · play/pause · next in the middle, the
/// timeline at the bottom, over gradients that keep them readable.
class _Controls extends StatelessWidget {
  const _Controls({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final neo = context.neo;
    const scrim = Color(0xB3000000);

    return Stack(
      fit: StackFit.expand,
      children: [
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scrim, Colors.transparent, Colors.transparent, scrim],
                stops: [0, 0.3, 0.65, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.exitFullscreen,
                      color: Colors.white,
                      icon: const Icon(
                        FluentIcons.full_screen_minimize_24_regular,
                      ),
                      onPressed: onClose,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(child: _Title()),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.skipToPrevious,
                      iconSize: 36,
                      color: Colors.white,
                      disabledColor: Colors.white38,
                      icon: const Icon(FluentIcons.previous_24_filled),
                      onPressed: audioHandler.hasPrevious
                          ? audioHandler.skipToPrevious
                          : null,
                    ),
                    const SizedBox(width: 32),
                    PlaybackIconButton(
                      iconSize: 36,
                      iconColor: neo.onAccent,
                      backgroundColor: neo.accent,
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      tooltip: l10n.skipToNext,
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(FluentIcons.next_24_filled),
                      onPressed: audioHandler.skipToNext,
                    ),
                  ],
                ),
                const Spacer(),
                const PositionSlider(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      initialData: audioHandler.mediaItem.valueOrNull,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        final artist = item.artist;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (artist != null && artist.isNotEmpty)
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        );
      },
    );
  }
}
