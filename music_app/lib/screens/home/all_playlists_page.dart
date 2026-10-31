import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/widgets/muzee_artwork.dart';

/// Every playlist Muzee suggests on Home ("For you" → View all).
class AllPlaylistsPage extends StatelessWidget {
  const AllPlaylistsPage({super.key, required this.onPlaylistSelected});

  final void Function(String ytid) onPlaylistSelected;

  @override
  Widget build(BuildContext context) {
    final items = playlists.where((p) => p['isAlbum'] != true).toList();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.forYou)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.74,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final playlist = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final ytid = playlist['ytid']?.toString();
              if (ytid != null) onPlaylistSelected(ytid);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: MuzeeArtwork(
                    url: playlist['image']?.toString(),
                    iconSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  playlist['title']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
