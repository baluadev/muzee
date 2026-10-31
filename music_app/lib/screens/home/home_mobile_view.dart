import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/home/all_playlists_page.dart';
import 'package:muzee/screens/home/home_controller.dart';
import 'package:muzee/services/google_account_service.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/router_service.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/app_utils.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/utilities/formatter.dart';
import 'package:muzee/widgets/announcement_box.dart';
import 'package:muzee/widgets/monetization/banner_ad_widget.dart';
import 'package:muzee/widgets/moods.dart';
import 'package:muzee/widgets/muzee_artwork.dart';
import 'package:muzee/widgets/muzee_brand.dart';
import 'package:muzee/widgets/shimmer_skeletons.dart';
import 'package:muzee/widgets/song_bar.dart';
import 'package:youtube_charts/youtube_charts.dart';

typedef PlaylistSelectedCallback = void Function(String ytid);

/// Home: greeting, moods, what you played lately, then trending and
/// suggestions.
class HomeMobileView extends StatelessWidget {
  const HomeMobileView({
    super.key,
    required this.controller,
    required this.onPlaylistSelected,
  });
  final HomeController controller;
  final PlaylistSelectedCallback onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(child: _HomeHeader(controller)),
        ),
        SliverToBoxAdapter(child: _buildAnnouncement(context)),
        const SliverToBoxAdapter(child: _MoodChips()),
        SliverToBoxAdapter(child: _buildListenAgain(context)),
        SliverToBoxAdapter(child: _buildTrending(context)),
        const SliverToBoxAdapter(
          child: BannerAdWidget(placement: AdBannerPlacement.home),
        ),
        SliverToBoxAdapter(child: _buildSuggestedPlaylists(context)),
        SliverToBoxAdapter(child: _buildMostPlayedSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

  Widget _buildListenAgain(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.recentlyPlayedLengthNotifier,
        controller.recentlyPlayedVersionNotifier,
      ]),
      builder: (context, _) {
        final songs = controller.getRecentlyPlayed();
        if (songs.isEmpty) return const SizedBox.shrink();
        final l10n = context.l10n!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.listenAgain),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < songs.length; i++)
                        SizedBox(
                          width: width,
                          child: _ListenAgainTile(
                            song: songs[i],
                            onTap: () => controller.playSongList(
                              title: l10n.recentlyPlayed,
                              list: songs,
                              index: i,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrending(BuildContext context) {
    return ValueListenableBuilder<YouTubeChartsCountry>(
      valueListenable: controller.currentCountryNotifier,
      builder: (context, country, _) {
        final l10n = context.l10n!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(l10n.trending),
            AsyncLoader<List<dynamic>>(
              future: controller.getTrendingVideos(country),
              onRetry: () => controller.retryTrendingVideos(country),
              loadingWidget: SizedBox(
                height: _TrendingCard.height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) =>
                      const ShimmerSuggestedCard(width: _TrendingCard.width),
                ),
              ),
              builder: (context, videos) {
                final songs = [
                  for (var i = 0; i < videos.length; i++)
                    _trendingSong(context, videos[i] as Map, i),
                ];
                if (songs.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: _TrendingCard.height,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _TrendingCard(
                      song: songs[index],
                      rank: index + 1,
                      onTap: () => controller.playTrendingSong(songs[index]),
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

  Map<String, dynamic> _trendingSong(BuildContext context, Map video, int i) {
    final l10n = context.l10n!;
    final artists = video['artists'] as List?;
    String? imageUrl;
    final thumbnails = video['thumbnail']?['thumbnails'] as List?;
    if (thumbnails != null && thumbnails.isNotEmpty) {
      imageUrl = thumbnails.last['url']?.toString();
    }
    final artist = (artists != null && artists.isNotEmpty)
        ? artists[0]['name']?.toString() ?? l10n.unknownArtist
        : l10n.unknownArtist;
    final title = video['title']?.toString();
    return {
      'id': i,
      'ytid': video['id']?.toString(),
      'title': title == null
          ? l10n.unknownTitle
          : formatChartTitle(title, artist),
      'artist': artist,
      'image': imageUrl,
      'highResImage': imageUrl,
      'lowResImage': imageUrl,
    };
  }

  Widget _buildSuggestedPlaylists(BuildContext context) {
    final l10n = context.l10n!;
    return AsyncLoader<List<dynamic>>(
      future: controller.getSuggestedPlaylists(),
      onRetry: controller.retrySuggestedPlaylists,
      loadingWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(l10n.forYou),
          SizedBox(
            height: _PlaylistCard.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const ShimmerPlaylistCard(),
            ),
          ),
        ],
      ),
      builder: (context, playlists) {
        final visible = playlists.take(8).cast<Map>().toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              l10n.forYou,
              actionLabel: l10n.viewAll,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AllPlaylistsPage(onPlaylistSelected: onPlaylistSelected),
                ),
              ),
            ),
            SizedBox(
              height: _PlaylistCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _PlaylistCard(
                  playlist: visible[index],
                  onTap: () {
                    final ytid = visible[index]['ytid']?.toString();
                    if (ytid != null) onPlaylistSelected(ytid);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMostPlayedSection(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.recentlyPlayedLengthNotifier,
        controller.recentlyPlayedVersionNotifier,
      ]),
      builder: (context, _) {
        final mostPlayedSongs = controller.getMostPlayedSongs();
        if (mostPlayedSongs.isEmpty) return const SizedBox.shrink();
        final title = context.l10n!.mostPlayed;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title),
            for (var index = 0; index < mostPlayedSongs.length; index++)
              SongBar(
                mostPlayedSongs[index],
                false,
                key: ValueKey(mostPlayedSongs[index]['ytid'] ?? index),
                onPlay: () => controller.playMostPlayedPlaylist(
                  title: title,
                  list: mostPlayedSongs,
                  index: index,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Logo, a greeting for the time of day, and the account / Settings button.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader(this.controller);
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n!;
    final greeting = switch (HomeController.greetingFor(DateTime.now())) {
      GreetingPart.morning => l10n.goodMorning,
      GreetingPart.afternoon => l10n.goodAfternoon,
      GreetingPart.evening => l10n.goodEvening,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          const MuzeeIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              greeting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ValueListenableBuilder<GoogleAccount?>(
            valueListenable: GoogleAccountService.instance.account,
            builder: (context, account, _) {
              final picture = account?.pictureUrl;
              return IconButton(
                tooltip: l10n.settings,
                onPressed: () => context.push(NavigationManager.settingsPath),
                icon: picture == null || picture.isEmpty
                    ? const Icon(FluentIcons.settings_24_regular)
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: context.neo.surfaceRaised,
                        backgroundImage: CachedNetworkImageProvider(picture),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The first moods ("Chill", "Workout"…) as chips; the full list is under
/// Search.
class _MoodChips extends StatelessWidget {
  const _MoodChips();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MoodSection>>(
      future: Moods.load(),
      builder: (context, snapshot) {
        final moods = snapshot.data?.firstOrNull?.moods ?? const [];
        if (moods.isEmpty) return const SizedBox(height: 8);
        return SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: moods.length.clamp(0, 12),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => MoodChip(moods[i]),
          ),
        );
      },
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

class _ListenAgainTile extends StatelessWidget {
  const _ListenAgainTile({required this.song, required this.onTap});

  final Map song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = formatSongTitle(song['title']?.toString() ?? '');
    return Material(
      color: context.neo.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            MuzeeArtwork(
              url: (song['lowResImage'] ?? song['image'])?.toString(),
              width: 56,
              height: 56,
              borderRadius: 0,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.song,
    required this.rank,
    required this.onTap,
  });

  static const double width = 260;
  static const double height = width * 9 / 16 + 56;

  final Map song;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final neo = context.neo;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                MuzeeArtwork(
                  url: song['image']?.toString(),
                  width: width,
                  height: width * 9 / 16,
                  iconSize: 32,
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: neo.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$rank',
                      style: text.labelLarge?.copyWith(color: neo.onAccent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatSongTitle(song['title']?.toString() ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall,
            ),
            Text(
              song['artist']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: neo.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});

  static const double size = 144;
  static const double height = size + 48;

  final Map playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MuzeeArtwork(
              url: playlist['image']?.toString(),
              width: size,
              height: size,
              iconSize: 32,
            ),
            const SizedBox(height: 8),
            Text(
              playlist['title']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
