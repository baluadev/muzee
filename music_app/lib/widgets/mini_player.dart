import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/full_player_state.dart';
import 'package:muzee/screens/now_playing_page.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/marquee.dart';
import 'package:muzee/widgets/song_artwork.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuber_playback/tuber_playback.dart';

/// Keeps the latest state, so a mini player built again later (e.g. when the
/// keyboard closes) shows at once even while paused, when no new position
/// arrives. The position starts at zero for the same reason.
final ValueStream<FullPlayerState> _fullPlayerStateStream = Rx.combineLatest3(
  audioHandler.playbackState.distinct(),
  audioHandler.queue.distinct(),
  audioHandler.positionDataStream.startWith(
    PositionData(Duration.zero, Duration.zero, Duration.zero),
  ),
  (PlaybackState state, List<MediaItem> queue, PositionData pos) =>
      FullPlayerState(playbackState: state, queue: queue, position: pos),
).debounceTime(const Duration(milliseconds: 100)).shareValue();

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  /// Matches Figma node 1:819 (mini player row height).
  static const double playerHeight = 64;

  /// The row plus its 2 dp progress line and bottom margin.
  static const double totalHeight = playerHeight + 2 + 8;
  static const double _artworkSize = 48;
  static const double _artworkRadius = 8;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, mediaSnapshot) {
          final metadata = mediaSnapshot.data;
          if (metadata == null) return const SizedBox.shrink();

          return StreamBuilder<FullPlayerState>(
            stream: _fullPlayerStateStream,
            initialData: _fullPlayerStateStream.valueOrNull,
            builder: (context, stateSnapshot) {
              final state = stateSnapshot.data;
              if (state == null) return const SizedBox.shrink();

              final hasNext =
                  state.queue.length > 1 &&
                  (state.playbackState.queueIndex ?? 0) <
                      state.queue.length - 1;

              return _MiniPlayerBody(
                colorScheme: colorScheme,
                metadata: metadata,
                state: state,
                hasNext: hasNext,
              );
            },
          );
        },
      ),
    );
  }
}

class _MiniPlayerBody extends StatefulWidget {
  const _MiniPlayerBody({
    required this.colorScheme,
    required this.metadata,
    required this.state,
    required this.hasNext,
  });

  final ColorScheme colorScheme;
  final MediaItem metadata;
  final FullPlayerState state;
  final bool hasNext;

  @override
  State<_MiniPlayerBody> createState() => _MiniPlayerBodyState();
}

class _MiniPlayerBodyState extends State<_MiniPlayerBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static const double _dragThresholdForNavigation = 10;

  void _handleVerticalDrag(DragUpdateDetails details) {
    if ((details.primaryDelta ?? 0) < -_dragThresholdForNavigation) {
      _navigateToNowPlaying();
    }
  }

  void _navigateToNowPlaying() {
    Navigator.of(context).push(_createSlideTransition());
  }

  PageRoute<void> _createSlideTransition() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, _) => const NowPlayingPage(),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.metadata;
    final state = widget.state;
    final neo = context.neo;
    final position = state.position;
    final total = position.duration.inMilliseconds;
    final progress = total <= 0
        ? 0.0
        : (position.position.inMilliseconds / total).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: Semantics(
        button: true,
        label: [
          context.l10n!.openPlayer,
          metadata.title,
          if (metadata.artist?.isNotEmpty ?? false) metadata.artist!,
        ].join(', '),
        child: GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          onVerticalDragUpdate: _handleVerticalDrag,
          onTap: _navigateToNowPlaying,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: neo.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: MiniPlayer.playerHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Row(
                      children: [
                        _ArtworkWidget(metadata: metadata),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            layoutBuilder: (currentChild, previousChildren) =>
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                ),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: KeyedSubtree(
                              key: ValueKey(metadata.id),
                              child: _MetadataWidget(
                                title: metadata.title,
                                artist: metadata.artist,
                              ),
                            ),
                          ),
                        ),
                        _ControlsWidget(
                          playbackState: state.playbackState,
                          hasNext: widget.hasNext,
                        ),
                      ],
                    ),
                  ),
                ),
                // 2 dp progress line along the bottom edge.
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  color: neo.onSurface,
                  backgroundColor: neo.hairline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  const _ArtworkWidget({required this.metadata});
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Hero(
        tag: 'now_playing_artwork',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiniPlayer._artworkRadius),
            color: context.neo.surfaceRaised,
          ),
          child: SongArtworkWidget(
            metadata: metadata,
            size: MiniPlayer._artworkSize,
            errorWidgetIconSize: 24,
            borderRadius: MiniPlayer._artworkRadius,
          ),
        ),
      ),
    );
  }
}

class _MetadataWidget extends StatelessWidget {
  const _MetadataWidget({required this.title, required this.artist});

  final String title;
  final String? artist;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarqueeWidget(
            manualScrollEnabled: false,
            animationDuration: const Duration(seconds: 8),
            backDuration: const Duration(seconds: 2),
            pauseDuration: const Duration(seconds: 2),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: neo.onSurface,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (artist != null && artist!.isNotEmpty)
            Text(
              artist!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: neo.onSurfaceMuted,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _ControlsWidget extends StatelessWidget {
  const _ControlsWidget({required this.playbackState, required this.hasNext});

  final PlaybackState playbackState;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final processingState = playbackState.processingState;
    final isPlaying = playbackState.playing;
    final isLoading =
        processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering;
    final isCompleted = processingState == AudioProcessingState.completed;
    final iconColor = context.neo.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 48 dp targets; the spinner takes the same box so nothing shifts.
        SizedBox.square(
          dimension: 48,
          child: isLoading
              ? Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: isCompleted
                      ? l10n.replay
                      : (isPlaying ? l10n.pause : l10n.play),
                  onPressed: isCompleted
                      ? () => audioHandler.playAgain()
                      : (isPlaying ? audioHandler.pause : audioHandler.play),
                  icon: Icon(
                    isCompleted
                        ? FluentIcons.arrow_counterclockwise_24_filled
                        : (isPlaying
                              ? FluentIcons.pause_24_filled
                              : FluentIcons.play_24_filled),
                    color: iconColor,
                    size: 28,
                  ),
                ),
        ),
        if (hasNext)
          IconButton(
            tooltip: l10n.next,
            onPressed: audioHandler.skipToNext,
            icon: Icon(FluentIcons.next_24_filled, color: iconColor, size: 24),
          ),
      ],
    );
  }
}
