import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/screens/playlist_page.dart';
import 'package:muzee/theme/neo/neo_colors.dart';
import 'package:muzee/widgets/load_error_view.dart';
import 'package:youtube_charts/youtube_charts.dart';

class CategoryPlaylistsPage extends StatefulWidget {
  const CategoryPlaylistsPage({
    super.key,
    required this.title,
    required this.params,
  });
  final String title;
  final String params;

  @override
  State<CategoryPlaylistsPage> createState() => _CategoryPlaylistsPageState();
}

class _CategoryPlaylistsPageState extends State<CategoryPlaylistsPage> {
  late Future<List<Map<String, dynamic>>> _categoryPlaylistsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _categoryPlaylistsFuture = YouTubeChartsClient().getPlaylistsForCategory(
      widget.params,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.neo.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoryPlaylistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.neo.accent),
            );
          }
          if (snapshot.hasError) {
            return LoadErrorView(onRetry: () => setState(_load));
          }
          final sections = snapshot.data ?? [];
          if (sections.isEmpty) {
            return Center(
              child: Text(
                context.l10n!.noPlaylistsFound,
                style: TextStyle(color: context.neo.onSurfaceMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              final title = section['title'] ?? 'Section';
              final items = section['items'] as List<dynamic>? ?? [];

              if (items.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.neo.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 16),
                      itemBuilder: (context, itemIndex) {
                        final item = items[itemIndex];
                        return _buildPlaylistCard(context, item);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, dynamic item) {
    String? title;
    String? subtitle;
    String? imageUrl;
    String? playlistId;

    if (item is Map) {
      if (item.containsKey('musicTwoRowItemRenderer')) {
        final renderer = item['musicTwoRowItemRenderer'];

        title = renderer['title']?['runs']?[0]?['text'];

        final subtitleRuns = renderer['subtitle']?['runs'] as List?;
        if (subtitleRuns != null && subtitleRuns.isNotEmpty) {
          subtitle = subtitleRuns.map((r) => r['text']).join();
        }

        final thumbnails =
            renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                as List?;
        if (thumbnails != null && thumbnails.isNotEmpty) {
          imageUrl = thumbnails.last['url'];
        }

        playlistId =
            renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
        if (playlistId != null && playlistId.startsWith('VL')) {
          playlistId = playlistId.substring(2); // Remove VL prefix if present
        }
      }
    }

    if (title == null || playlistId == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistPage(
              playlistId: playlistId,
              playlistData: {
                'ytid': playlistId,
                'title': title,
                'image': imageUrl,
                'source': 'youtube',
                'list': [], // PlaylistPage will fetch the rest
              },
            ),
          ),
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: context.neo.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.neo.hairline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: context.neo.accent,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.music_note,
                          color: Colors.grey,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: Colors.grey,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.neo.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.neo.onSurfaceMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
