import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/home/home_controller.dart';
import 'package:muzee/screens/home/home_mobile_view.dart'
    show PlaylistSelectedCallback;
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/app_utils.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/widgets/announcement_box.dart';
import 'package:muzee/widgets/monetization/banner_ad_widget.dart';
import 'package:muzee/widgets/no_artwork_cube.dart';
import 'package:muzee/widgets/shimmer_skeletons.dart';
import 'package:muzee/widgets/song_bar.dart';
import 'package:muzee/widgets/spinner.dart';
import 'package:youtube_charts/youtube_charts.dart';

class HomeTabletView extends StatelessWidget {
  const HomeTabletView({
    super.key,
    required this.controller,
    required this.onPlaylistSelected,
  });

  final HomeController controller;
  final PlaylistSelectedCallback onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topInset),
              _buildAnnouncement(context),
              _buildHeroBanner(context),
              const BannerAdWidget(placement: AdBannerPlacement.home),
              const SizedBox(height: 16),
              _buildSuggestedPlaylists(context),
              const SizedBox(height: 16),
              _buildRecentlyPlayedSection(context),
              const SizedBox(height: 120), // Bottom padding for mini player
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncement(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.announcementUrlNotifier,
      builder: (_, url, __) {
        if (url == null) return const SizedBox.shrink();
        final isSponsor = isSponsorshipAnnouncementUrl(url);
        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
          child: AnnouncementBox(
            message: isSponsor
                ? context.l10n!.sponsorProject
                : context.l10n!.newAnnouncement,
            url: url,
            icon: isSponsor
                ? FluentIcons.heart_24_filled
                : FluentIcons.megaphone_24_filled,
            onDismiss: controller.dismissAnnouncement,
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return ValueListenableBuilder<YouTubeChartsCountry>(
      valueListenable: controller.currentCountryNotifier,
      builder: (context, country, _) {
        return AsyncLoader<List<dynamic>>(
          future: controller.getTrendingVideos(country),
          onRetry: () => controller.getTrendingVideos(country),
          loadingWidget: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(child: ShimmerHeroBanner()),
                SizedBox(width: 24),
                Expanded(child: ShimmerHeroBanner()),
              ],
            ),
          ),
          builder: (context, trendingVideos) {
            if (trendingVideos.isEmpty) return const SizedBox.shrink();

            final items = trendingVideos.take(2).toList();
            if (items.length < 2) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHeroItem(
                        context,
                        items[0] as Map,
                        0,
                        context.l10n!.trending,
                        context.neo.accent,
                        context.neo.onAccent,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildHeroItem(
                        context,
                        items[1] as Map,
                        1,
                        'NEW RELEASE', // Or context.l10n if available, hardcoded based on design request
                        context.neo.surfaceRaised,
                        context.neo.accent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroItem(
    BuildContext context,
    Map video,
    int index,
    String tagText,
    Color tagColor,
    Color tagTextColor,
  ) {
    final title = video['title']?.toString() ?? context.l10n!.unknownTitle;

    var artistName = context.l10n!.unknownArtist;
    if (video['artists'] != null && (video['artists'] as List).isNotEmpty) {
      artistName =
          video['artists'][0]['name']?.toString() ??
          context.l10n!.unknownArtist;
    }

    final subtitle = artistName;

    String? imageUrl;
    if (video['thumbnail'] != null &&
        video['thumbnail']['thumbnails'] != null) {
      final thumbnails = video['thumbnail']['thumbnails'] as List;
      if (thumbnails.isNotEmpty) {
        imageUrl = thumbnails.last['url']?.toString();
      }
    }

    return GestureDetector(
      onTap: () {
        final videoId = video['id']?.toString();
        if (videoId != null) {
          final song = {
            'id': index,
            'ytid': videoId,
            'title': title,
            'artist': artistName,
            'image': imageUrl,
            'highResImage': imageUrl,
            'lowResImage': imageUrl,
          };
          controller.playTrendingSong(song);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _NetworkArtwork(
              imageUrl: imageUrl,
              borderRadius: BorderRadius.zero,
              fallbackIcon: FluentIcons.music_note_2_24_regular,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.neo.background.withAlpha(0),
                    context.neo.background.withAlpha(0),
                    context.neo.background,
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      tagText,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: tagTextColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: context.neo.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.neo.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(BuildContext context) {
    return AsyncLoader<List<dynamic>>(
      future: controller.getSuggestedPlaylists(),
      onRetry: controller.getSuggestedPlaylists,
      loadingWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n!.forYou,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.neo.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: null,
                  child: Text(
                    context.l10n!.viewAll,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.neo.accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 256,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 24),
              itemBuilder: (_, __) => const ShimmerPlaylistCard(),
            ),
          ),
        ],
      ),
      builder: (context, playlists) {
        final visible = playlists.take(12).cast<Map>().toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n!.forYou,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.neo.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n!.viewAll,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.neo.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 256,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: 24),
                itemBuilder: (context, index) {
                  return _PlaylistCard(
                    playlist: visible[index],
                    onTap: () {
                      final ytid = visible[index]['ytid']?.toString();
                      if (ytid != null) {
                        onPlaylistSelected(ytid);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentlyPlayedSection(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: controller.recentlyPlayedLengthNotifier,
      builder: (_, __, ___) {
        return ValueListenableBuilder<int>(
          valueListenable: controller.recentlyPlayedVersionNotifier,
          builder: (_, __, ___) {
            final mostPlayedSongs = controller.getMostPlayedSongs();
            if (mostPlayedSongs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Recently Played', // Based on Figma design, explicitly named Recently Played instead of Most Played
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.neo.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: List.generate(mostPlayedSongs.length, (index) {
                      final song = mostPlayedSongs[index];
                      return SongBar(
                        song,
                        false,
                        key: ValueKey(song['ytid'] ?? index),
                        onPlay: () async {
                          await controller.playMostPlayedPlaylist(
                            title: context.l10n!.recentlyPlayed,
                            list: mostPlayedSongs,
                            index: index,
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});

  final Map playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: context.neo.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.neo.hairline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _NetworkArtwork(
                  imageUrl: playlist['image']?.toString(),
                  borderRadius: BorderRadius.circular(12),
                  fallbackIcon: FluentIcons.music_note_2_24_regular,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              playlist['title']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.neo.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              playlist['artist']?.toString() ?? context.l10n!.playlist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.neo.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkArtwork extends StatelessWidget {
  const _NetworkArtwork({
    required this.imageUrl,
    required this.borderRadius,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: context.neo.surface,
          alignment: Alignment.center,
          child: NullArtworkWidget(icon: fallbackIcon),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: trimmedUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => ColoredBox(
          color: context.neo.surface,
          child: const Center(
            child: SizedBox(width: 20, height: 20, child: Spinner()),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: context.neo.surface,
          alignment: Alignment.center,
          child: NullArtworkWidget(icon: fallbackIcon),
        ),
      ),
    );
  }
}
