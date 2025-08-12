import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/views/playlist/detail_playlist_view.dart';

class CellPlaylistArtist extends StatelessWidget {
  final PlaylistModel playlist;
  const CellPlaylistArtist({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushScreenWithNavBar(
        context,
        DetailPlaylistView(
          playlist: playlist,
        ),
      ),
      child: SizedBox(
        width: 148.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.w),
              child: SizedBox(
                height: 148.w,
                width: 148.w,
                child: CachedNetworkImage(
                  imageUrl: playlist.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(FlutterRemix.music_line),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                playlist.title ?? '',
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              playlist.playlistId != null ? locale.album : locale.playlist,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
