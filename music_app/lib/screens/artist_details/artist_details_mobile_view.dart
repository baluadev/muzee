import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/artist_details/artist_details_controller.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:muzee/widgets/song_bar.dart';
import 'package:youtube_charts/youtube_charts.dart';

class ArtistDetailsMobileView extends StatelessWidget {
  const ArtistDetailsMobileView({super.key, required this.controller});
  final ArtistDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<YouTubeChartsCountry>(
        valueListenable: controller.countryNotifier,
        builder: (context, country, _) {
          return AsyncLoader<Map<String, dynamic>>(
            future: controller.fetchArtistDetails(country),
            onRetry: () => controller.fetchArtistDetails(country),
            builder: (context, data) {
              if (data.isEmpty) {
                return Center(child: Text(context.l10n!.noDetailsFound));
              }

              final metadata = data['metadata'] ?? {};
              final name = metadata['name'] ?? context.l10n!.unknownArtist;
              final heroMetadata = metadata['heroMetadata'] ?? {};
              final bannerUrl = heroMetadata['heroBannerImageUrl'] as String?;
              final totalViews = data['totalViews'] as int? ?? 0;
              final topSongs = data['topSongs'] as List<dynamic>? ?? [];

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        name,
                        style: const TextStyle(
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                      background: bannerUrl != null
                          ? CachedNetworkImage(
                              imageUrl: bannerUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, size: 64),
                            )
                          : const Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (totalViews > 0)
                            Text(
                              '${context.l10n!.totalViews}: ${NumberFormat.compact().format(totalViews)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey[400]),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n!.topSongs,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (topSongs.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.play_circle_fill,
                                    color: context.neo.accent,
                                    size: 36,
                                  ),
                                  onPressed: () =>
                                      controller.playTopSongs(topSongs, name),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = topSongs[index];
                      final songMap = controller.mapSong(song, name);
                      return SongBar(songMap, false);
                    }, childCount: topSongs.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
