import 'package:audio_service/audio_service.dart';
import 'package:floating/floating.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/main.dart';
import 'package:muzee/services/monetization/ui_route_flags.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/now_playing/bottom_actions_row.dart';
import 'package:muzee/widgets/now_playing/marquee_text_widget.dart';
import 'package:muzee/widgets/now_playing/now_playing_artwork.dart';
import 'package:muzee/widgets/now_playing/now_playing_controls.dart';
import 'package:muzee/widgets/position_slider.dart';
import 'package:muzee/widgets/queue_list_view.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final _lyricsController = FlipCardController();
  late final VideoController _pipVideoController;

  @override
  void initState() {
    super.initState();
    UiRouteFlags.nowPlayingVisible.value = true;
    _pipVideoController = VideoController(
      audioHandler.audioPlayer.nativePlayer,
    );
  }

  @override
  void dispose() {
    UiRouteFlags.nowPlayingVisible.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.width > 800 && size.height > 600;
    final screenWidth = size.width;
    final baseIconSize = screenWidth < 360
        ? 36.0
        : screenWidth < 400
        ? 40.0
        : 44.0;
    final miniIconSize = screenWidth < 360 ? 18.0 : 22.0;

    return Scaffold(
      body: GestureDetector(
        // Swipe down anywhere (outside the slider and lyrics) to close.
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 600) Navigator.maybePop(context);
        },
        child: SafeArea(
          child: StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              if (snapshot.data == null || !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final metadata = snapshot.data!;
              return PiPSwitcher(
                childWhenEnabled: _PipVideoOnlySurface(
                  controller: _pipVideoController,
                  metadata: metadata,
                ),
                childWhenDisabled: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: isLargeScreen
                          ? _DesktopLayout(
                              metadata: metadata,
                              size: size,
                              adjustedIconSize: baseIconSize,
                              adjustedMiniIconSize: miniIconSize,
                              lyricsController: _lyricsController,
                            )
                          : _MobileLayout(
                              metadata: metadata,
                              size: size,
                              adjustedIconSize: baseIconSize,
                              adjustedMiniIconSize: miniIconSize,
                              isLargeScreen: isLargeScreen,
                              lyricsController: _lyricsController,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n!.closePlayer,
            iconSize: 28,
            icon: const Icon(FluentIcons.chevron_down_24_regular),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              context.l10n!.nowPlaying,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.neo.onSurfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Title and artist, under the artwork (scrolls when too long).
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.metadata});
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final artist = metadata.artist;
    // Full width, so it lines up with the slider under it.
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MarqueeTextWidget(
            text: metadata.title,
            fontColor: context.neo.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          if (artist != null && artist.isNotEmpty) ...[
            const SizedBox(height: 4),
            MarqueeTextWidget(
              text: artist,
              fontColor: context.neo.onSurfaceMuted,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ],
        ],
      ),
    );
  }
}

class _PipVideoOnlySurface extends StatelessWidget {
  const _PipVideoOnlySurface({
    required this.controller,
    required this.metadata,
  });

  final VideoController controller;
  final MediaItem metadata;

  @override
  Widget build(BuildContext context) {
    final isVideo = metadata.extras?['isVideo'] == true;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: isVideo
            ? Video(
                controller: controller,
                controls: NoVideoControls,
                pauseUponEnteringBackgroundMode: false,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.lyricsController,
  });
  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: NowPlayingArtwork(
                      size: size,
                      metadata: metadata,
                      lyricsController: lyricsController,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _TitleBlock(metadata: metadata),
                ),
                if (!(metadata.extras?['isLive'] ?? false))
                  Expanded(
                    flex: 4,
                    child: NowPlayingControls(
                      size: size,
                      audioId: metadata.extras?['ytid'],
                      adjustedIconSize: adjustedIconSize,
                      adjustedMiniIconSize: adjustedMiniIconSize,
                      metadata: metadata,
                    ),
                  ),
                BottomActionsRow(
                  audioId: metadata.extras?['ytid'],
                  metadata: metadata,
                  iconSize: adjustedMiniIconSize,
                  isLargeScreen: true,
                  lyricsController: lyricsController,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        const Expanded(child: QueueWidget()),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.isLargeScreen,
    required this.lyricsController,
  });
  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final bool isLargeScreen;
  final FlipCardController lyricsController;

  @override
  Widget build(BuildContext context) {
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      return _buildLandscapeLayout(context);
    }
    return _buildPortraitLayout(context);
  }

  Widget _buildPortraitLayout(BuildContext context) {
    final isLive = metadata.extras?['isLive'] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: NowPlayingArtwork(
                  size: size,
                  metadata: metadata,
                  lyricsController: lyricsController,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: _TitleBlock(metadata: metadata),
          ),
          if (!isLive) ...[
            const PositionSlider(),
            const SizedBox(height: 4),
            PlayerControlButtons(
              metadata: metadata,
              iconSize: adjustedIconSize,
              miniIconSize: adjustedMiniIconSize,
            ),
          ],
          const SizedBox(height: 16),
          BottomActionsRow(
            audioId: metadata.extras?['ytid'],
            metadata: metadata,
            iconSize: adjustedMiniIconSize,
            isLargeScreen: isLargeScreen,
            lyricsController: lyricsController,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: NowPlayingArtwork(
                size: size,
                metadata: metadata,
                lyricsController: lyricsController,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _TitleBlock(metadata: metadata),
                ),
                if (!(metadata.extras?['isLive'] ?? false))
                  Expanded(
                    child: NowPlayingControls(
                      size: size,
                      audioId: metadata.extras?['ytid'],
                      adjustedIconSize: adjustedIconSize,
                      adjustedMiniIconSize: adjustedMiniIconSize,
                      metadata: metadata,
                    ),
                  ),
                BottomActionsRow(
                  audioId: metadata.extras?['ytid'],
                  metadata: metadata,
                  iconSize: adjustedMiniIconSize,
                  isLargeScreen: isLargeScreen,
                  lyricsController: lyricsController,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
