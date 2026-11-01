import 'package:flutter/material.dart';
import 'package:muzee/extensions/l10n.dart';
import 'package:muzee/services/monetization/ad_placement_gate.dart';
import 'package:muzee/services/playlists_manager.dart';
import 'package:muzee/widgets/monetization/native_ad_tile.dart';
import 'package:muzee/widgets/muzee_artwork.dart';

/// Every playlist Muzee suggests on Home ("For you" → View all), with one
/// native ad after the first rows.
class AllPlaylistsPage extends StatelessWidget {
  const AllPlaylistsPage({super.key, required this.onPlaylistSelected});

  final void Function(String ytid) onPlaylistSelected;

  /// Playlists before the ad: two rows of three on a phone.
  static const _beforeAd = 6;

  static const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    mainAxisSpacing: 16,
    crossAxisSpacing: 12,
    childAspectRatio: 0.74,
  );

  @override
  Widget build(BuildContext context) {
    final items = playlists.where((p) => p['isAlbum'] != true).toList();
    final head = items.take(_beforeAd).toList();
    final rest = items.skip(_beforeAd).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.forYou)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: _gridOf(head),
          ),
          if (rest.isNotEmpty) ...[
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: NativeAdTile(placement: AdNativePlacement.allPlaylists),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: _gridOf(rest),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _gridOf(List<Map> playlists) => SliverGrid.builder(
    gridDelegate: _grid,
    itemCount: playlists.length,
    itemBuilder: (context, index) {
      final playlist = playlists[index];
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
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      );
    },
  );
}
