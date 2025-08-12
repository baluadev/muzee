import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';

import 'detail_playlist_view.dart';

class Cell extends StatelessWidget {
  final PlaylistModel playlist;
  const Cell({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushScreenWithNavBar(
          context,
          DetailPlaylistView(
            playlist: playlist,
            isLocal: true,
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageSongWidget(
            id: playlist.songs.isNotEmpty ? playlist.songs.first.songId : '',
            url: playlist.thumbnailUrl,
            width: 148.w,
            height: 148.w,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              playlist.title ?? '',
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 2,
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
    );
  }
}
