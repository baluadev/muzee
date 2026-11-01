import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/explore/explore_controller.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/widgets/monetization/banner_ad_widget.dart';
import 'package:muzee/widgets/moods.dart';
import 'package:muzee/widgets/muzee_artwork.dart';
import 'package:muzee/widgets/page_title.dart';
import 'package:muzee/widgets/shimmer_skeletons.dart';
import 'package:muzee/widgets/song_bar.dart';
import 'package:youtube_charts/youtube_charts.dart';

typedef ActionCallback = void Function();
typedef ArtistSelectedCallback = void Function(String artistId);

/// The Search tab before typing: the search field on top, then trending
/// artists, top songs and every mood & genre. One layout for every width.
class ExploreMobileView extends StatelessWidget {
  const ExploreMobileView({
    super.key,
    required this.controller,
    required this.onSearchTap,
    required this.onArtistsViewAll,
    required this.onArtistSelected,
  });
  final ExploreController controller;
  final ActionCallback onSearchTap;
  final ActionCallback onArtistsViewAll;
  final ArtistSelectedCallback onArtistSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(child: PageTitle(l10n.search)),
        ),
        SliverToBoxAdapter(child: _SearchField(onTap: onSearchTap)),
        SliverToBoxAdapter(child: _buildTrendingArtists(context)),
        // Below the first section, clear of the search field.
        const SliverToBoxAdapter(
          child: BannerAdWidget(placement: AdBannerPlacement.search),
        ),
        SliverToBoxAdapter(child: _buildTopSongs(context)),
        const BrowseAllMoods(),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildTrendingArtists(BuildContext context) {
    return ValueListenableBuilder<YouTubeChartsCountry>(
      valueListenable: controller.currentCountryNotifier,
      builder: (context, country, _) {
        final l10n = context.l10n!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              l10n.trendingArtists,
              actionLabel: l10n.viewAll,
              onAction: onArtistsViewAll,
            ),
            AsyncLoader<List<dynamic>>(
              future: controller.getTopArtists(country),
              onRetry: () => controller.retryTopArtists(country),
              loadingWidget: SizedBox(
                height: _ArtistAvatar.height,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, __) =>
                      const ShimmerArtistCard(size: _ArtistAvatar.size),
                ),
              ),
              builder: (context, artists) {
                if (artists.isEmpty) return const SizedBox.shrink();
                final top = artists.take(10).toList();
                return SizedBox(
                  height: _ArtistAvatar.height,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: top.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) => _ArtistAvatar(
                      artist: top[index] as Map,
                      onTap: onArtistSelected,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopSongs(BuildContext context) {
    return ValueListenableBuilder<YouTubeChartsCountry>(
      valueListenable: controller.currentCountryNotifier,
      builder: (context, country, _) {
        final l10n = context.l10n!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.topVideos),
            AsyncLoader<List<dynamic>>(
              future: controller.getTopVideos(country),
              onRetry: () => controller.retryTopVideos(country),
              loadingWidget: const Column(
                children: [
                  ShimmerSongBar(),
                  ShimmerSongBar(),
                  ShimmerSongBar(),
                ],
              ),
              builder: (context, videos) {
                final songs = videos
                    .take(10)
                    .map((v) => controller.mapVideo(l10n.unknownArtist, v))
                    .toList();
                return Column(
                  children: [
                    for (var i = 0; i < songs.length; i++)
                      SongBar(
                        songs[i],
                        true,
                        key: ValueKey('top_song_${songs[i]['ytid']}'),
                        onPlay: () => controller.playSongs(songs, i),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Looks like a search field; opens the search page.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        button: true,
        label: context.l10n!.searchHint,
        excludeSemantics: true,
        child: Material(
          color: neo.surfaceRaised,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(FluentIcons.search_24_regular, color: neo.onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n!.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: neo.onSurfaceMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  const _ArtistAvatar({required this.artist, required this.onTap});

  static const double size = 96;
  static const double height = size + 32;

  final Map artist;
  final ArtistSelectedCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = artist['name']?.toString() ?? context.l10n!.unknownArtist;
    final thumbnails = artist['thumbnail']?['thumbnails'] as List?;
    final imageUrl = (thumbnails != null && thumbnails.isNotEmpty)
        ? thumbnails.last['url']?.toString()
        : null;
    final id = artist['id']?.toString();

    return SizedBox(
      width: size,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: id == null ? null : () => onTap(id),
        child: Column(
          children: [
            MuzeeArtwork(
              url: imageUrl,
              width: size,
              height: size,
              borderRadius: size / 2,
              iconSize: 32,
              fallbackIcon: FluentIcons.person_24_regular,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
