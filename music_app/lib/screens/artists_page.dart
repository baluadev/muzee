import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/artist_details_page.dart';
import 'package:muzee/services/settings_manager.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/utilities/async_loader.dart';
import 'package:youtube_charts/youtube_charts.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.topArtists)),
      body: ValueListenableBuilder<YouTubeChartsCountry>(
        valueListenable: youtubeChartsCountryNotifier,
        builder: (context, country, _) {
          return AsyncLoader<List<dynamic>>(
            future: YouTubeChartsClient().getTopArtists(country: country),
            onRetry: () =>
                YouTubeChartsClient().getTopArtists(country: country),
            builder: (context, artists) {
              if (artists.isEmpty) {
                return Center(child: Text(context.l10n!.noArtistsFound));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  final name =
                      artist['name'] as String? ?? context.l10n!.unknownArtist;
                  final thumbnailObj = artist['thumbnail'];
                  String? imageUrl;
                  if (thumbnailObj != null &&
                      thumbnailObj['thumbnails'] != null) {
                    final thumbnails = thumbnailObj['thumbnails'] as List;
                    if (thumbnails.isNotEmpty) {
                      imageUrl = thumbnails.last['url'] as String?;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      if (artist['id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArtistDetailsPage(artistId: artist['id']),
                          ),
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.neo.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.neo.hairline),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: context.neo.onSurface),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
