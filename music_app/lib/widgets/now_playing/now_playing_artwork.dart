import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/screens/now_playing_route.dart';
import 'package:muzee/screens/video_fullscreen_page.dart';
import 'package:muzee/services/common_services.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/widgets/song_artwork.dart';

/// Marks a `NowPlayingPage` built as a drag preview: its artwork shows the
/// still image (no video surface, no Hero).
class NowPlayingPreview extends InheritedWidget {
  const NowPlayingPreview({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<NowPlayingPreview>() != null;

  @override
  bool updateShouldNotify(NowPlayingPreview oldWidget) => false;
}

class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({
    super.key,
    required this.size,
    required this.metadata,
    required this.lyricsController,
  });
  final Size size;
  final MediaItem metadata;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isLandscape = screenWidth > screenHeight;
    final isDesktop = screenWidth > 800;
    final imageWidth = isDesktop
        ? screenHeight * 0.50
        : isLandscape
        ? screenHeight * 0.65
        : double.infinity;

    final imageHeight = isDesktop
        ? screenHeight * 0.50
        : isLandscape
        ? screenHeight * 0.65
        : screenWidth * 0.60;

    const borderRadius = 8.0;
    final preview = NowPlayingPreview.of(context);

    return FlipCard(
      rotateSide: RotateSide.right,
      onTapFlipping: !offlineMode.value,
      controller: lyricsController,
      frontWidget: HeroMode(
        enabled: !preview,
        child: Hero(
          tag: nowPlayingArtworkHeroTag,
          transitionOnUserGestures: true,
          // In flight, the still artwork stands in for a video, so the player's
          // video surface isn't rebuilt mid-move.
          flightShuttleBuilder: (_, __, ___, ____, _____) => SongArtworkWidget(
            metadata: metadata,
            size: double.infinity,
            height: double.infinity,
            errorWidgetIconSize: size.width / 8,
            borderRadius: borderRadius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: preview
                  ? SongArtworkWidget(
                      metadata: metadata,
                      size: imageWidth,
                      height: imageHeight,
                      errorWidgetIconSize: size.width / 8,
                      borderRadius: borderRadius,
                    )
                  : _NowPlayingMediaSurface(
                      metadata: metadata,
                      size: imageWidth,
                      height: imageHeight,
                      errorWidgetIconSize: size.width / 8,
                      borderRadius: borderRadius,
                    ),
            ),
          ),
        ),
      ),
      backWidget: Container(
        width: imageWidth,
        height: imageHeight,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: AsyncLoader<String?>(
          future: getSongLyrics(metadata.artist, metadata.title),
          emptyWidget: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.text_quote_24_regular,
                  size: 48,
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n!.lyricsNotAvailable,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          errorBuilder: (ctx, error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FluentIcons.text_quote_24_regular,
                  size: 48,
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n!.lyricsNotAvailable,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          builder: (context, lyrics) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Text(
              lyrics ?? context.l10n!.lyricsNotAvailable,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSecondaryContainer,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingMediaSurface extends StatefulWidget {
  const _NowPlayingMediaSurface({
    required this.metadata,
    required this.size,
    this.height,
    required this.errorWidgetIconSize,
    required this.borderRadius,
  });

  final MediaItem metadata;
  final double size;
  final double? height;
  final double errorWidgetIconSize;
  final double borderRadius;

  @override
  State<_NowPlayingMediaSurface> createState() =>
      _NowPlayingMediaSurfaceState();
}

class _NowPlayingMediaSurfaceState extends State<_NowPlayingMediaSurface> {
  VideoController? _videoController;
  String? _videoRenderKey;

  /// Whether the current controller has drawn a frame yet.
  bool _videoShowing = false;

  bool get _isVideo => widget.metadata.extras?['isVideo'] == true;
  String? get _videoSource =>
      widget.metadata.extras?['videoSource']?.toString();
  String get _currentVideoRenderKey =>
      '${widget.metadata.id}|${_videoSource ?? ''}';

  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  @override
  void didUpdateWidget(covariant _NowPlayingMediaSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasVideo = oldWidget.metadata.extras?['isVideo'] == true;
    final previousVideoSource = oldWidget.metadata.extras?['videoSource']
        ?.toString();
    final sourceChanged = previousVideoSource != _videoSource;
    final idChanged = oldWidget.metadata.id != widget.metadata.id;
    if (wasVideo != _isVideo || sourceChanged || idChanged) {
      _initVideoController(forceRecreate: sourceChanged || idChanged);
    }
  }

  void _initVideoController({bool forceRecreate = false}) {
    if (!_isVideo) {
      if (_videoController != null && mounted) {
        setState(() {
          _videoController = null;
          _videoRenderKey = null;
        });
        return;
      }
      _videoController = null;
      _videoRenderKey = null;
      return;
    }

    final nextKey = _currentVideoRenderKey;
    if (forceRecreate ||
        _videoController == null ||
        _videoRenderKey != nextKey) {
      final controller = VideoController(audioHandler.audioPlayer.nativePlayer);
      _videoShowing = false;
      controller.waitUntilFirstFrameRendered.then((_) {
        if (mounted && _videoController == controller) {
          setState(() => _videoShowing = true);
        }
      });
      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoRenderKey = nextKey;
        });
      } else {
        _videoController = controller;
        _videoRenderKey = nextKey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo && _videoController == null) {
      _initVideoController();
    }

    if (_isVideo && _videoController != null) {
      return Stack(
        children: [
          // The artwork shows through until the video's first frame.
          if (!_videoShowing) _artwork(),
          SizedBox(
            width: widget.size,
            height: widget.height ?? widget.size,
            child: Video(
              controller: _videoController!,
              pauseUponEnteringBackgroundMode: false,
              controls: NoVideoControls,
              fill: Colors.transparent,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () async {
                  final controller = _videoController;
                  if (controller == null) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          VideoFullscreenPage(controller: controller),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    FluentIcons.full_screen_maximize_24_regular,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _artwork();
  }

  Widget _artwork() => SongArtworkWidget(
    metadata: widget.metadata,
    size: widget.size,
    height: widget.height,
    errorWidgetIconSize: widget.errorWidgetIconSize,
    borderRadius: widget.borderRadius,
  );
}
